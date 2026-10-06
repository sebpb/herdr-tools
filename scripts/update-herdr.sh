#!/bin/sh
# Actualiza herdr a la ultima version estable sin perder los cambios propios (chats agrupados):
# aplica la rama sobre la nueva version, compila, prueba, instala y pasa el servidor en vivo.
# Uso: update-herdr.sh [--force]   (--force recompila aunque ya este al dia)
set -eu

repo=${HERDR_FORK_DIR:-$HOME/Proyectos/herdr}
branch=${HERDR_FORK_BRANCH:-group-agents-by-space}
remote=${HERDR_FORK_REMOTE:-fork}
zig=${ZIG:-$(ls -d "$HOME"/.local/opt/zig-*-0.16.*/zig 2>/dev/null | tail -n1)}
force=
[ "${1:-}" = "--force" ] && force=1

die() {
  printf 'update-herdr: %s\n' "$*" >&2
  exit 1
}

bin=$(command -v herdr) || die "no encuentro herdr en el PATH"
[ -n "$zig" ] && [ -x "$zig" ] || die "no encuentro Zig 0.16; defini ZIG=/ruta/a/zig"
cd "$repo" || die "no existe $repo; defini HERDR_FORK_DIR"
[ -z "$(git status --porcelain)" ] || die "$repo tiene cambios sin commitear"
git switch -q "$branch"

git fetch -q --tags origin
latest=$(git tag --list 'v*' --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n1)
base=$(git describe --tags --abbrev=0 --match 'v[0-9]*' HEAD)
previous=$(git rev-parse HEAD)

# Vuelve la rama a como estaba si algo falla despues del rebase.
rollback() {
  git reset -q --hard "$previous"
  die "$1; la rama quedo como estaba y no se instalo nada"
}

if [ "$base" = "$latest" ] && [ -z "$force" ]; then
  echo "herdr ya esta en $latest con tus cambios (usa --force para recompilar)."
  exit 0
fi
if [ "$base" != "$latest" ]; then
  echo "Aplicando $branch sobre $latest (antes $base)..."
  if ! git rebase -q --onto "$latest" "$base" "$branch"; then
    git rebase --abort
    die "los cambios no aplican limpio sobre $latest; hay que adaptarlos a mano en $repo"
  fi
fi

echo "Compilando..."
ZIG=$zig cargo build --release --locked || rollback "fallo la compilacion"
echo "Probando el panel de chats..."
ZIG=$zig cargo test --release --locked --bin herdr -- grouped_agent agent_sidebar api_pane_move_to_new_tab \
  >/dev/null 2>&1 || rollback "fallan los tests del panel"

cp "${CARGO_TARGET_DIR:-target}/release/herdr" "$bin.new" || rollback "no encuentro el binario compilado"
cp -p "$bin" "$bin.prev"
mv "$bin.new" "$bin"
version=$("$bin" --version | awk '{print $2}')
echo "Instalado herdr $version en $bin (el anterior quedo en $bin.prev)."
if [ "$base" != "$latest" ]; then
  git push -q --force-with-lease "$remote" "$branch" && echo "Rama $branch actualizada en $remote."
fi

socket=$("$bin" status server 2>/dev/null | sed -n 's/^socket: //p')
if [ -n "$socket" ]; then
  printf 'Pasar el servidor al binario nuevo sin cortar los chats? [S/n] '
  read -r answer || answer=
  case $answer in
  [nN]*) echo "El servidor nuevo arranca la proxima vez que se reinicie." ;;
  *)
    python3 -I - "$socket" "$bin" "$version" <<'EOF'
import json, os, socket, struct, sys, time

path, exe, version = sys.argv[1:]
request = {
    "id": "update-herdr:live-handoff",
    "method": "server.live_handoff",
    "params": {"import_exe": exe, "expected_version": version},
}
with socket.socket(socket.AF_UNIX) as conn:
    conn.settimeout(30)
    conn.connect(path)
    # PID del servidor viejo, para esperar a que termine de pasar los panes (solo Linux).
    old_pid = None
    if hasattr(socket, "SO_PEERCRED"):
        creds = conn.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, struct.calcsize("3i"))
        old_pid = struct.unpack("3i", creds)[0]
    conn.sendall(json.dumps(request).encode() + b"\n")
    response = json.loads(conn.makefile().readline())
if "error" in response:
    sys.exit(f"update-herdr: fallo el handoff: {response['error']['message']}")
deadline = time.monotonic() + 30
while old_pid and time.monotonic() < deadline:
    try:
        os.kill(old_pid, 0)
    except ProcessLookupError:
        break
    time.sleep(0.2)
else:
    time.sleep(3)
EOF
    tries=0
    until "$bin" status server 2>/dev/null | grep -q '^status: running'; do
      tries=$((tries + 1))
      [ "$tries" -lt 30 ] || die "el servidor nuevo no respondio; revisa herdr status"
      sleep 1
    done
    echo "Servidor pasado al binario nuevo; los chats siguen corriendo."
    ;;
  esac
fi
echo "Para ver la interfaz nueva: prefix+q y volve a abrir herdr."

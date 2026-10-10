# Proyectos = sesiones de Herdr. Comparte el estado con el lanzador herdr-proyectos.
projects_state=${XDG_STATE_HOME:-$HOME/.local/state}/herdr-tools/projects

# Nombre de la sesion a la que pertenece este servidor.
current_project() {
  "${HERDR_BIN_PATH:-herdr}" session list --json |
    jq -r --arg sock "$HERDR_SOCKET_PATH" '.sessions[] | select(.socket_path == $sock) | .name'
}

# Nombre para mostrar: el que se escribio al crearlo, o el de la sesion.
project_label() {
  cat "$projects_state/labels/$1" 2>/dev/null || printf '%s\n' "$1"
}

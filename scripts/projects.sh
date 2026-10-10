#!/bin/sh
# Lista los proyectos (sesiones de Herdr). Enter cambia al elegido y suspende el actual,
# un nombre que no existe crea un proyecto nuevo y ctrl-x borra el elegido. Esc cierra.
. "$HERDR_PLUGIN_ROOT/scripts/projects-lib.sh"
herdr=$HERDR_BIN_PATH
tab=$(printf '\t')
current=$(current_project)

# Una fila por proyecto, el actual primero: nombre, marca, nombre para mostrar y workspaces.
# Los que estan corriendo se consultan por su socket; los suspendidos, en su session.json.
rows() {
  "$herdr" session list --json |
    jq -r --arg cur "$current" '.sessions | sort_by(.name != $cur)[] | [.name, .running, .socket_path, .session_dir] | @tsv' |
    while IFS=$tab read -r name running sock dir; do
      if [ "$running" = true ]; then
        spaces=$(HERDR_SOCKET_PATH=$sock "$herdr" workspace list | jq -r '[.result.workspaces[].label] | join(", ")')
      else
        spaces=$(jq -r '[.workspaces[]? | .custom_name // (.identity_cwd // "" | split("/") | last)] | join(", ")' "$dir/session.json" 2>/dev/null)
      fi
      if [ "$name" = "$current" ]; then mark='●'; elif [ "$running" = true ]; then mark='○'; else mark=' '; fi
      printf '%s\t%s %s\t%s\n' "$name" "$mark" "$(project_label "$name")" "${spaces:-sin workspaces}"
    done
}

# Lo que se pierde al suspender: chats trabajando y procesos que no son un chat retomable.
busy_panes() {
  spaces=$("$herdr" workspace list | jq -c '[.result.workspaces[] | {key: .workspace_id, value: .label}] | from_entries')
  "$herdr" pane list |
    jq -r --argjson ws "$spaces" '.result.panes[] | [.pane_id, (.agent_session != null), .agent_status, $ws[.workspace_id], (.terminal_title_stripped // "")] | @tsv' |
    while IFS=$tab read -r pane resumable status space title; do
      if [ "$resumable" = true ]; then
        [ "$status" = working ] && printf '  • %s: chat trabajando (%s)\n' "$space" "$title"
      else
        "$herdr" pane process-info --pane "$pane" |
          jq -r --arg space "$space" '.result.process_info | select(.foreground_process_group_id != .shell_pid) | "  • \($space): \([.foreground_processes[].name] | unique | join(", "))"'
      fi
    done
}

confirm() {
  printf '%s [s/N] ' "$1"
  read -r answer
  case $answer in s | S | si | sí | y | Y) return 0 ;; esac
  return 1
}

pause() {
  printf '\n%s\nEnter para volver. ' "$1"
  read -r _
}

slug() {
  printf '%s' "$1" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null |
    tr 'A-Z ' 'a-z-' | tr -cd 'a-z0-9._-' | cut -c1-64
}

# Pide al lanzador abrir $1 (en la carpeta $2 si es nuevo) y para este servidor.
switch_to() {
  warnings=$(busy_panes)
  if [ -n "$warnings" ]; then
    printf 'Al suspender «%s» se corta:\n\n%s\n\n' "$(project_label "$current")" "$warnings"
    confirm '¿Cambiar igual?' || return 1
  fi
  if ! kill -0 "$(cat "$projects_state/launcher.pid" 2>/dev/null)" 2>/dev/null; then
    printf 'Herdr no se abrió con herdr-proyectos: se va a cerrar y vas a tener que abrir\n'
    printf '«%s» a mano con: herdr --session %s\n\n' "$(project_label "$1")" "$1"
    confirm '¿Suspender igual?' || return 1
  else
    printf '%s\t%s\n' "$1" "$2" >"$projects_state/next"
  fi
  printf 'Suspendiendo «%s»…\n' "$(project_label "$current")"
  # Fuera del grupo del popup: parar el servidor cierra este pane.
  if command -v setsid >/dev/null; then
    setsid -f "$herdr" server stop >/dev/null 2>&1 </dev/null
  else
    nohup "$herdr" server stop >/dev/null 2>&1 </dev/null &
  fi
  sleep 5
}

create() {
  name=$(slug "$1")
  if [ -z "$name" ]; then
    pause "«$1» no sirve como nombre: usá letras o números."
    return 1
  fi
  if "$herdr" session list --json | jq -e --arg n "$name" 'any(.sessions[]; .name == $n)' >/dev/null; then
    switch_to "$name" ""
    return
  fi
  printf 'Nuevo proyecto «%s».\nCarpeta inicial (Enter = ~): ' "$1"
  read -r dir
  case $dir in '' | '~') dir=$HOME ;; '~/'*) dir=$HOME/${dir#\~/} ;; esac
  if [ ! -d "$dir" ]; then
    pause "No existe la carpeta $dir."
    return 1
  fi
  mkdir -p "$projects_state/labels"
  printf '%s\n' "$1" >"$projects_state/labels/$name"
  switch_to "$name" "$dir"
}

delete() {
  if [ "$1" = "$current" ]; then
    pause 'No se puede borrar el proyecto actual.'
    return
  fi
  confirm "¿Borrar «$(project_label "$1")» con todos sus workspaces y chats guardados?" || return
  if out=$("$herdr" session delete "$1" 2>&1); then
    rm -f "$projects_state/labels/$1"
  else
    pause "No se pudo borrar: $out"
  fi
}

mkdir -p "$projects_state"
while :; do
  out=$(rows | fzf --delimiter="$tab" --with-nth=2.. --prompt='Proyecto > ' --no-sort --reverse \
    --print-query --expect=ctrl-n,ctrl-x \
    --header='Enter: cambiar · ctrl-n: crear con lo escrito · ctrl-x: borrar · ● actual  ○ abierto')
  [ $? -eq 130 ] && exit 0
  query=$(printf '%s\n' "$out" | sed -n 1p)
  key=$(printf '%s\n' "$out" | sed -n 2p)
  target=$(printf '%s\n' "$out" | sed -n 3p | cut -f1)
  clear
  if [ "$key" = ctrl-x ]; then
    [ -n "$target" ] && delete "$target"
  elif [ "$key" = ctrl-n ] || [ -z "$target" ]; then
    [ -n "$query" ] && create "$query"
  elif [ "$target" = "$current" ]; then
    exit 0
  else
    switch_to "$target" ""
  fi
done

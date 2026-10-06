#!/bin/sh
# Mueve el pane activo a una pestana nueva del workspace elegido, sin reiniciarlo.
. "$HERDR_PLUGIN_ROOT/scripts/context.sh"
herdr=$HERDR_BIN_PATH
ws=$("$herdr" workspace list |
  jq -r --arg ws "$(context workspace_id)" '.result.workspaces[] | select(.workspace_id != $ws) | [.workspace_id, "\(.number). \(.label)"] | @tsv' |
  fzf --delimiter='\t' --with-nth=2.. --prompt='Mover chat a > ' --no-sort --reverse | cut -f1)
[ -n "$ws" ] || exit 0
# Conserva el nombre de la pestana salvo que sea el numero por defecto.
label=$(context tab_label)
case "$label" in ''|*[!0-9]*) ;; *) label= ;; esac
"$herdr" pane move "$(context focused_pane_id)" --new-tab --workspace "$ws" ${label:+--label "$label"} --no-focus >/dev/null

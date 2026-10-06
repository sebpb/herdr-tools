#!/bin/sh
# Lista los chats del workspace activo; Enter enfoca el elegido, Esc cierra.
. "$HERDR_PLUGIN_ROOT/scripts/context.sh"
herdr=$HERDR_BIN_PATH
pane=$("$herdr" agent list |
  jq -r --arg ws "$(context workspace_id)" '.result.agents[] | select(.workspace_id == $ws) | [.pane_id, .agent_status, .agent, .terminal_title_stripped] | @tsv' |
  fzf --delimiter='\t' --with-nth=2.. --prompt='Chat > ' --no-sort --reverse | cut -f1)
[ -n "$pane" ] && "$herdr" agent focus "$pane" >/dev/null
exit 0

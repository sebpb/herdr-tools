# Lee el workspace, la pestana y el pane activos del contexto del plugin.
context() {
  printf '%s' "$HERDR_PLUGIN_CONTEXT_JSON" | jq -r --arg k "$1" '.[$k] // empty'
}

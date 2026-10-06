#!/bin/sh
# Muestra los atajos propios del config.toml activo, filtrables con fzf.
cfg=${HERDR_CONFIG_PATH:-$("$HERDR_BIN_PATH" --help | sed -n 's/^Config: //p')}
python3 -I "$HERDR_PLUGIN_ROOT/scripts/shortcuts.py" "$cfg" | fzf --no-sort --reverse --prompt='Atajos > ' --no-info
exit 0

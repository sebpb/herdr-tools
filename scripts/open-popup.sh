#!/bin/sh
# Abre el popup del plugin indicado (chats, move-chat o shortcuts).
exec "$HERDR_BIN_PATH" plugin pane open --plugin "$HERDR_PLUGIN_ID" --entrypoint "$1" >/dev/null

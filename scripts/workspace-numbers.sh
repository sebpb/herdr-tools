#!/bin/sh
# Publica "N. nombre" como token $numbered en cada workspace, segun su posicion actual.
herdr=${HERDR_BIN_PATH:-herdr}
"$herdr" workspace list | jq -r '.result.workspaces[] | [.workspace_id, "\(.number). \(.label)"] | @tsv' |
  while IFS="$(printf '\t')" read -r id numbered; do
    "$herdr" workspace report-metadata "$id" --source "plugin:${HERDR_PLUGIN_ID:-sebpb.herdr-tools}" --token "numbered=$numbered" >/dev/null
  done

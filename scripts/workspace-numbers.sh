#!/bin/sh
# Publica "N. nombre" como token $numbered en cada workspace, segun su posicion actual,
# y el nombre del proyecto (la sesion de Herdr) como token $project.
. "${HERDR_PLUGIN_ROOT:-$(dirname "$0")/..}/scripts/projects-lib.sh"
herdr=${HERDR_BIN_PATH:-herdr}
project=$(project_label "$(current_project)")
"$herdr" workspace list | jq -r '.result.workspaces[] | [.workspace_id, "\(.number). \(.label)"] | @tsv' |
  while IFS="$(printf '\t')" read -r id numbered; do
    "$herdr" workspace report-metadata "$id" --source "plugin:${HERDR_PLUGIN_ID:-sebpb.herdr-tools}" --token "numbered=$numbered" --token "project=$project" >/dev/null
  done

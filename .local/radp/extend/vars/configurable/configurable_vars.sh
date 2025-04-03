#!/usr/bin/env bash
# shellcheck source=../../../framework/includes/vars/global_vars.sh
set -e

function __extend_integration_settings() {
  :
}

function __extend_plugin_settings() {
  :
}

function __extend_others_settings() {
    declare -gr g_tarignore_file=${G_TARIGNORE_FILE:-"$g_user_config_path"/.tarignore}
}

function main() {
  __extend_integration_settings
  __extend_plugin_settings
  __extend_others_settings
}

main

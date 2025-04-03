#!/usr/bin/env bash


function main() {
  # enabled==true plugin
  declare -gxa g_enabled_plugins=()

  # plugin_name -> plugin_file mapper
  declare -gxA g_plugin_file_mapper
  declare -gxA g_enabled_plugin_file_mapper # enabled == true
}

main

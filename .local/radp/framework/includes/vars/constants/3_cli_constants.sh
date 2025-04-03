#!/usr/bin/env bash

function main() {
  declare -gr g_getopt_common_short_opts="hf:"
  declare -gr g_getopt_common_long_opts="help,function:"
  declare -grA g_getopt_common_desc=(
    ['help']='Display this help and exit'
    ['function']="Specify the function to execute"
  )
}

main

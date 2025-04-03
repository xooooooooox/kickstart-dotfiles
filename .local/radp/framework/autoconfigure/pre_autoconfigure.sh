#!/usr/bin/env bash
set -e

function main() {
  radp_source_local_scripts "$g_framework_root"/autoconfigure/hook/pre || return 1
}

main

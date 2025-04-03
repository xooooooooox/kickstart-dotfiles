#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_markdownlint_cli_install() {
  if command -v markdownlint >/dev/null 2>&1; then
    radp_log_info "fzf already installed"
    return 0
  fi
  case "$g_guest_distro_id" in
    osx)
      brew install markdownlint-cli || return 1
      ;;
    *)
      if ! command -v npm >/dev/null 2>&1;then
        radp_log_error "npm not installed"
        return 1
      fi
      npm install -g markdownlint-cli || return 1
      ;;
  esac
}

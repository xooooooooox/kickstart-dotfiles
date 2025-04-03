#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_zoxide_install() {
  if command -v zoxide >/dev/null 2>&1;then
    radp_log_info "zoxide already installed"
    return 0
  fi
  case "$g_guest_distro_id" in
    osx)
      radp_alias_brew install zoxide || return 1
      ;;
    dnf)
      radp_utils_run "$g_sudo dnf install -y zoxide" || return 1
      ;;
    *)
      radp_utils_retry -- "curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh" || return 1
      ;;
  esac
}
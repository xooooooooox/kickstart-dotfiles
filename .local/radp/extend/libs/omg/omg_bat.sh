#!/usr/bin/env/bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_bat_install() {
  if command -v bat >/dev/null 2>&1; then
    radp_log_info "bat already installed"
    return 0
  fi
  case "$g_guest_distro_pkg" in
    brew | dnf)
      radp_os_pkg_install "bat" || return 1
      ;;
    *)
      # https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-aarch64-unknown-linux-gnu.tar.gz
      # see https://github.com/sharkdp/bat?tab=readme-ov-file#installation
      radp_log_error "Not support install bat on current os"
      return 1
      ;;
  esac

}

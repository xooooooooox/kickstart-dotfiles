#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

function radp_omg_fastfetch_install() {
  if command -v fastfetch >/dev/null 2>&1; then
    radp_log_info "fastfetch already installed"
    return 0
  fi

  case "$g_guest_distro_id" in
    osx)
      brew install fastfetch || return 1
      ;;
    centos)
      case "$g_guest_distro_pkg" in
        dnf)
          $g_sudo dnf install -y fastfetch || return 1
          ;;
        *)
          radp_log_error "Not support install fastfetch"
          return 1
          ;;
      esac
      ;;
    ubuntu)
      radp_alias_apt_get fastfetch || return 1
      ;;
    *)
      radp_log_error "Not support install fastfetch"
      return 1
      ;;
  esac
}

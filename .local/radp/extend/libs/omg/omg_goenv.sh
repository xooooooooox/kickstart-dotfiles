#!/usr/bin/env/bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

function radp_omg_goenv_install() {
  if command -v goenv >/dev/null 2>&1; then
    radp_log_info "goenv already installed"
    return 0
  fi
  case "$g_guest_distro_pkg" in
    brew)
      brew install goenv
      ;;
    *)
      radp_utils_retry -- "git clone https://github.com/go-nv/goenv.git ~/.goenv" || return 1
      ;;
  esac
}

function radp_omg_go_install() {
  local version=${1:-1.23.0}
  if ! command -v goenv >/dev/null 2>&1; then
    radp_omg_goenv_install || return 1
  fi
  radp_utils_retry -- "goenv install $version" || return 1
  goenv global "$version"
}

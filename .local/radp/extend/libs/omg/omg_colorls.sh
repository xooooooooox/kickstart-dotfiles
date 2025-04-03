#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

function radp_omg_colorls_install() {
  if command -v colorls >/dev/null 2>&1; then
    radp_log_info "colorls already installed"
    return 0
  fi

  if ! command -v ruby >/dev/null 2>&1; then
    radp_omg_ruby_install || return 1
  fi
  gem install colorls || return 1
}

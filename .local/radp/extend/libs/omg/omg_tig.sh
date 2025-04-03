#!/usr/bin/env/bash
# install: https://github.com/jonas/tig/blob/master/INSTALL.adoc#installation-using-homebrew
# manual: https://jonas.github.io/tig/doc/manual.html
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_tig_install() {
  if command -v tig >/dev/null 2>&1; then
    radp_log_info "tig already installed"
    return 0
  fi
  radp_os_pkg_install 'tig' || return 1
}

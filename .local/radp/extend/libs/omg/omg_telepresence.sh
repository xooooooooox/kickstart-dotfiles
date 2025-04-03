#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_telepresence_install() {
  local version=${1:-$g_const_telepresence_version}

  if command -v telepresence >/dev/null 2>&1;then
    radp_log_info "telepresence already installed"
    return 0
  fi

  local download_url="$g_const_telepresence_download_base_url"/v"$version"
  case "$g_guest_distro_id" in
    osx)
      brew install telepresenceio/telepresence/telepresence-oss || return 1
      ;;
    *)
      download_url="$download_url"/telepresence-linux-amd64
      ;;
  esac
  radp_utils_retry -- "$g_sudo curl -fL $download_url -o /usr/local/bin/telepresence" || return 1
  radp_utils_run "$g_sudo chmod a+x /usr/local/bin/telepresence"
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function main() {
  declare -gr g_const_telepresence_version=2.17.0
  declare -gr g_const_telepresence_download_base_url=https://app.getambassador.io/download/tel2oss/releases/download
}

main

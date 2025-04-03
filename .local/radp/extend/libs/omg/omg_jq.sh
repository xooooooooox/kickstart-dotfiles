#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_jq_install() {
  if command -v jq >/dev/null 2>&1; then
    radp_log_info "jq already installed"
    return 0
  fi
  case "$g_guest_distro_pkg" in
    brew | dnf | apt-get)
      radp_os_pkg_install 'jq' || return 1
      ;;
    *)
      local version=${1:-1.7.1}
      local binary_url="https://github.com/jqlang/jq/releases/download/jq-${version}/jq-${g_guest_distro_os}-${g_guest_distro_arch_alias}"
      if radp_utils_retry -- "$g_sudo wget --no-check-cert --progress=bar:force $binary_url -O /usr/local/bin/jq"; then
        radp_utils_run "$g_sudo chmod +x /usr/local/bin/jq" || return 1
      else
        radp_log_error "failed to install jq from '$binary_url'"
        return 1
      fi
      ;;
  esac
}

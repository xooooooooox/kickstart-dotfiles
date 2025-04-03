#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_v2ray_install() {
  pushd /tmp || return 1
  local script_url="https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh"
  local script_file
  script_file=$(basename "$script_url")
  radp_utils_run "curl -O $script_url" || return 1
  radp_utils_run "$g_sudo bash $script_file" || return 1
  popd || return 1
}

function radp_omg_v2raya_install() {
  local version=${1:-'2.2.6.2'}

  case "$g_guest_distro_pkg" in
    brew)
      :
      ;;
    yum | dnf)
      if ! command -v v2ray >/dev/null; then
        radp_log_info "before install v2rayA, first install v2ray"
        radp_omg_v2ray_install || return 1
      fi
      pushd /tmp || return 1
      local url="https://github.com/v2rayA/v2rayA/releases/download/v${version}/installer_redhat_x64_${version}.rpm"
      radp_utils_retry "wget $url"
      local rpm_file
      rpm_file=$(basename "$url")
      radp_utils_run "$g_sudo rpm -i $rpm_file"
      $g_sudo systemctl start v2raya.service || return 1
      $g_sudo systemctl enable v2raya.service || return 1
      popd || return 1
      ;;
    *)
      radp_log_error "Not implemented on current os."
      return 1
      ;;
  esac
}

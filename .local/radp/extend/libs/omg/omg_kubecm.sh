#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_kubecm_install() {
  if command -v kubecm >/dev/null 2>&1; then
    radp_log_info "kubecm already installed"
    return 0
  fi
  case "$g_guest_distro_id" in
    osx)
      brew install kubecm || return 1
      ;;
    *)
      local version=${1:-0.27.1}
      local tmp_dir binary_url downloaded_file
      binary_url="https://github.com/sunny0826/kubecm/releases/download/${version}/kubecm_${version}_${g_guest_distro_os}_${g_guest_distro_arch}.tar.gz"
      downloaded_file=kubecm.tar.gz
      tmp_dir=$(mktemp -d)
      pushd "$tmp_dir" || return 1
      radp_utils_retry "curl -Lo $downloaded_file $binary_url" || return 1
      # linux & macos
      tar -zxvf $downloaded_file kubecm
      cd kubecm || return 1
      radp_utils_run "$g_sudo mv -v kubecm /usr/local/bin/"
      radp_utils_run "$g_sudo chmod +x /usr/local/bin/kubecm"
      ;;
  esac
}

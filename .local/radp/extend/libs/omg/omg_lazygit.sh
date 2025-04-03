#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_lazygit_install() {
  local version=${1:-0.43.1}
  if command -v lazygit >/dev/null 2>&1;then
    radp_log_info "lazygit already installed"
    return 0
  fi

  case "$g_guest_distro_pkg" in
    brew)
      brew install lazygit
      ;;
    dnf)
      $g_sudo dnf copr enable atim/lazygit -y
      $g_sudo dnf install -y lazygit
      ;;
    *)
      local download_url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_${g_guest_distro_os}_${g_guest_distro_arch}.tar.gz"
      local target=/usr/local/bin/lazygit
      radp_utils_retry -- "$g_sudo wget --no-check-cert --progress=bar:force $download_url -O $target"
      ;;
  esac
}

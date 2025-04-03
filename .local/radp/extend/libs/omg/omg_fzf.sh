#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_fzf_install() {
  if command -v fzf >/dev/null 2>&1; then
    radp_log_info "fzf already installed"
    return 0
  fi
  case "$g_guest_distro_pkg" in
    brew | dnf)
      radp_os_pkg_install "fzf" || return 1
      ;;
    apt | apt-get)
      if [[ -d ~/.fzf ]];then
        radp_log_info "~/.fzf already exists, delete it before install fzf!"
        rm -rvf ~/.fzf || return 1
      fi
      git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf || return 1
      ~/.fzf/install || return 1
      ;;
    *)
      local version=${1:-0.55.0}
      local tarball_url tarball_filename tmpdir
      tarball_url=https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-${g_guest_distro_os}_${g_guest_distro_arch_alias}.tar.gz
      tarball_filename=$(basename "$tarball_url")
      tmpdir=$(mktemp -d)
      pushd "$tmpdir" || return 1
      radp_utils_retry -- "wget -c $tarball_url" || return 1
      tar -xzf "$tarball_filename" \
        && cd "${tarball_filename%.tar.gz}" \
        && $g_sudo mv -v ./fzf /usr/local/bin \
        && $g_sudo chmod a+x /usr/local/bin/fzf || return 1
      popd || return 1
      radp_utils_run "rm -rvf $tmpdir"
      ;;
  esac
}

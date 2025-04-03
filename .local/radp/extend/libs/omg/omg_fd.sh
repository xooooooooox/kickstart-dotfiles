#!/usr/bin/env/bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

function radp_omg_fd_install() {
  if command -v fd >/dev/null 2>&1; then
    radp_log_info "fd already installed"
    return 0
  fi
  case "$g_guest_distro_pkg" in
    brew)
      brew install fd || return 1
      ;;
    dnf | apt-get)
      radp_os_pkg_install fd-find || return 1
      ;;
    *)
      if [[ "$g_guest_distro_os" != 'linux' ]]; then
        radp_log_error "Not support install fd on current os"
        return 1
      fi
      local version=${1:-10.2.0}
      local tarball_url tarball_filename tmpdir
      tarball_url=https://github.com/sharkdp/fd/releases/download/v${version}/fd-v${version}-${g_guest_distro_arch}-unknown-linux-gnu.tar.gz
      tarball_filename=$(basename "$tarball_url")
      tmpdir=$(mktemp -d)
      pushd "$tmpdir" || return 1
      radp_utils_retry -- "wget -c $tarball_url" || return 1
      tar -xzf "$tarball_filename" \
        && $g_sudo mv -v ./fd /usr/local/bin \
        && $g_sudo chmod a+x /usr/local/bin/fd || return 1
      popd || return 1
      radp_utils_run "rm -rvf $tmpdir"
      ;;
  esac
}

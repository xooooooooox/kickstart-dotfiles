#!/usr/bin/env/bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function _install_tmux() {
  case "$g_guest_distro_pkg" in
    brew | dnf)
      radp_os_pkg_install tmux || return 1
      ;;
    *)
      local version=${1:?}
      case "$g_guest_distro_pkg" in
        apt-get)
          radp_utils_run "$g_sudo apt-get install -y libevent-dev ncurses-dev build-essential bison pkg-config libevent ncurses" || return 1
          ;;
        yum)
          radp_utils_run "$g_sudo yum install -y libevent-devel ncurses-devel gcc make bison pkg-config libevent ncurses perl" || return 1
          ;;
        *)
          return 1
          ;;
      esac
      local tarball_url tarball_filename tmpdir
      tarball_url=https://github.com/tmux/tmux/releases/download/${version}/tmux-${version}.tar.gz
      tarball_filename=$(basename "$tarball_url")
      tmpdir=$(mktemp -d)
      pushd "$tmpdir" || return 1
      radp_utils_retry -- "wget -c $tarball_url" || return 1
      tar -xzf "$tarball_filename" \
        && cd "${tarball_filename%.tar.gz}" \
        && ./configure \
        && make \
        && $g_sudo make install || return 1
      ;;
  esac
}

function radp_omg_tmux_install() {
  local version=${1:-3.4}
  if command -v tmux >/dev/null 2>&1; then
    local required_version tmux_version
    # tmux version must >= 2.6, because i used oh-my-tmux
    # see https://github.com/gpakosz/.tmux
    required_version=2.6
    tmux_version=$(tmux -V | awk '{print $2}')
    if ! radp_utils_check_version_satisfied "$tmux_version" "$required_version"; then
      _install_tmux "$version" || return 1
    fi
    radp_log_info "tmux already installed"
    return 0
  else
    _install_tmux "$version" || return 1
  fi
}

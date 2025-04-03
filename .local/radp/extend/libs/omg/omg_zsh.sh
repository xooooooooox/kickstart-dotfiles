#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

function _zsh_install_from_source() {
  local version=${1:?}
  local tmpdir
  tmpdir=$(mktemp -d)
  pushd "$tmpdir" || return 1
  radp_os_pkg_install gcc wget tar || return 1
  # centos 与 ubuntu 中 ncurses 开发库包名不同
  radp_os_pkg_install ncurses-devel || radp_os_pkg_install libncurses-dev || return 1
  radp_utils_retry "wget https://sourceforge.net/projects/zsh/files/zsh/$version/zsh-$version.tar.xz/download -O zsh.tar.xz" || return 1
  tar -xf zsh.tar.xz || return 1
  pushd "zsh-$version" || return 1
  ./configure || ./configure --with-tcsetpgrp || ./configure --without-tcsetpgrp
  make
  radp_utils_run "sleep 3"
  radp_utils_run "$g_sudo make install"
  popd || return 1
  popd || return 1
  if [[ -n "$tmpdir" && "$tmpdir" != '/' ]]; then
    rm -rf "$tmpdir"
  fi
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_zsh_install() {
  local version=${1:-$g_omg_zsh_version}

  # 默认通过包管理工具安装 zsh, 否则通过源代码编译安装
  if ! radp_os_pkg_install 'zsh';then
    _zsh_install_from_source "$version" || return 1
  fi

}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
declare -gr g_omg_zsh_version='5.9'

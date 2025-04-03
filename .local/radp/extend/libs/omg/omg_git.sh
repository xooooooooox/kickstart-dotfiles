#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
##
# centos yum install git 默认在 /usr/bin
# 通过源代码安装会出现在 /usr/local/bin
# 一般来说 /usr/local/bin 会在 /usr/bin 之前
# 所以,只需要重新 source ~/.bashrc, git 就会默认使用这个版本了, 无需额外配置 PATH
function _install_git_from_source() {
  local version=${1:?}

  # 先安装必要依赖，再编译安装
  # see https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
  # fix error git: 'remote-https' is not a git command.
  case "$g_guest_distro_pkg" in
    dnf | yum)
      radp_os_pkg_install dh-autoreconf curl-devel expat-devel gettext-devel openssl-devel perl-devel zlib-devel getopt || return 1
      ;;
    apt-get)
      radp_utils_run "$g_sudo apt-get install -y dh-autoreconf libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev install-info" || return 1
      ;;
    *)
      return 1
      ;;
  esac
  local tmpdir tarball_url tarball_filename tarball_name
  tarball_url=https://mirrors.edge.kernel.org/pub/software/scm/git/git-${version}.tar.gz
  tarball_filename=$(basename "$tarball_url")
  tarball_name=${tarball_filename%.tar.gz}
  tmpdir=$(mktemp -d)
  pushd "$tmpdir" || return 1
  radp_utils_retry -- "wget -c $tarball_url" || return 1
  tar -xzf "$tarball_filename" || return 1
  cd "$tarball_name" \
    && ./configure \
    && make \
    && $g_sudo make install || {
    radp_log_error "Failed to install git $version from source"
    return 1
  }
}

function _install_git() {
  local version=${1:?}
  local required_version=${2:?}
  case "$g_guest_distro_pkg" in
    brew | dnf)
      radp_os_pkg_install git || return 1
      ;;
    *)
      local version=${1:?}
      _install_git_from_source "$version" || return 1
      ;;
  esac
  local current_version
  current_version=$(git --version | awk '{print $3}')
  if ! radp_utils_check_version_satisfied "$current_version" "$required_version"; then
    return 1
  fi
}

function radp_omg_git_install() {
  local version=${1:-2.43.5}
  local required_version=2.23
  if command -v git >/dev/null 2>&1; then
    local git_version
    # git restore 等命令是在 2.23+ 以后的版本引入的
    git_version=$(git --version | awk '{print $3}')
    if ! radp_utils_check_version_satisfied "$git_version" "$required_version"; then
      _install_git "$version" "$required_version" || return 1
    else
      radp_log_info "git already installed, and its version $git_version is greater than $required_version"
      return 0
    fi
  else
    _install_git "$version" "$required_version" || return 1
  fi
}

#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_ripgrep_install() {
  case "$g_guest_distro_pkg" in
    brew | dnf | apt-get)
      radp_os_pkg_install ripgrep
      ;;
    *)
      if [[ "$g_guest_distro_os" != 'linux' ]]; then
        radp_log_error "Not support install ripgrep on this os"
        return 1
      fi
      local version=${1:-14.1.0}
      local tarball_url tarball_filename tmpdir
      tarball_url=https://github.com/BurntSushi/ripgrep/releases/download/${version}/ripgrep-${version}-${g_guest_distro_arch}-unknown-linux-gnu.tar.gz
      tarball_filename=$(basename "$tarball_url")
      tmpdir=$(mktemp -d)
      pushd "$tmpdir" || return 1
      radp_utils_retry -- "wget -c $tarball_url" || return 1
      tar -xzf "$tarball_filename" \
        && cd "${tarball_filename%.tar.gz}" \
        && $g_sudo mv -v ./rg /usr/local/bin \
        && $g_sudo chmod a+x /usr/local/bin/rg || return 1
      ;;
  esac
}

function radp_omg_neovim_install() {
  local version=${1:-0.10.1}
  if command -v nvim >/dev/null 2>&1; then
    radp_log_info "nvim already installed"
    return 0
  fi

  case "$g_guest_distro_id" in
    osx)
      brew install git make unzip gcc ripgrep neovim || return 1
      ;;
    centos)
      _install_neovim_with_packages "$version" || return 1
      ;;
    ubuntu)
      _install_neovim_from_source || return 1
      ;;
    *)
      radp_log_error "Not support install neovim on $g_guest_distro_id"
      return 1
      ;;
  esac
}

function _install_neovim_from_source() {
  pushd "$HOME" || return 1

  # clone sources
  if [[ ! -d "$HOME"/neovim ]]; then
    git clone --depth 1 https://github.com/neovim/neovim || {
      radp_log_error "Failed to clone neovim"
      return 1
    }
  else
    radp_log_error "neovim may be already cloned to $HOME, please check"
    return 1
  fi

  # requirements
  case "$g_guest_distro_pkg" in
    apt | apt-get)
      $g_sudo apt-get install -y ninja-build gettext cmake unzip curl build-essential || return 1
      ;;
    dnf)
      $g_sudo dnf -y install ninja-build cmake gcc make unzip gettext curl glibc-gconv-extra || return 1
      ;;
    *)
      radp_log_error "Not support"
      return 1
      ;;
  esac

  cd neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo || {
    radp_log_error "Failed to make neovim source"
    return 1
  }

  $g_sudo make install || {
    radp_log_error "Failed to make install neovim"
    return 1
  }
  popd || return 1
}

function _install_neovim_with_packages() {
  local version=${1:?}
  local glibc_version
  if [[ "$g_guest_distro_id" == 'centos' ]]; then
    glibc_version=$(ldd --version | head -n1 | awk '{print $4}')
  else
    glibc_version=$(ldd --version | head -n1 | awk '{print $5}')
  fi
  # 对于较老版本的linux, glibc version 可能过低, 可能会报错 nvim: /lib64/libc.so.6: version `GLIBC_2.28' not found (required by nvim)
  # 为了避免这个问题，需要使用 precompile 版本的 neovim
  # see: People requiring releases that work on older glibc versions can find them at <https://github.com/neovim/neovim-releases>.
  local tarball_url tarball_filename tarball_name tmpdir
  if ! radp_utils_check_version_satisfied "$glibc_version" '2.29'; then
    tarball_url=https://github.com/neovim/neovim-releases/releases/download/v${version}/nvim-linux64.tar.gz
  else
    tarball_url=https://github.com/neovim/neovim/releases/download/v${version}/nvim-linux64.tar.gz
  fi
  tarball_filename=$(basename "$tarball_url")
  tarball_name=${tarball_filename%.tar.gz}
  tmpdir=$(mktemp -d)
  pushd "$tmpdir" || return 1
  radp_utils_retry -- "wget -c $tarball_url" || return 1
  $g_sudo tar -xzf "$tarball_filename" -C /opt \
    && $g_sudo chown -R "$g_guest_user":"$g_guest_user" /opt/"$tarball_name" \
    && $g_sudo ln -snf /opt/"$tarball_name"/bin/nvim /usr/local/bin/nvim || return 1
  popd || return 1
  rm -rvf "$tmpdir"
  if ! nvim -v >/dev/null; then
    radp_log_error "Install nvim occurs problem, please check it."
    return 1
  fi
}

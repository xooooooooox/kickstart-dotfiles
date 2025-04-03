#!/usr/bin/env bash
set -e
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function _install_nvm() {
  local version=${1:-0.40.0}
  if command -v nvm >/dev/null 2>&1; then
    radp_log_info "nvm already installed"
    return 0
  fi
  if [[ "$g_guest_distro_id" == 'osx' ]]; then
    radp_log_warn "osx 建议直接使用 oh-my-zsh plugin, plugin 会自动安装"
    return 0
  fi
  radp_log_info "Installing nvm $version"
  # nvm 已经不建议使用 homebrew 安装了
  # see https://github.com/nvm-sh/nvm?tab=readme-ov-file#important-notes
  radp_omg_git_install || return 1 # 解决 git: 'remote-https' is not a git command
  # 脚本会自动追加到 ~/.bashrc
  radp_utils_retry -- "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$version/install.sh | bash" || return 1
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true
}

function _install_nodejs_with_nvm() {
  # 对于 Linux, nodejs 可以安装的版本, 受 glibc 版本的影响
  # 比如 node v18.x 默认情况下在 centos7 上安装就会有问题, 会报错 node: /lib64/libm.so.6: version `GLIBC_2.27' not found
  # 因为默认情况下, centos7 ldd --version 为 2.17
  local version=${1:-16.20.2}
  if ! command -v nvm >/dev/null 2>&1; then
    if [[ -d "$NVM_DIR" ]]; then
      # 反正也不知道为什么, 它就是找不到 nvm, 手动 load nvm, 避免环境变量问题
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true
    else
      _install_nvm || return 1
    fi
  fi

  if nvm which "$version" > /dev/null 2>&1; then
    radp_log_info "nodejs $version already installed"
    return 0
  fi
  nvm install "$version" || return 1
  nvm use "$version"
}

function _install_nodejs_with_vofx() {
  local version=${1:?}
  if ! command -v vfox >/dev/null 2>&1; then
    radp_log_warn "vfox not installed"
    radp_omg_vfox_install || return 1
  fi
  # 由于 vfox 对于已经安装过的 plugin, vfox add 会 return 1, 所以这里 || true
  vfox add nodejs || true
  if ! vfox list nodejs | awk '{print $2}' | grep -q "${version}$"; then
    vfox install nodejs@"${version}" || {
      radp_log_error "failed to install nodejs ${version}"
      return 1
    }
    vfox use -g nodejs@"$version" || {
      radp_log_error "Failed to run vfox use -g nodejs@$version"
      return 1
    }
  fi
}


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_nvm_install() {
  local version=${1:-0.39.7}
  _install_nvm "$version" || return 1
}

function radp_omg_nodejs_install() {
  local version=${1:-16.20.2}

  case "$g_guest_distro_pkg" in
  brew | dnf)
    _install_nodejs_with_vofx "$version" || return 1
    ;;
  *)
    _install_nodejs_with_nvm "$version" || return 1
    ;;
  esac
}

#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# fix 低版本 gcc 导致 centos7 rbenv install failed
function _install_newer_gcc() {
  radp_utils_run "$g_sudo yum install centos-release-scl"
  radp_utils_run "$g_sudo yum install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils"
}

function _install_ruby_with_rbenv() {
  local version=${1:?}

  if ! command -v rbenv >/dev/null 2>&1; then
    radp_log_error "rbenv not installed"
    radp_omg_rbenv_install || return 1
  fi

  if ! rbenv versions | grep -q "${version}\b"; then
    rbenv install "$version" || return 1
    rbenv global "$version"
    rbenv rehash
  else
    radp_log_info "ruby $version already installed"
    return 0
  fi
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_rbenv_install() {
  if command -v rbenv >/dev/null 2>&1; then
    radp_log_info "rbenv already installed"
    return 0
  fi

  radp_log_info "Installing rbenv"
  case "$g_guest_distro_pkg" in
  brew)
    brew install rbenv || return 1
    ;;
  dnf)
    $g_sudo dnf install -y rbenv ruby-devel || return 1
    ;;
  *)
    # fix 安装了 rbenv 后,还是无法 rbenv install 的问题,
    # see https://github.com/rbenv/rbenv?tab=readme-ov-file#installing-ruby-versions
    # see https://github.com/rbenv/ruby-build/wiki#suggested-build-environment
    case "$g_guest_distro_pkg" in
    yum)
      # requirements
      $g_sudo yum install -y autoconf gcc patch bzip2 openssl-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel tar || return 1
      ;;
    apt-get)
      radp_alias_apt_get install -y autoconf patch build-essential rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev || return 1
      ;;
    dnf)
      $g_sudo dnf install -y autoconf gcc rust patch make bzip2 openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel || return 1
      ;;
    esac
    radp_utils_retry -- "curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash" || return 1
    if ! curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-doctor | bash; then
      radp_log_error "Failed to install rbenv via rbenv-installer."
      return 1
    fi
    if [[ ! -d $HOME/.rbenv/plugins ]]; then
      git clone --depth 1 https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
    fi
    ;;
  esac
}

function _install_ruby_with_vofx() {
  local version=${1:?}
  if ! command -v vfox >/dev/null 2>&1; then
    radp_log_error "vfox not installed"
    return 1
  fi
  # 由于 vfox 对于已经安装过的 plugin, vfox add 会 return 1, 所以这里 || true
  vfox add ruby || true

  # 使用 vfox 安装 ruby 需要使用 ruby-build
  if ! command -v ruby-build >/dev/null 2>&1; then
    case "$g_guest_distro_pkg" in
    brew)
      brew install ruby-build || return 1
      ;;
    *)
      radp_log_error "No support install ruby-build on current os."
      return 1
      ;;
    esac
  fi
  if ! vfox list ruby | awk '{print $2}' | grep -q "${version}$"; then
    # 反正就是会安装失败
    # 报错: error    libmamba Could not solve for environment specs
    vfox install ruby@"${version}" || {
      radp_log_error "failed to install ruby ${version}"
      return 1
    }
    vfox use -g ruby@"$version" || {
      radp_log_error "Failed to run vfox use -g ruby@$version"
      return 1
    }
  fi
}

function radp_omg_ruby_install() {
  local version=${1:-$g_omg_ruby_version}

  case "$g_guest_distro_pkg" in
  brew)
    # 必须使用 3.1.2.rb 版本, 这种版本号是使用 ruby-build 本地编译安装的
    # 如果直接安装 3.1.2 版本, 虽然可能可以安装成功, 但是 gem install 可能会失败
    version="$version.rb"
    _install_ruby_with_vofx "$version" || return 1
    ;;
  *)
    _install_ruby_with_rbenv "$version" || return 1
    ;;
  esac
}
##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
declare -gr g_omg_ruby_version='3.2.2'

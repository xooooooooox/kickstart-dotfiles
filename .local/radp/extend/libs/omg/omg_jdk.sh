#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_jenv_install() {
  if [[ -d "$HOME/.jenv/bin" ]]; then
    export PATH=${HOME}/.jenv/bin:$PATH # 进一步保证重复安装
  fi
  if command -v jenv >/dev/null 2>&1; then
    eval "$(jenv init -)" # 保证 jenv 功能能正常使用
    return 0
  fi

  case "$g_guest_distro_id" in
  osx)
    radp_alias_brew install jenv || return 1
    ;;
  *)
    radp_utils_run "git clone --depth 1 ${g_omg_jenv_git_repo} ~/.jenv"
    export PATH=${HOME}/.jenv/bin:$PATH
    ;;
  esac
}

function radp_omg_openjdk_install() {
  local version=${1:-}
  radp_omg_jdk_install "$version" "openjdk"
}

function radp_omg_jdk_install() {
  local jdk_version=${1:-$g_omg_jdk_version}
  local jdk_type=${2:-$g_omg_jdk_type}

  case "$g_guest_distro_pkg" in
  brew)
    _install_jdk_with_vfox "$jdk_version" || return 1
    ;;
  *)
    _install_jdk_with_jenv "$jdk_version" "$jdk_type" || return 1
    ;;
  esac
}

function _install_jdk_with_vfox() {
  local jdk_version=${1:?}
  local jdk_type=${2:-tem}

  if ! command -v vfox >/dev/null 2>&1; then
    radp_omg_vfox_install || return 1
  fi

  if [[ "$g_guest_distro_arch_alias" == 'arm64' && jdk_version -eq 8 ]];then
    # mbp arm can't install java@8-tem, but can install java@8-amzn
    jdk_type='amzn'
  fi

  vfox add java || true
  local version="${jdk_version}-${jdk_type}"
  if ! vfox list java | awk '{print $2}' | grep -q "v${jdk_version}."; then
    vfox install java@"${version}" || {
      radp_log_error "failed to vfox install java@${version}"
      return 1
    }
    local full_version
    full_version=$(vfox list java | awk '{print $2}' | grep "$v${jdk_version}.")
    vfox use -g java@"${full_version#v}" || {
      radp_log_error "Failed to run vfox use -g java@$full_version"
      return 1
    }
  fi
}

function _install_jdk_with_jenv() {
  local jdk_version=${1:?}
  local jdk_type=${2:?}
  if ! command -v jenv >/dev/null 2>&1; then
    radp_omg_jenv_install || return 1
  fi
  # fixme 这里判断是否已经安装, 需要优化
  if jenv version | grep -q "$jdk_version"; then
    radp_log_info "$jdk_type $jdk_version already installed"
    return 0
  fi

  _install_jdk_from_pkg "$jdk_version" "$jdk_type"

  # 不知道为什么脚本中执行 enable-plugin 会报错 no such command 'enable-plugin'
  # 这一步骤的作用是为了设置 JAVA_HOME
  eval "$(jenv init -)" && jenv enable-plugin export || return 1
}

function _install_jdk_from_pkg() {
  local jdk_version=${1:?}
  local jdk_type=${2:?}

  case "$g_guest_distro_id" in
  osx)
    local formula="$jdk_type"@"$jdk_version"
    if radp_io_prompt_continue --msg "brew install $formula, continue(y/N)" --default n --timeout 10; then
      radp_alias_brew install "$formula" || return 1
      # 由于 intel mac 与 arm mac homebrew 默认安装路径不一样
      if [[ -z "$HOMEBREW_PREFIX" || ! -d "$HOMEBREW_PREFIX" ]]; then
        radp_log_error "Invalid HOMEBREW_PREFIX '$HOMEBREW_PREFIX'"
        return 1
      fi
      # for the system java wrapper to find this jdk
      sudo ln -sfn "${HOMEBREW_PREFIX}"/opt/"${formula}"/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/"${jdk_type}"-"${jdk_version}".jdk
      jenv add "${HOMEBREW_PREFIX}"/opt/"${formula}"/libexec/openjdk.jdk/Contents/Home
    fi
    ;;
  centos)
    if [[ "$jdk_version" == 8 ]]; then
      jdk_version=1.8.0
    fi
    radp_os_pkg_install "java-${jdk_version}-${jdk_type}" "java-${jdk_version}-${jdk_type}-devel"
    # add JAVA_HOME to jenv
    local java_home=/etc/alternatives/java_sdk_${jdk_version}
    radp_utils_run "jenv add $java_home"
    local full_jdk_version
    full_jdk_version=$(jenv versions | grep "$jdk_version" | head -n 1 | xargs)
    jenv global "$full_jdk_version" # 不这么做的话, 虽然 java -version 已经显示成功安装了, 但是此时 JAVA_HOME 是没有的
    ;;
  ubuntu)
    radp_utils_run "radp_alias_apt_get install -y ${jdk_type}-${jdk_version}-jdk"
    local java_home=/usr/lib/jvm/java-${jdk_version}-${jdk_type}-${g_guest_distro_arch_alias}
    radp_utils_run "jenv add $java_home"
    local full_jdk_version
    full_jdk_version=$(jenv versions | grep "$jdk_version" | head -n 1 | xargs)
    jenv global "$full_jdk_version"
    ;;
  *)
    radp_log_error "Not implemented on current os."
    return 1
    ;;
  esac
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function main() {
  declare -gr g_omg_jdk_type=openjdk
  declare -gr g_omg_jdk_version=8
  declare -gr g_omg_jenv_git_repo='https://github.com/jenv/jenv.git'
}

main

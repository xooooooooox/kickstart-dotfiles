#!/usr/bin/env bash
set -e

# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function _install_python_requirements() {
  local distro_name pkg_manager
  IFS=':' read -r _ distro_name _ pkg_manager < <(radp_os_get_distro_info)
  case "$pkg_manager" in
    yum)
      radp_utils_run radp_utils_retry -- "$g_sudo" yum install -y git
      radp_utils_run radp_utils_retry -- "$g_sudo" yum groupinstall -y "Development Tools"
      radp_utils_run radp_utils_retry -- "$g_sudo" yum install -y zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel
      ;;
    apt)
      radp_utils_run radp_utils_retry -- "$g_sudo" apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git
      ;;
    brew)
      radp_utils_run radp_utils_retry -- brew install openssl readline sqlite3 xz zlib
      ;;
    *)
      radp_log_error "Unsupported install requirement for python in distribution '$distro_name'"
      exit 1
      ;;
  esac
}

function _configure_pypi() {
  local pypi_index_url=${1:-$g_omg_pypi_index_url}

  # step1: setup pqi
  if ! command -v pqi >/dev/null 2>&1; then
    radp_utils_run pip install pqi
    radp_utils_run "mkdir -p ${HOME}/.config/pip"
  else
    radp_log_debug "pqi is already installed"
  fi

  # step2: 切换 pypi 源
  if ! pqi show | grep -qF "${pypi_index_url}"; then
    local status_code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$pypi_index_url")
    if ((status_code != 500)); then
      radp_utils_run pqi add nexus "$pypi_index_url" # 添加 pypi 私有源
      radp_utils_run pqi use nexus
      radp_log_info "Switched to PyPI private source: $pypi_index_url"
    else
      radp_log_warn "PyPI private source can't reach: '$pypi_index_url', falling back to aliyun"
      radp_utils_run pqi use aliyun
    fi
  else
    radp_log_debug "PyPI Private source is already set to $pypi_index_url"
    return 0
  fi
}

function _install_python_with_pyenv() {
  local python_version=${1:?}

  if ! command -v pyenv >/dev/null 2>&1; then
    radp_log_error "pyenv not installed"
    return 1
  fi

  if ! pyenv versions | grep -q "${python_version}\b"; then
    pyenv install "$python_version" || return 1
    pyenv global "$python_version"
    python -m pip install --upgrade pip
    radp_log_info "Python installed successfully and has been set to global."
  else
    radp_log_debug "Python $python_version already installed"
    return 0
  fi
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_pyenv_install() {
  if command -v pyenv >/dev/null; then
    radp_log_debug "Pyenv already installed."
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    radp_os_pkg_install git
  fi
  case "$g_guest_distro_id" in
    osx)
      brew install pyenv || return 1
      ;;
    *)
      radp_utils_retry -- "curl $g_omg_pyenv_install_url | bash" || return 1
      ;;
  esac
}

function _install_python_with_vfox() {
  local version=${1:?}
  if ! command -v vfox >/dev/null 2>&1; then
    radp_log_error "vfox not installed"
    return 1
  fi
  # 由于 vfox 对于已经安装过的 plugin, vfox add 会 return 1, 所以这里 || true
  vfox add python || true
  if ! vfox list python | awk '{print $2}' | grep -q "${version}$"; then
    vfox install python@"${version}" || {
      radp_log_error "failed to vfox install python@${version}"
      return 1
    }
    vfox use -g python@"$version" || {
      radp_log_error "Failed to run vfox use -g python@$version"
      return 1
    }
  fi
}

function radp_omg_python_install() {
  local python_version=${1:-$g_omg_python_version}

  case "$g_guest_distro_pkg" in
  brew)
    _install_python_with_vfox "$python_version" || return 1
    ;;
  *)
    _install_python_with_pyenv "$python_version" || return 1
    ;;
  esac
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
declare -gr g_omg_python_version='3.7.11'
declare -gr g_omg_pyenv_install_url='https://pyenv.run'
declare -gr g_omg_pypi_index_url='https://nexus.seyvoue.com/repository/pypi-public/simple'

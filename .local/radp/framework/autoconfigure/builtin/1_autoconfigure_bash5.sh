#!/usr/bin/env bash
# shellcheck source=./../../bootstrap.sh

#######################################
# 自动配置并安装 Bash 5.x。这个函数检查当前 Bash 的版本，
# 如果版本低于 4.3，则自动下载、编译并安装 Bash 5.x。
# 此过程包括安装必要的开发工具、下载 Bash 源码包、
# 编译安装新版本的 Bash。安装后，会使用新版本的 Bash 重新执行脚本。
# Globals:
#   BASH_VERSINFO 一个数组，包含了 Bash 的主要和次要版本号等信息
#   BASH_VERSION 当前 Bash 的版本号。
#   g_command_line 包含了原始脚本启动时使用的命令行参数的数组
#   g_sudo
# Arguments:
#   None
# Returns:
#   1 如果安装失败
#   0 如果 Bash 版本满足要求，或成功安装了新版本
#######################################
function __framework_setup_builtin_bash5() {
  local bash_download_url=$g_framework_builtin_bash_download_url

  # 检查是否在 Bash 环境中运行
  if [[ -z "$BASH_VERSION" ]]; then
    radp_log_error "This script requires Bash. Current shell is not Bash."
    return 1 # Exit the function with an error status
  fi

  # 是否通过 Bash 执行或者版本号大于等于 4.3, 若不满足则安装
  # (因为脚本中使用了很多高级特性，低版本如 CentOS 7 默认自带的 4.2.x 并不支持)
  if radp_os_check_bash_version "4.3"; then
    return 0
  fi

  if ! radp_io_prompt_continue --msg "将自动安装高版本 Bash，安装完成后将会重新执行刚刚的指令。是否继续(y/N)" --default y --level warn; then
    radp_log_warn "已取消自动安装，请手动安装高版本 bash，并使用高版本 bash 重新运行当前脚本 '${g_command_line[*]}'"
    return 1
  fi

  # step1: 安装必要的依赖
  #  radp_utils_run radp_utils_retry -- "$g_sudo" yum groupinstall -y "Development Tools"
  radp_utils_retry -- "$g_sudo" yum install -y gcc gcc-c++ make bison flex ncurses-devel openssl-devel curl || return 1

  # step2: 下载源码包
  local bash5_release bash5_release_url download_dir
  bash5_release_url=${bash_download_url}
  download_dir=${g_framework_tmp_path}
  bash5_release="${download_dir}"/${bash5_release_url##*/}
  if [[ ! -f "$bash5_release" ]]; then # 为了避免极端情况下重复下载的问题（如已经安装了，但始终无法以 bash5 运行）
    radp_log_debug "Downloading $bash5_release_url to $bash5_release..."
    [[ ! -d "$download_dir" ]] && mkdir -pv "$download_dir"
    radp_utils_retry -- "curl -k ${bash5_release_url} -o ${bash5_release}" || {
      radp_log_error "Failed to download $bash5_release_url"
      return 1
    }
  fi

  # step3: 编译安装
  if (
    local tmp_dir filename
    tmp_dir="$(dirname "${bash5_release}")"
    filename="$(basename "${bash5_release}")"
    cd "${tmp_dir}"
    tar -xzvf "${filename}"
    cd "${filename%.*.*}"
    ./configure
    make
    $g_sudo make install
  ); then
    radp_log_info "成功编译安装高版本 bash."
  else
    radp_log_error "编译安装高版本 bash 失败"
    exit 1
  fi
  # 追加环境变量
  __framework_export_path
  radp_utils_rerun_command_line "${g_command_line[@]}"
}

#######################################
# 追加到环境变量 PATH 中，且保证不重复追加
# Globals:
#   g_command_line
#   g_sudo
#   g_main_script_bin_path
#   g_main_script_name
# Arguments:
#   0
#######################################
function __framework_export_path() {
  radp_log_debug "main script name: $g_main_script_name"
  if ! command -v "$g_main_script_name" >/dev/null; then
    local pkg_manager _
    IFS=':' read -r _ _ _ pkg_manager < <(radp_os_get_distro_info)
    case "$pkg_manager" in
      brew)
        # 对于 macos 暂时不自动添加
        return 0
        ;;
      *)
        radp_utils_run "$g_sudo ln -snf ${g_main_script_bin_path}/${g_main_script_name} /usr/bin/$g_main_script_name"
        # 为了保证所有用户均能找到 radpctl，将环境变量追加到 /etc/profile.d/my.sh 中
        #        local radpctl_global_env_file=/etc/profile.d/my.sh
        #        if ! $g_sudo test -f "$radpctl_global_env_file"; then
        #          radp_utils_run "$g_sudo touch $radpctl_global_env_file"
        #        fi
        #        radp_io_append_single_line_to_file "${radpctl_global_env_file}" "export PATH=${g_main_script_bin_path}:\$PATH"
        ;;
    esac
  fi
}

#######################################
# 准备 bash5 环境(全自动)
# Arguments:
#  None
#######################################
function main() {
  __framework_setup_builtin_bash5 || return 1
  __framework_export_path || return 1
}

main

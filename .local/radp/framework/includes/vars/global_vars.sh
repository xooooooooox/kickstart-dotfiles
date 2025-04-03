#!/usr/bin/env bash
# shellcheck source=../../bootstrap.sh

#######################################
# 加载指定的配置文件。
# 如果指定了 '--required' 标志，则认为配置文件是必需的，如果配置文件不存在将返回错误。
# 如果没有指定 '--required' 标志，则配置文件被视为可选的，其不存在不会导致错误，只会打印警告信息。
#
# Globals:
#  None
#
# Arguments:
#  $1 (可选) - '--required' 标志，表明后续的文件名参数是必需的
#  $2 or $1 - 配置文件路径。如果存在 '--required'，则为 $2，否则为 $1
#
# Returns:
#  如果成功加载配置文件或文件为可选且不存在，则返回 0。
#  如果文件是必需的但不存在，或文件存在但无法加载，则返回 1。
#
# Examples:
#  __framework_load_config_file /path/to/optional/config.sh
#  __framework_load_config_file --required /path/to/required/config.sh
#######################################
function __framework_load_config_file() {
  local required=false
  if [[ "$1" == '--required' ]]; then
    required=true
    shift
  fi

  local config_file=${1:?}

  if [[ ! -f "$config_file" ]]; then
    if $required; then
      echo "Error: Required config file '$config_file' not found." >&2
      return 1
    else
#      echo "Warning: Optional config file '$config_file' not found, skipping."
      return 0 # Return success for optional files that do not exist
    fi
  fi

  # If the file exists, source it
  # shellcheck disable=SC1090
  source "$config_file" || {
    echo "Failed to load config '$config_file'" >&2
    return 1
  }
}

#######################################
# 声明全局常量
# Globals:
#   g_framework_includes_root
# Arguments:
#  None
#######################################
function __framework_declare_constants_vars() {
  radp_source_local_scripts "$g_framework_includes_root"/vars/constants || return 1
}

#######################################
# 声明全局运行时变量
# Globals:
#   g_framework_includes_root
# Arguments:
#  $@
#######################################
function __framework_declare_runtime_vars() {
  radp_source_local_scripts "$g_framework_includes_root"/vars/runtime "$@" || return 1
}

#######################################
# 声明可配置化的全局变量
# Globals:
#   g_env
#   g_framework_base_config_filename - 框架基础配置文件名
#   g_framework_config_path - 框架配置文件目录
#   g_framework_includes_root - 框架库根目录
#   g_user_base_config_filename - 外部用户扩展基础配置文件名
#   g_user_config_path - 外部用户扩展配置文件目录
# Arguments:
#  None
# Returns:
#   1 - 如果加载配置文件或声明全局变量失败
#
# @see configurable_setup.sh
# @see configurable_vars.sh
#######################################
function __framework_declare_configurable_vars() {
  # 基本逻辑: 先加载配置文件，然后声明全局变量

  # 1. 加载基础配置文件 radpctl_config.sh 以及 configurable_setup.sh 中声明的全局变量
  __framework_load_config_file --required "$g_framework_config_path"/"$g_framework_base_config_filename" || return 1
  radp_source_local_scripts "$g_framework_includes_root"/vars/configurable/configurable_setup.sh || return 1
  # 2. 加载框架环境配置文件 radpctl_config_xx.sh
  local framework_env_config_filename
  framework_env_config_filename=$(radp_vars_get_env_config_filename "$g_env" "$g_framework_base_config_filename")
  __framework_load_config_file "$g_framework_config_path"/"$framework_env_config_filename" || return 1
  # 3. 加载外部用户基础配置文件 radpctl.sh
  __framework_load_config_file "$g_user_config_path"/"$g_user_base_config_filename" || return 1
  # 4. 加载外部用户环境配置文件 radpctl_xx.sh
  local user_env_config_filename
  user_env_config_filename=$(radp_vars_get_env_config_filename "$g_env" "$g_user_base_config_filename")
  __framework_load_config_file "$g_user_config_path"/"$user_env_config_filename" || return 1

  # 5. 声明 configurable_vars.sh 中的变量
  radp_source_local_scripts "$g_framework_includes_root"/vars/configurable/configurable_vars.sh || return 1
}

#######################################
# 统一声明所有全局变量
# 命名规范：脚本内所有全局变量必须为小写，且为以下格式(除 gxw_xxx 外，均为只读)）
#   1) g_xxx: 只读
#   2) gx_xxx: export了的全局变量，保证父子进程可见性
#   3) gxw_xxx: 可读写，一般用于运行时数据的存储
# 分类: 包括三类全局变量
#   1) xxx_constants.sh: 常量/写死/不可配置
#   2) configurable_vars.sh: 可配置变量(即可通过配置文件进行配置化的全局变量)
#   3) dynamic_xxx.sh: 动态变量/运行时,主要是一些运行态的数据存储
# 使用规范
#   1) 脚本业务逻辑中不允许使用大写的全局变量！！！！
#   2) 大写的全局变量表示环境变量，仅可出现在配置文件中
#
# Arguments:
#   $@ - 命令行所有参数
#
#######################################
function main() {
  __framework_declare_constants_vars
  __framework_declare_configurable_vars
  __framework_declare_runtime_vars "$@"
}

main "$@"

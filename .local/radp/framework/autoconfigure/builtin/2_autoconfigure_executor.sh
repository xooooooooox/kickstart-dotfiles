#!/usr/bin/env bash
# shellcheck source=../../bootstrap.sh

#######################################
# 设置子命令与执行器脚本的映射关系。
# 此函数扫描指定路径下的所有脚本文件，并根据给定的正则表达式识别子命令名称，
# 然后将子命令名称与其对应的执行器脚本文件路径映射到提供的关联数组中。
#
# Globals:
#   None
#
# Arguments:
#   1 - __nr_subcmd_executor_mapper__ - 命名引用变量，用于存储子命令与执行器脚本的映射关系。
#   2 - executor_path - 执行器脚本所在的目录路径。
#   3 - executor_regex - （可选）正则表达式，用于从脚本文件名中提取子命令名称。默认为 '^(.*)_executor.*\.sh$'。
#
# Returns:
#   无
#
# Examples:
#   假设 /path/to/executors 目录下有名为 start_executor.sh 和 stop_executor.sh 的脚本文件：
#   ```
#   declare -A subcmd_executor_mapper
#   radp_nr_set_subcmd_executor_mapper subcmd_executor_mapper "/path/to/executors"
#   # 此时，subcmd_executor_mapper 关联数组将包含：
#   # ["start"]="/path/to/executors/start_executor.sh"
#   # ["stop"]="/path/to/executors/stop_executor.sh"
#   ```
#
# Notes:
#   - 执行器脚本命名应遵循通过正则表达式 '^(.*)_executor.*\.sh$' 可以识别的命名规则。
#   - 此函数依赖于 radp_lang_check_var_type 函数来验证 __nr_subcmd_executor_mapper__ 参数确实是一个关联数组。
#   - 使用 mapfile 命令和 < <() 结构来读取 find 命令的输出，确保能正确处理文件名中的空格等特殊字符。
#######################################
function __framework_set_subcmd_executor_mapper() {
  local -n __nr_subcmd_executor_mapper__=${1:?}
  local executor_path=${2:?}
  local executor_regex=${3:?}

  radp_lang_check_var_type __nr_subcmd_executor_mapper__ -A

  if [[ -e "$executor_path" ]]; then
    local -a executor_files
    mapfile -t executor_files < <(find "$executor_path" -type f -name "*.sh")
    local executor_file executor_filename subcmd
    for executor_file in "${executor_files[@]}"; do
      executor_filename=$(basename "$executor_file")
      if [[ $executor_filename =~ $executor_regex ]]; then
        subcmd="${BASH_REMATCH[1]}"
        __nr_subcmd_executor_mapper__["$subcmd"]="$executor_file"
      fi
    done
  fi
}


#######################################
# 将命令与其帮助手册文件(.man)进行映射。
# 此函数搜索指定路径下所有的手册文件(.man)，并根据文件名与给定的正则表达式匹配结果，
# 建立命令名称与手册文件路径之间的映射关系。
#
# Globals:
#   None
#
# Arguments:
#   1 - __nr_cmd_man_mapper__ - 命名引用变量，用于存储命令与手册文件的映射关系。
#   2 - cmd_man_path - 手册文件所在的目录路径。
#   3 - cmd_man_regex - （可选）正则表达式，用于从手册文件名中提取命令名称。默认值为 '^(.*)_executor.*\.man$'。
#
# Returns:
#   无
#
# Examples:
#   假设 /path/to/mans 目录下有名为 start_executor.man 和 stop_executor.man 的手册文件：
#   ```
#   declare -A cmd_man_mapper
#   radp_nr_cmd_man_mapper cmd_man_mapper "/path/to/mans"
#   # 此时，cmd_man_mapper 关联数组将包含：
#   # ["start"]="/path/to/mans/start_executor.man"
#   # ["stop"]="/path/to/mans/stop_executor.man"
#   ```
#
# Notes:
#   - 手册文件的命名应遵循通过正则表达式 '^(.*)_executor.*\.man$' 可以识别的规则。
#   - 此函数依赖于 radp_lang_check_var_type 函数来验证 __nr_cmd_man_mapper__ 参数确实是一个关联数组。
#######################################
function __framework_set_cmd_man_mapper() {
  local -n __nr_cmd_man_mapper__=${1:?}
  local cmd_man_path=${2:?}
  local cmd_man_regex=${3:?}

  radp_lang_check_var_type __nr_cmd_man_mapper__ -A

  if [[ -e "$cmd_man_path" ]]; then
    local -a executor_man_files
    mapfile -t executor_man_files < <(find "$cmd_man_path" -type f -name "*.man")
    local executor_man_file executor_man_filename subcmd
    for executor_man_file in "${executor_man_files[@]}"; do
      executor_man_filename=$(basename "$executor_man_file")
      if [[ $executor_man_filename =~ $cmd_man_regex ]]; then
        subcmd="${BASH_REMATCH[1]}"
        __nr_cmd_man_mapper__["$subcmd"]="$executor_man_file"
      fi
    done
  fi
}

#######################################
# 自动注入子命令 subcmd 和 执行器 executor 映射关系，包括:
# 1. 自动注入子命令 subcmd 和 执行器脚本 subcmd_executor.sh 的映射关系
#   1) 首先尝试为框架内置的子命令设置执行器映射
#   2) 然后为用户定义的子命令设置执行器映射。
#   3) 若出现同名子命令，优先级：用户子命令映射器 > 框架内置子命令映射器
# 2. 自动注入子命令 subcmd 和 执行器命令行帮助文档 subcmd_executor.man 的映射关系
#
# Globals:
#   g_cli_subcmd_executor_mapper - 关联数组，用于存储子命令名称与执行器脚本文件路径之间的映射。
#   g_framework_executor_path - 框架的执行器脚本所在目录路径。
#   g_user_executor_path - 用户的执行器脚本所在的目录路径。
#   g_user_executor_regex - 用户定义的正则表达式，用于从执行器脚本文件名中提取子命令名称。
#   g_cli_cmd_man_mapper - 关联数组，用于存储命令名称与手册文件路径的映射。
#   g_framework_man_path - 框架手册文件所在目录路径。
#   g_user_man_path - 用户手册文件所在目录路径。
#   g_user_man_regex - 用户定义的正则表达式，用于从手册文件名中提取命令名称。
#
# Arguments:
#  None
#
# Notes
#   subcmd -> subcmd_executor.sh
#   1) 这个过程涉及搜索指定的执行器脚本目录，并根据脚本文件名与给定正则表达式的匹配结果来建立子命令名称与脚本文件路径之间的映射关系。
#   2) 如果在配置框架或用户子命令执行器映射过程中遇到任何错误，将记录错误日志并退出程序
#   3) 依赖于 radp_nr_set_subcmd_executor_mapper 函数来完成实际的映射配置工作。
#   4) 执行器脚本的命名和存放路径需按照预定的规则设置，以保证可以被正确识别和映射
#   subcmd -> subcmd_executor.man
#   1) 如果在配置框架或用户命令帮助手册文件映射过程中遇到任何错误，将记录错误日志并退出程序。
#   2) 依赖于 radp_nr_cmd_man_mapper 函数来完成映射配置工作
#######################################
function main() {
  # 1. subcmd -> executor_file mapping
  __framework_set_subcmd_executor_mapper g_cli_subcmd_executor_mapper "${g_framework_executor_path}" "$g_framework_executor_regex" || {
    radp_log_error "Autoconfigure framework subcmd executor mapper failed"
    exit 1
  }
  __framework_set_subcmd_executor_mapper g_cli_subcmd_executor_mapper "${g_user_executor_path}" "${g_user_executor_regex}" || {
    radp_log_error "Autoconfigure user subcmd executor mapper failed"
    exit 1
  }
  radp_log_debug "Autoconfigure framework's and user's subcmd-executor mapper: $(radp_nr_utils_print_assoc_arr g_cli_subcmd_executor_mapper)"

  # 2. subcmd -> executor_man_file mapping
  __framework_set_cmd_man_mapper g_cli_cmd_man_mapper "${g_framework_man_path}" "$g_framework_man_regex" || {
    radp_log_error "Autoconfigure framework cmd-man mapper failed"
    exit 1
  }
  __framework_set_cmd_man_mapper g_cli_cmd_man_mapper "${g_user_man_path}" "${g_user_man_regex}" || {
    radp_log_error "Autoconfigure user cmd-man mapper failed"
    exit 1
  }
  radp_log_debug "Autoconfigure framework's and user's cmd-man mapper: $(radp_nr_utils_print_assoc_arr g_cli_cmd_man_mapper)"
}

main

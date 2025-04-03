#!/usr/bin/env bash
# shellcheck source=./../../../bootstrap.sh

#######################################
# 转换文件大小到指定单位。
# 支持单位包括 B, KB, K, MB, M, GB, G。
# Globals:
#   None
# Arguments:
#   1 - size_str: 带单位的文件大小字符串，如 '10M' 或 '1GB'.
#   2 - target_unit: 目标单位（'B', 'KB', 'K', 'MB', 'M', 'GB', 'G'），默认为'B'.
# Returns:
#   输出转换后的文件大小。
# Examples:
# converted_size=$(radp_utils_transfer_filesize "10MB" "K")
# echo "Converted Size: $converted_size K"
#######################################
function radp_utils_transfer_filesize() {
  local size_str=${1:?}
  local target_unit=${2:-B} # 默认单位为字节
  local base_size original_unit
  base_size=$(echo "$size_str" | sed -E 's/[^0-9]//g')                                 # 提取数字部分
  original_unit=$(echo "$size_str" | sed -E 's/[0-9]//g' | tr '[:lower:]' '[:upper:]') # 提取并大写单位部分

  # 转换原始大小到字节
  local size_in_bytes
  case $original_unit in
    'K' | 'KB') size_in_bytes=$((base_size * 1024)) ;;
    'M' | 'MB') size_in_bytes=$((base_size * 1024 ** 2)) ;;
    'G' | 'GB') size_in_bytes=$((base_size * 1024 ** 3)) ;;
    'B' | '') size_in_bytes=$base_size ;; # 包含无单位或只有'B'的情况
    *)
      return 1
      ;;
  esac

  # 转换字节到目标单位
  local converted_size
  case $(echo "$target_unit" | tr '[:lower:]' '[:upper:]') in
    'B') converted_size=$size_in_bytes ;;
    'K' | 'KB') converted_size=$((size_in_bytes / 1024)) ;;
    'M' | 'MB') converted_size=$((size_in_bytes / 1024 ** 2)) ;;
    'G' | 'GB') converted_size=$((size_in_bytes / 1024 ** 3)) ;;
    *)
      return 1
      ;;
  esac

  echo "$converted_size"
}

#######################################
# 打印 debug 级别日志
# Globals:
#   BASH_LINENO
#   BASH_SOURCE
#   FUNCNAME
# Arguments:
#   1 - msg: 要记录的日志消息。
#   2 - script_name (可选): 记录日志的脚本名称。如果未提供，则自动从调用栈中推断。
#   3 - func_name (可选): 记录日志的函数名称。如果未提供，则自动从调用栈中推断。
#   4 - line_no (可选): 记录日志的行号。如果未提供，则自动从调用栈中推断。
#######################################
function radp_log_debug() {
  local msg=$1
  local script_name
  script_name=${2:-$(basename "${BASH_SOURCE[2]}")}
  script_name=${script_name:-$(basename "${BASH_SOURCE[1]}")}
  local func_name=${3:-${FUNCNAME[1]}}
  local line_no=${4:-${BASH_LINENO[0]}}
  __framework_logger "debug" "$msg" "$script_name" "$func_name" "$line_no"
}

#######################################
# 打印 info 级别日志
# Globals:
#   BASH_LINENO
#   BASH_SOURCE
#   FUNCNAME
# Arguments:
#   1 - msg: 要记录的日志消息。
#   2 - script_name (可选): 记录日志的脚本名称。如果未提供，则自动从调用栈中推断。
#   3 - func_name (可选): 记录日志的函数名称。如果未提供，则自动从调用栈中推断。
#   4 - line_no (可选): 记录日志的行号。如果未提供，则自动从调用栈中推断。
function radp_log_info() {
  local msg=$1
  local script_name
  script_name=${2:-$(basename "${BASH_SOURCE[2]}")}
  script_name=${script_name:-$(basename "${BASH_SOURCE[1]}")}
  local func_name=${3:-${FUNCNAME[1]}}
  local line_no=${4:-${BASH_LINENO[0]}}
  __framework_logger "info" "$msg" "$script_name" "$func_name" "$line_no"
}

#######################################
# 打印 warn 级别日志
# Globals:
#   BASH_LINENO
#   BASH_SOURCE
#   FUNCNAME
# Arguments:
#   1 - msg: 要记录的日志消息。
#   2 - script_name (可选): 记录日志的脚本名称。如果未提供，则自动从调用栈中推断。
#   3 - func_name (可选): 记录日志的函数名称。如果未提供，则自动从调用栈中推断。
#   4 - line_no (可选): 记录日志的行号。如果未提供，则自动从调用栈中推断。
function radp_log_warn() {
  local msg=$1
  local script_name
  script_name=${2:-$(basename "${BASH_SOURCE[2]}")}
  script_name=${script_name:-$(basename "${BASH_SOURCE[1]}")}
  local func_name=${3:-${FUNCNAME[1]}}
  local line_no=${4:-${BASH_LINENO[0]}}
  __framework_logger "warn" "$msg" "$script_name" "$func_name" "$line_no"
}

#######################################
# 打印 error 级别日志
# Globals:
#   BASH_LINENO
#   BASH_SOURCE
#   FUNCNAME
# Arguments:
#   1 - msg: 要记录的日志消息。
#   2 - script_name (可选): 记录日志的脚本名称。如果未提供，则自动从调用栈中推断。
#   3 - func_name (可选): 记录日志的函数名称。如果未提供，则自动从调用栈中推断。
#   4 - line_no (可选): 记录日志的行号。如果未提供，则自动从调用栈中推断。
function radp_log_error() {
  local msg=$1
  local script_name
  script_name=${2:-$(basename "${BASH_SOURCE[2]}")}
  script_name=${script_name:-$(basename "${BASH_SOURCE[1]}")}
  local func_name=${3:-${FUNCNAME[1]}}
  local line_no=${4:-${BASH_LINENO[0]}}
  __framework_logger "error" "$msg" "$script_name" "$func_name" "$line_no"
}

#######################################
# 根据给定的日志级别返回相应的颜色代码。
# 此函数利用 g_log_level_color_config 数组，将日志级别映射到 g_colors 数组中的颜色代码，
# 支持 DEBUG, INFO, WARN, ERROR 日志级别及默认颜色。
#
# Globals:
#   g_log_level_color_config - 数组，包含不同日志级别对应的颜色在 g_colors 数组中的索引。
#   g_colors - 数组，定义了日志颜色代码。
#
# Arguments:
#   1 - log_level: 日志级别（DEBUG, INFO, WARN, ERROR 或默认）。
#
# Returns:
#   输出对应日志级别的颜色代码。
#
# Note:
#   - 如果给定的日志级别不是预定义的（DEBUG, INFO, WARN, ERROR），则使用默认颜色。
#   - 此函数设计用于改善日志输出的可读性，通过为不同级别的日志应用不同的颜色。
#######################################
function radp_log_get_log_level_color() {
  local -u log_level=${1:?}
  local log_color_idx

  case "${log_level}" in
    DEBUG)
      log_color_idx=${g_log_level_color_config[0]}
      ;;
    INFO)
      log_color_idx=${g_log_level_color_config[1]}
      ;;
    WARN)
      log_color_idx=${g_log_level_color_config[2]}
      ;;
    ERROR)
      log_color_idx=${g_log_level_color_config[3]}
      ;;
    *)
      log_color_idx=${g_log_level_color_config[4]}
      ;;
  esac

  echo "${g_colors[$log_color_idx]}"
}

#----------------------------------------------------------------------------------------------------------------------#

#######################################
# 通用日志记录函数。
# 根据给定的日志级别、消息和其他上下文信息，构造并输出格式化的日志消息。
# 支持日志级别过滤，只有高于或等于配置日志级别的消息才会被记录。
# 日志消息将同时输出到控制台和指定的日志文件，且不影响脚本的返回值。
#
# Globals:
#   g_debug - 控制是否以调试模式运行，调试模式下所有日志级别的消息都会被输出。
#   g_log_level_id - 关联数组，存储日志级别与其对应ID的映射，用于控制日志输出。
#   g_log_level - 配置的全局日志级别，只有大于等于此级别的日志才会被输出。
#   FD 3 - 日志文件的文件描述符。
#   FD 4 - 控制台的文件描述符。
#
# Arguments:
#   1 - log_level: 日志级别（DEBUG, INFO, WARN, ERROR）。
#   2 - log_msg: 要记录的日志消息。
#   3 - script_name: 脚本名称，模拟线程名。
#   4 - func_name: 调用日志的函数名称。
#   5 - line_no: 日志记录点的行号。
#
# Returns:
#   None
#
# Note:
#   - 日志消息会根据其级别着色输出到控制台，以提高可读性。
#   - 此函数不会影响脚本的返回值，即使日志写入操作失败。
#######################################
function __framework_logger() {
  local -u log_level=${1:?}
  local log_msg=${2:-}
  # position
  local script_name=${3:?} # 使用主脚本名模拟线程名
  local func_name=${4:?}
  local line_no=${5:?}

  local formatted_msg_console formatted_msg_file log_color
  local timestamp
  local thread_name # 使用主脚本名模拟线程名
  local pid=$$      ## 当前脚本的进程 ID

  timestamp=$(date +'%Y-%m-%d %H:%M:%S.%3N')
  thread_name=$(basename "$0")
  local no_color
  no_color=$(radp_log_get_log_level_color "default")

  # 判断日志级别来决定是否需要输出日志
  # Only proceed if the log level is greater than or equal to the configured log level
  if [[ ${g_debug} == true || ${g_log_level_id[${log_level}]} -ge ${g_log_level_id[${g_log_level^^}]} ]]; then
    # Map log levels to colors
    log_color=$(radp_log_get_log_level_color "$log_level")

    # Construct the formatted message
    local formatted_code_position formatted_log_level formatted_pid
    formatted_log_level=$(printf "%-5s" "${log_level}")
    formatted_pid=$(printf "%-5s" "${pid}")
    formatted_code_position=$(printf "%-50s" "${line_no}:${script_name}#${func_name}")
    formatted_msg_console="${log_color}${timestamp} | ${formatted_log_level} ${formatted_pid} | ${thread_name} | ${formatted_code_position}${no_color} | ${log_msg}"
    formatted_msg_file="${timestamp} | ${formatted_log_level} ${formatted_pid} | ${thread_name} | ${formatted_code_position} | ${log_msg}"

    # Log to file and console without affecting the script's return value
    {
      echo -e "${formatted_msg_file}" >&3
      echo -e "${formatted_msg_console}" >&4
    } &>/dev/null # Suppress command output to preserve return values in functions
  fi
}

#########################################################################################################################

#######################################
# 设置框架日志系统的基本配置。
# 此函数负责确保日志目录的存在，将特定的文件描述符重定向到日志文件和标准输出，
# 以支持框架的日志记录功能。
#
# Globals:
#   g_log_file - 全局变量，指定日志文件的路径。
#
# Arguments:
#   None
#
# Returns:
#   None
#
# Note:
#   - 文件描述符 3 被重定向到日志文件，用于日志记录。
#   - 文件描述符 4 根据脚本运行环境的不同，可能重定向到 /dev/tty、stdout 或 /dev/null，
#     用于控制台输出。这样做是为了保证即使在脚本重定向输出时，日志信息仍可被正确输出。
#   - 函数内部对重定向操作进行了错误检查，任何重定向失败都会导致脚本退出，
#     以避免日志记录或控制台输出的失效。
#######################################
function __framework_setup_logger() {
  # 确保日志目录存在
  local log_dir log_file
  log_file=${g_log_file:?}
  log_dir=$(dirname "${log_file}")
  if [[ ! -d "${log_dir}" ]]; then
    if ! mkdir -p "${log_dir}"; then
      $g_sudo mkdir -p "$log_dir" 2>/dev/null || {
        echo "Error: Failed to create log directory '${log_dir}'."
        exit 1
      }
      $g_sudo chown -Rv "$g_guest_user":"$g_guest_user" "$log_dir"
    fi
  fi

  if [[ -f "$log_file" && ! -w "${log_file}" ]]; then
    echo "Give write permission to $log_file"
    $g_sudo chmod u+w,g+w "$log_file"
  fi

  # 为了避免日志输出影响函数返回值
  # 将文件描述符 3 重定向到日志文件
  # 如果重定向失败，则报错并退出
  exec 3>>"${log_file}" || {
    echo "Error: Failed to open log file '${log_file}' for writing."
    exit 1
  }
  [[ "$g_debug" == 'true' ]] && echo "Redirect file descriptor 3 to $log_file"

  # 检测是否在交互式终端中运行
  # 如果是则重定向到 stdout
  # fall back to /dev/null if not available
  if [[ -t 1 ]]; then
    if [[ -e /dev/tty ]]; then
      if exec 4>/dev/tty; then
        if [[ "$g_debug" == 'true' ]]; then
          echo "Redirect file descriptor 4 to /dev/tty"
        fi
      else
        exec 4>&1
        echo "Fallback to redirecting file descriptor 4 to stdout because '/dev/tty' is not available or not writable."
      fi
    else
      exec 4>&1
      echo "Fallback to redirecting file descriptor 4 to stdout because /dev/tty is not available."
    fi
  else
    if exec 4>&1; then
      if [[ "$g_debug" == 'true' ]]; then
        echo "In non-interactive terminal, redirecting file descriptor 4 to stdout"
      fi
    else
      exec 4>/dev/null
      echo "Fallback to redirecting file descriptor 4 to /dev/null"
    fi
  fi
}

#######################################
# 日志文件轮换并压缩
# Globals:
#   g_log_file - 全局变量，指定日志文件的路径。
#   g_log_retention_days - 日志保留天数。
# Arguments:
#   None
# Returns:
#   None
#######################################
function __framework_rotate_logfile() {
  local max_size=${g_log_file_max_size:-10MB}           # 设置默认日志文件的最大大小
  local retention_days=${g_log_file_retention_days:-15} # 设置日志保留的天数
  local log_file="${g_log_file:?}"
  local log_dir basename current_date max_size_bytes current_time
  log_dir=$(dirname "$log_file")
  basename=$(basename "$log_file")
  current_date=$(date '+%Y%m%d')
  max_size_bytes=$(radp_utils_transfer_filesize "$max_size")
  current_time=$(date +%s)

  local file_size_bytes file_mod_date
  file_size_bytes=$(wc -c <"$log_file")
  file_mod_date=$(date -r "$log_file" '+%Y%m%d')
  local should_rotate=false

  # 根据单文件日志大小，以及日志时间是否当日，来决策是否需要归档
  if [[ $file_size_bytes -ge $max_size_bytes || "$file_mod_date" != "$current_date" ]]; then
    should_rotate=true
  fi

  # 检查日志文件大小并进行轮换
  if [[ "$should_rotate" == true ]]; then
    # 计算今天已经轮换的日志文件数量来生成序号
    local count
    count=$(find "$log_dir" -maxdepth 1 -type f -name "${basename}.${current_date}*" | wc -l)
    ((count++))
    local backup_file="${log_file}.${current_date}-${count}.gz"

    radp_log_info "Rotating and compressing to $backup_file"
    # 压缩并重命名当前日志文件
    gzip -c "$log_file" >"$backup_file"
    truncate -s 0 "$log_file" # 清空当前日志文件而不删除，保持文件描述符有效
  fi

  # 查找并删除超出保留期限的旧日志文件
  local old_files
  old_files=$(find "$log_dir" -maxdepth 1 -name "${basename}.*.gz" -type f -mtime +"$retention_days")
  local delete_count=0
  if [[ -n "$old_files" ]]; then
    delete_count=$(echo "$old_files" | wc -l)
    echo "$old_files" | xargs rm -v
  fi
  if ((delete_count > 0)); then
    radp_log_info "Deleted $delete_count old compressed log files older than $retention_days days."
  fi
}

#######################################
# 日志模块
# Arguments:
#  None
#######################################
function main() {
  __framework_setup_logger
  __framework_rotate_logfile
}

main

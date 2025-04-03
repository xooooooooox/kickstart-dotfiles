#!/usr/bin/env bash
# shellcheck source=./../../../../bootstrap.sh

#######################################
# 执行给定的命令并可选地捕获其输出。
# 此函数能够处理简单和复杂的命令，包括包含重定向和管道的命令。
# 对于包含输出重定向的命令，将直接使用 bash -c 执行而不捕获输出，
# 否则，使用 eval 执行命令并捕获其输出。
# 可以通过 --no-capture 选项禁用输出捕获，直接在当前 shell 中执行命令。
#
# Globals:
#   g_command_log_levels - 定义特定命令的日志级别。
#   g_debug - 控制是否打印调试输出的全局标志。
# Arguments:
#   --no-capture - 可选。指定此选项将不捕获命令输出。
#   command - 要执行的命令字符串。
# Outputs:
#   命令的标准输出（如果未禁用捕获）。
# Returns:
#   命令的退出状态码。
# Examples:
#   radp_utils_run "ls -l"
#   radp_utils_run "--no-capture" "sudo apt update"
#   radp_utils_run "bash -c 'some_command > output.txt'"
# Notes:
#   函数还支持日志脱敏功能 @see radp_utils_desensitize_str
#######################################
function radp_utils_run() {
  local capture_output=true
  if [[ "$1" == "--no-capture" ]]; then
    capture_output=false
    shift
  fi
  local command="$*" # 要执行的命令

  # log start
  local run_id start_msg script_name func_name line_no
  run_id=$(openssl rand -hex 4)                                     # 给当前执行计算一个 UUID，方便日志跟踪
  start_msg="${run_id}>>> $(radp_utils_desensitize_str "$command")" # radp_utils_desensitize_string 对执行的命令进行脱敏处理
  script_name="$(basename "${BASH_SOURCE[1]}")"
  func_name="${FUNCNAME[1]}"
  line_no="${BASH_LINENO[0]}"
  local cmd_key="${command%% *}" # 提取命令的第一个单词作为键来检查是否有特定的日志级别配置

  local cmd_log_level='info'
  if [[ -n "$cmd_key" ]]; then
    cmd_log_level=${g_command_log_levels[$cmd_key]:-'info'}
  fi
  __framework_logger "$cmd_log_level" "$start_msg" "$script_name" "$func_name" "$line_no"

  # 捕获输出与执行状态
  local output status
  if [[ "$capture_output" == true ]]; then
    output=$(bash -c "$command" 2>&1) || output=$(eval "$command" 2>&1)
    status=$?
  else
    # 不捕获输出的情况
    bash -c "$command"
    status=$?
  fi

  # log end
  local end_msg="${run_id}>>> $output"
  if [[ -n "$output" ]]; then
    if ((status != 0)); then
      radp_log_error "$end_msg" "$script_name" "$func_name" "$line_no"
    else
      radp_log_debug "$end_msg" "$script_name" "$func_name" "$line_no"
    fi
  fi

  # 如果命令有输出且处于捕获模式，则打印输出
  if [[ "$capture_output" == true && -n "$output" ]]; then
    echo "$output"
  fi

  # 返回状态码
  return "$status"
}

#######################################
# 重试执行指定的命令, 知道成功或达到最大尝试次数, 并在每次尝试间增加思考时间
#
# Globals:
#   None
#
# Arguments:
#   -m | --max [num]   可选 设置最大尝试次数。
#   -d | --delay [num] 可选 设置尝试之间的延迟秒数。
#   --                 必须 后续所有参数视为要执行的命令。
#
# Returns:
#   最后一次尝试的退出状态码。如果命令最终执行成功，则返回 0。
#
# Examples:
#   1) 使用默认的最大尝试次数和延迟时间
#     radp_utils_retry -- cp source.txt destination.txt
#   2) 指定最大尝试次数为 3，延迟时间为 10 秒
#     radp_utils_retry -m 3 -d 10 -- cp source.txt destination.txt
#   3) 使用长选项 --max 和 --delay
#     radp_utils_retry --max 3 --delay 10 -- cp source.txt destination.txt
#######################################
function radp_utils_retry() {
  local max_attempts=5
  local delay_seconds=15

  local command_to_run

  # 参数解析
  while :; do
    case $1 in
      -m | --max)
        max_attempts="$2"
        shift 2
        ;;
      -d | --delay)
        delay_seconds="$2"
        shift 2
        ;;
      --)
        shift
        command_to_run="$*"
        break
        ;;
      *)
        # No more options left.
        command_to_run="$*"
        break
        ;;
    esac
  done

  if [[ -z "$command_to_run" ]]; then
    radp_log_error "No command specified to retry."
    return 1
  fi

  local attempts=0
  local exit_code=0

  while ((attempts < max_attempts)); do
    eval "$command_to_run"
    exit_code=$?

    if ((exit_code == 0)); then
      return 0
    else
      ((attempts++))
      radp_log_warn "Command [$command_to_run] failed with exit code $exit_code. Attempt $attempts/$max_attempts"

      if ((attempts < max_attempts)); then
        sleep "$delay_seconds"
      else
        radp_log_error "The command [$command_to_run] has failed after $max_attempts attempts."
        return 1
      fi
    fi
  done
}

#######################################
# 对给定的字符串进行脱敏处理，以保护潜在的敏感信息不被暴露。
# 该函数主要针对一些常见的命令行参数进行脱敏处理，
# 如用户名、密码、令牌等，通过将这些参数后的值替换为星号来隐藏敏感信息。
#
# Globals:
#   None
# Arguments:
#   str - 需要进行脱敏处理的字符串。
# Returns:
#   输出脱敏后的字符串。
# Examples:
#   radp_utils_desensitize_string "curl -u user:password http://example.com"
#   # 输出: "curl -u user:****** http://example.com"
#######################################
function radp_utils_desensitize_str() {
  local str="$1"
  # 定义可能包含敏感信息的参数列表
  local sensitive_params=("-u" "--user" "--password" "--token")
  local param pattern

  for param in "${sensitive_params[@]}"; do
    if [[ "$str" == *"$param "* ]]; then
      # 生成用于匹配参数及其值的正则表达式模式
      pattern="$param [^ ]+"
      # 将匹配到的参数值替换为脱敏后的值
      str=$(echo "$str" | sed -E "s|$pattern|$param ******|g")
    fi
  done
  echo "$str"
}

#######################################
# 生成强密码
# Globals:
#   RANDOM
# Arguments:
#  $1 - length: 可选。密码长度
#  $2 - special_chars: 可选。特殊字符
# Returns:
#   1 - 如果传入的参数不符合要求，如密码长度
# Examples:
#   radp_utils_generate_strong_random_password
#   radp_utils_generate_strong_random_password 20
#   radp_utils_generate_strong_random_password 20 @#!S_+
#######################################
function radp_utils_get_strong_random_password() {
  # 定义密码长度和字符集
  local length=${1:-12}
  local special_chars=${2:-}

  local minor_length=12
  local digits='0123456789'
  local upper_case='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  local lower_case='abcdefghijklmnopqrstuvwxyz'
  special_chars=${special_chars:-'!@#$%^&*()_+{}|:<>?-=[];,.'}

  if ((length < minor_length)); then
    radp_log_error "Password length must greater than $minor_length"
    return 1
  fi

  # 确保密码包含至少一个大写、小写、数字和特殊字符
  local password
  password="$(echo $digits | fold -w1 | shuf | head -c1)"
  password+="$(echo $upper_case | fold -w1 | shuf | head -c1)"
  password+="$(echo $lower_case | fold -w1 | shuf | head -c1)"
  password+="$(echo "$special_chars" | fold -w1 | shuf | head -c1)"

  # 添加随机字符直到达到指定长度
  local remaining=$((length - 4))
  local i
  for ((i = 0; i < remaining; i++)); do
    local set="${digits}${upper_case}${lower_case}${special_chars}"
    password+="${set:$((RANDOM % ${#set})):1}"
  done

  # 打乱密码以避免可预测的模式
  echo "$password" | fold -w1 | shuf | tr -d '\n'
}

#######################################
# 重新执行脚本命令行
# Arguments:
#  $@: 待执行的命令行
#######################################
function radp_utils_rerun_command_line() {
  local command_line=("$@")
  radp_log_warn "!!! 重新运行刚刚的命令：[${command_line[*]}]"
  if test -f /usr/local/bin/bash; then
    exec /usr/local/bin/bash "${command_line[@]}"
  else
    exec /usr/bin/env bash "${command_line[@]}"
  fi
}

#######################################
# 在远程主机执行命令或函数
# Arguments:
#   1 - target_host 必须, format: vagrant@k8s-master
#   2 - command_or_method 必须, 待执行的命令或函数
#   3 - additional_params 可选, 额外参数
# Examples:
#   1) 远程执行一个命令
#   radp_utils_remote_run "vagrant@k8s-master" "ls -l"
#   2) 远程执行一个函数
#   radp_utils_remote_run "vagrant@k8s-master" radp_k8s_api_get_token
#######################################
function radp_utils_remote_run() {
  local target_host=${1:?}
  local command_or_method=${2:?}
  local additional_paras=${3:-}

  local temp_script
  temp_script=$(mktemp)

  if [[ -n "$(type -t "$command_or_method")" && "$(type -t "$command_or_method")" == "function" ]]; then
    # 传递的是一个方法名
    local method_definition
    method_definition=$(declare -f "$command_or_method")
    echo "$method_definition" >"$temp_script"                    # 将方法定义写入文件
    echo "$command_or_method $additional_paras" >>"$temp_script" # 执行这个方法写在尾部
    # TODO 期望通过 radp_utils_run 去包装执行下面的命令
    # 在远程主机执行当前主机(源)本地文件
    ssh -o StrictHostKeyChecking=no "$target_host" 'bash -s' <"$temp_script" 2>/dev/null
  else
    # 传递的是一个待执行的命令
    ssh -o StrictHostKeyChecking=no "$target_host" "$command_or_method" 2>/dev/null
  fi

  # 删除临时脚本
  rm -f "$temp_script"
}

function radp_utils_check_version_satisfied() {
    local current_version=${1:?}
    local required_version=${2:?}
    if [[ "$(printf '%s\n' "$required_version" "$current_version" | sort -V | head -n1)" != "$required_version" ]]; then
      radp_log_warn "detected current version $current_version <= $required_version"
      return 1 # 当前版本小于 required_version
    else
      return 0 # 当前版本大于等于 required_version
    fi
}
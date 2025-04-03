#!/usr/bin/env bash

#######################################
# 功能描述:
#   `radp_nr_prompt_inputs` 函数用于从用户那里以命令行的方式获取输入。
#   它支持定制提示消息、输入超时、默认值以及日志级别的颜色显示。
#   特别的，它还提供了一个密码模式，用于在读取密码时不回显输入。
#
# Arguments:
#   $1 - __nr_prompt_inputs__: 必须。引用传递。函数将用户输入的结果存储到提供的变量名中。
#   --level <level>: 可选。指定日志级别的颜色显示（如 info, error）。默认为 "info"。
#   --msg <message>: 可选。自定义的提示信息。默认为 "Continue?(y/N)"。
#   --timeout <seconds>: 可选。设置用户输入的超时时间。默认为空。
#   --default <value>: 可选。指定在超时或输入错误时使用的默认值。默认为 "no"。
#   --password: 可选。启用密码模式，输入时不回显。
#
# Examples:
#   local user_input
#   radp_nr_prompt_inputs user_input --msg "Enter your choice: " --timeout 5 --default "y" --level "info"
#   echo "You chose: $user_input"
#
# Notes:
#   该函数使用局部变量和读取命令的超时选项，可能不适用于所有的操作环境。
#   当使用 `--password` 选项时，输入将不会回显，适用于密码或敏感信息的输入。
#######################################
function radp_nr_io_prompt_inputs() {
  local -n __nr_prompt_inputs__=${1:?}
  shift
  local msg="请输入: "
  local timeout=300
  local default=""
  local level="info"
  local password_flag=false

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --level)
        level="${2:?}"
        shift 2
        ;;
      --msg)
        msg="${2:?}"
        shift 2
        ;;
      --timeout)
        timeout="${2:?}"
        shift 2
        ;;
      --default)
        default="${2:?}"
        shift 2
        ;;
      --password)
        password_flag=true
        shift
        ;;
      *)
        radp_log_error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  local color reset_color
  reset_color=$(radp_log_get_log_level_color "default")
  color=$(radp_log_get_log_level_color "$level")

  local input
  # 检查是否在非交互式环境中
  if [ ! -t 0 ]; then
    radp_log_warn "Non-interactive environment detected. Defaulting to automatically generated or provided default value."
    if [[ $password_flag == true ]]; then
      input=$(radp_utils_get_strong_random_password) # 如果是密码，生成强密码
    else
      input=$default
    fi
  else
    if [[ $password_flag == "true" ]]; then
      default=$(radp_utils_get_strong_random_password)
      read -r -t "$timeout" -sp "$(printf "${color}%s${reset_color}" "$msg")" input || {
        echo -ne "\n${color}=>Timeout. Defaulting to '$default'${reset_color}"
        # 超时或其他错误，使用默认值
        input=$default
      }
      echo # 新行(read 命令在密码模式下，不会自动换行)
    else
      read -r -t "$timeout" -p "$(printf "${color}%s${reset_color}" "$msg, default is $default: ")" input || {
        echo -e "\n${color}=>Timeout. Defaulting to '$default'${reset_color}"
        # 超时或其他错误，使用默认值
        input=$default
      }
    fi
  fi

  __nr_prompt_inputs__=${input}
}

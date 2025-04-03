#!/usr/bin/env bash
# shellcheck source=../../../../bootstrap.sh

#######################################
# 向指定的文件中追加一行内容，可选地检查内容是否已经存在，以避免重复追加。
#
# Globals:
#   None
# Arguments:
#   --no-check    可选。如果指定，函数将不会检查内容是否以存在于文件中
#   filepath      必需。被追加内容的目标文件
#   content_line  必需。要追加的内容行
#   grep_pattern  可选。用于检查内容是否已存在的模式。如果未指定，则使用 content_line 作为模式。
# Outputs:
#   Log warnings, errors and information
# Returns:
#   1) 如果成功追加内容或内容已存在，返回 0；
#   2) 如果有错误发生，返回 1。(如目标文件不存在，参数缺失)
# Examples:
#   1) 不检查内容重复
#   _utils_append_line_to_file /path/to/file 'export PYENV_ROOT="$HOME"/.pyenv'
#   2) 检查内容重复
#   _utils_append_line_to_file --no-check /path/to/file 'export PYENV_ROOT="$HOME"/.pyenv'
#######################################
function radp_io_append_single_line_to_file() {
  local check_content_exists=true
  local filepath=""
  local content_line=""
  local grep_pattern=""

  # 解析传入的参数
  while (("$#")); do
    case "$1" in
      --no-check)
        check_content_exists=false
        shift
        ;;
      *)
        # 分配参数到特定的变量
        if [[ -z "$filepath" ]]; then
          filepath="$1"
        elif [[ -z "$content_line" ]]; then
          content_line="$@"
          break
        fi
        shift
        ;;
    esac
  done

  # Use content_line as grep_pattern if not specified
  grep_pattern=${grep_pattern:-"$content_line"}

  # 参数检查
  if [[ -z "$filepath" || -z "$content_line" ]]; then
    radp_log_error "Usage: radp_utils_append_content_to_file [--no-check] filepath content_line [grep_pattern]"
    return 1
  fi
  # 检查目标文件是否存在
  if ! $g_sudo test -f "$filepath";then
    radp_log_error "Can't append because '$filepath' does not exist"
    return 1
  fi

  if [[ "$check_content_exists" == true ]]; then
    if grep -qxF -- "$grep_pattern" "$filepath" 2>/dev/null; then
      radp_log_debug "The specified line '$content_line' already exists in $filepath"
      return 0
    elif $g_sudo grep -qxF -- "$grep_pattern" "$filepath" 2>/dev/null; then
      radp_log_debug "The specified line '$content_line' already exists in $filepath"
      return 0
    fi
  fi

  radp_log_debug "Appending $content_line to $filepath"
  # 尝试使用普通权限追加内容
  if sh -c 'echo "$content_line" >>"$filepath"' 2>/dev/null; then
    return 0
  else
    # 如果失败则使用 sudo 权限尝试追加内容
    radp_log_debug "Normal permission append failed, attempting with sudo"
    if echo "$content_line" | sudo tee -a "$filepath" >/dev/null; then
      return 0
    else
      radp_log_error "Failed to append '$content_line' to $filepath due to permission issues"
      return 1
    fi
  fi
}

#######################################
# 使用 figlet 工具生成一个文本横幅，并将其保存到指定的文件中。
# 此函数依赖于 figlet 工具，确保它已安装在系统中。
#
# Globals:
#   None
# Arguments:
#   1 - banner: 要生成横幅的文本内容。
#   2 - target: 横幅文本输出的目标文件路径。
#   3 - fig_font (可选): figlet 使用的字体，默认为 'slant'。可选字体取决于系统中安装的 figlet 字体。
# Returns:
#   None - 无返回值。但会将生成的横幅文本写入指定的目标文件。
# Examples:
#   radp_utils_generate_banner_file "Hello World" "/tmp/banner.txt"
#   radp_utils_generate_banner_file "Welcome" "/tmp/welcome_banner.txt" "shadow"
# Notes:
#   - 请确保目标文件路径是可写的，否则此函数将失败。
#   - 如果指定的字体未安装，figlet 将回退到默认字体，并可能输出错误信息。
#######################################
function radp_io_output_banner_file() {
  local banner=${1:?}
  local target=${2:?}
  local fig_font=${3:-'slant'}

  # 检查 figlet 命令是否存在
  if ! command -v figlet &>/dev/null; then
    radp_log_error "Figlet is not installed"
    return 1
  fi

  # 检查目标文件的目录是否可写
  local target_dir
  target_dir=$(dirname "$target")
  if [ ! -w "$target_dir" ]; then
    radp_log_error "Target directory '$target_dir' is not writable."
    return 1
  fi

  if ! figlet -f "$fig_font" "$banner" >"$target"; then
    radp_log_error "Failed to generate banner with figlet."
    return 1
  fi
}

#######################################
# 提示用户是否继续，并具有倒计时功能。支持通过命名参数自定义提示信息、超时时间及默认答案。
#
# Arguments:
#   --msg <message> - 可选.显示给用户的消息。不指定时使用默认值 Continue?(y/N)
#   --timeout <seconds> - 可选.用户响应的等待时间（秒）。不指定时使用默认值 10
#   --default <answer> - 可选.默认答案，在超时后使用。不指定时使用默认值 no
#   --level <level> - 可选. 提示信息级别，根据级别显示未不同颜色。不指定时使用默认值 info
#                         @see radp_log_get_log_level_color
# Returns:
#   0 - 用户明确回答"yes"或"y"
#   1 - 用户回答"no"、"n"或未在指定时间内响应
# Examples:
#   radp_utils_continue --msg "Are you sure you want to proceed?(y/N)" --timeout 5 --default no --level warn
#   radp_utils_continue
#######################################
function radp_io_prompt_continue() {
  local msg="Continue?(y/N)"
  local timeout=10
  local default="N"
  local level="info"

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
      *)
        radp_log_error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  local input
  # 检查当前环境是否支持交互式输入
  if [ ! -t 0 ]; then # 如果标准输入不是终端（非交互式）
    radp_log_warn "Non-interactive environment detected. Defaulting to '$default'."
    input=$default
  else
    local color reset_color
    reset_color=$(radp_log_get_log_level_color "default")
    color=$(radp_log_get_log_level_color "$level")
    read -r -t "$timeout" -p "$(printf "${color}%s${reset_color}" "${msg}, default is $default: ") " input || {
      echo -e "\n${color}=>Timeout. Defaulting to '$default'${reset_color}"
      # 超时或其他错误，使用默认值
      input=$default
    }
  fi

  case $input in
    [yY][eE][sS] | [yY])
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

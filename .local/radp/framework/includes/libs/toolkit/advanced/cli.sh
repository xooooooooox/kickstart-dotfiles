#!/usr/bin/env bash
# shellcheck source=./../../../../bootstrap.sh

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#######################################
# 统一处理一些通用的命令行参数
# 每个支持命令行参数的 executor 中，都需要调用
# Globals:
#   g_getopt_long_opts - 通用短参数
#   g_getopt_short_opts - 通用长参数
# Arguments:
#   1 - __nr_common_parsed_args__: nameref，解析过的参数与参数值存储在命名引用对用的关联数组中
#   2 - __nr_remained_args__
#   3...n - 待解析的命令行参数列表
# Examples
#   local -n __nr_xx_executor_parsed_args__
#   local -a remaining_args
#   radp_cli_nr_getopt_common_args_process __nr_xx_executor_parsed_args__ remaining_args "$@"
# Notes:
#   1) 背景：
#   每个提供命令行参数解析功能的 executor_file，
#   都会先调用参数解析器 @see radp_cli_nr_getopt_parser
#   并在参数解析器中指定属于自己的参数解析方法，
#   在这个参数解析方法中，将每个选项的值存入到关联数组中，为后续处理做准备
#   2) 问题：
#   但随着 executor_file 的增多，势必会存在很多常用的 option，且处理逻辑一直
#   3) 作用：
#   这个方法的目的就是为了统一处理这些公共参数，减少重复代码
#######################################
function radp_nr_cli_parse_common_options() {
  # 解析后的参数
  local -n __nr_common_parsed_args__=$1
  # 经过本函数进行通用参数解析后，剩余未解析的参数数组
  local -n __nr_remained_args__=$2
  shift 2

  radp_lang_check_var_type __nr_common_parsed_args__ -A
  radp_lang_check_var_type __nr_remained_args__ -a

  local common_short_opts=${g_getopt_common_short_opts}
  local common_long_opts=${g_getopt_common_long_opts}

  radp_log_debug "Origin args: $*"
  radp_log_debug "Try to parse common opts: '${common_short_opts[*]}', '${common_long_opts[*]}',common opts desc: $(radp_nr_utils_print_assoc_arr g_getopt_common_desc)"
  while [[ -n "$1" ]]; do
    case "$1" in
      -f | --function)
        __nr_common_parsed_args__['function']="$2"
        shift 2
        ;;
      -v | --version)
        __nr_common_parsed_args__['version']="$2"
        shift 2
        ;;
      --)
        break
        ;;
      *)
        __nr_remained_args__+=("$1") # Save remaining args
        shift
        ;;
    esac
  done

  # Append any remaining args after '--'
  while [[ -n "$1" ]]; do
    __nr_remained_args__+=("$1")
    shift
  done

  radp_log_debug "Parsed common opts: $(radp_nr_utils_print_assoc_arr __nr_common_parsed_args__)"
  radp_log_debug "Remaining dis-processed args: [${__nr_remained_args__[*]}]"
}

#######################################
# 使用 getopt 和命名引用解析命令行参数。
# 设计用于处理包括短选项、长选项和自动生成帮助信息在内的复杂 CLI 参数解析场景。
#
# Globals:
#   g_cli_remaining_args: 如果 -p 参数没有指定，那么该函数执行完后将会给这个全局变量赋值
#
# Arguments:
#   -r | --nr-parsed - 解析后的参数将被存储到这个命名引用变量中。
#   -n | --name - （可选）程序的名称，用于帮助信息的标题。如果未指定，调用 __cli_get_prog_name 函数计算得到
#   -d | --nr-desc - 选项描述的关联数组的命名引用，包含选项的描述信息。
#   -o | --options - getopt 的短选项字符串。
#   -l | --longoptions - getopt 的长选项字符串。
#   -p | --process-func - （可选）用于进一步处理解析后参数的函数名称。
#   -m | --manual-file - （可选）包含额外帮助信息或示例的文件路径。
#   -- - 标记命令行参数的结束，之后的参数将直接传递给脚本。
#
# Returns:
#   None
#   如果参数解析失败或用户请求帮助信息（-h/--help），则打印帮助信息并退出脚本。
#
# Examples:
#   1) 最完整的写法
#   radp_cli_nr_getopt_parser -r parsed_args -o "$short_opts" -l "$long_opts" -d opts_desc -p process_cli_args -m "/path/to/help_file" -- "$@"
#   2) 如果命令行参数为公共参数的子集，则无需额外在定义 -p process_func
#   radp_cli_nr_getopt_parser -r parsed_args -o "$short_opts" -l "$long_opts" -d opts_desc -m "${g_cli_cmd_man_mapper['framework']}" -- "$@"
#   3) 当然，如果你没有帮助文档的话，也可以不指定
#   radp_cli_nr_getopt_parser -r parsed_args -o "$short_opts" -l "$long_opts" -d opts_desc -- "$@"
# Notes:
#   - 需要在 bash 环境下运行，并确保 getopt 命令可用。
#   - 确保所有传入的变量（如 parsed_args 和 option_desc）已经事先声明并初始化。
#   - 该函数通过 -r 和 -d 选项引用的关联数组，需要 bash 版本支持 -n 名称引用功能。
#######################################
function radp_nr_cli_parser() {
  local -n __nr_parsed_args__ __nr_option_descriptions__
  local process_func short_opts long_opts name manual_file

  name=$(__framework_cli_get_prog_name)
  while [[ -n "$1" ]]; do
    case "$1" in
      -r | --nr-parsed)
        __nr_parsed_args__=${2:?}
        shift 2
        ;;
      -n | --name)
        name=${2:?}
        shift 2
        ;;
      -d | --nr-desc)
        __nr_option_descriptions__=${2:?}
        radp_lang_check_var_type __nr_option_descriptions__ -A || exit 1
        shift 2
        ;;
      -o | --options)
        short_opts=${2:?}
        shift 2
        ;;
      -l | --longoptions)
        long_opts=${2:?}
        shift 2
        ;;
      -p | --process-func)
        process_func=${2:?}
        shift 2
        ;;
      -m | --manual-file)
        manual_file=${2:-}
        shift 2
        ;;
      --)
        shift
        break
        ;;
      *)
        radp_log_error "Invalid args '$1'."
        exit 1
        ;;
    esac
  done

  # 追加公共短/长选项以及面熟
  local opt
  # 检测并追加短选项
  for ((i = 0; i < ${#g_getopt_common_short_opts}; i++)); do
    opt="${g_getopt_common_short_opts:$i:1}"
    # 检查选项后是否有冒号（即是否带参数）
    if [[ "${g_getopt_common_short_opts:((i + 1)):1}" == ":" ]]; then
      opt="$opt:"
      ((i++))
    fi
    if [[ "$short_opts" != *"$opt"* ]]; then
      short_opts+="$opt"
    fi
  done
  # 检测并追加长选项
  local long_opt_array
  IFS="," read -ra long_opt_array <<<"$g_getopt_common_long_opts"
  for opt in "${long_opt_array[@]}"; do
    if [[ ! "$long_opts" =~ $opt ]]; then
      long_opts+=",$opt"
    fi
  done
  # 检测并追加选项描述
  local key
  for key in "${!g_getopt_common_desc[@]}"; do
    if [[ ! "${opts_desc[$key]+_}" ]]; then
      __nr_option_descriptions__[$key]="${g_getopt_common_desc[$key]}"
    fi
  done

  set +e # 暂时关闭 'set -e'
  local getopt_results
  getopt_results=$(getopt -o "$short_opts" -l "$long_opts" -- "$@") #TODO 这里如果使用 radp_utils_run 进行执行的话，会报错 => 这说明 radp_utils_run 包装的还是不够通用
  local status=$?
  set -e # 重新开启 'set -e'

  # 如果参数解析存在非法参数，则打印帮助信息
  if [[ $status -ne 0 ]]; then
    radp_nr_cli_print_detail_help -n "$name" -o "$short_opts" -l "$long_opts" -d __nr_option_descriptions__ -m "$manual_file"
    exit 1
  fi

  # 解析 getopt 的输出 getopt_results，将规范化后的命令行参数分配至位置参数 $@
  # 准备传递给 parse_func，
  eval set -- "$getopt_results"

  # 在传递给 parse_func 之前, 先处理通用参数, 如, -h|--help
  while true; do
    case "$1" in
      -h | --help)
        radp_nr_cli_print_detail_help -n "$name" -o "$short_opts" -l "$long_opts" -d __nr_option_descriptions__ -m "$manual_file"
        exit 0
        ;;
      --)
        shift
        break
        ;;
      *)
        # 如果需要，这里可以处理额外的选项参数
        # 但如果没有公共的处理逻辑的话，
        # 这部分会留给 $process_func 函数处理
        break
        ;;
    esac
  done

  if [[ $# -le 0 ]]; then
    radp_nr_cli_print_detail_help -n "$name" -o "$short_opts" -l "$long_opts" -d __nr_option_descriptions__ -m "$manual_file"
    exit 0
  fi

  # 以下是这个解析器的核心逻辑
  if [[ -z "$process_func" ]]; then
    radp_log_warn "Falling back to default cli args process func, because NO user cli args func specified"
    g_cli_remaining_args=()
    radp_nr_cli_parse_common_options __nr_parsed_args__ g_cli_remaining_args "$@"
  else
    if [[ "$(type -t "$process_func")" == "function" ]]; then
      # 调用传入的函数来处理解析后的参数
      "$process_func" __nr_parsed_args__ "$@"
      radp_log_debug "Finally parsed cli args: $(radp_nr_utils_print_assoc_arr __nr_parsed_args__)"
    else
      radp_log_error "'$process_func' isn't a function, please check your code."
      exit 1
    fi
  fi
}

#######################################
# 打印给定程序的简要命令行帮助信息。
# 这个函数是 `radp_nr_print_brief_cli_help` 的一个包装器，
#
# Globals:
#   g_cli_main_script_name
#   g_cli_subcmd_executor_mapper
#
# Arguments:
#   -n <arg> - name: 必须, 帮助文档 progname，程序的名称
#   -n [arg] - subcommands: 可选,允许的子命令数组
#
# Returns:
#   None
#
# Examples:
#   1) radp_print_brief_cli_help -n "my_script"
#   2) local -a cmds=(cmd1 cmd2)
#      radp_print_brief_cli_help -n "my_script" -s "${available_subcmd[@]}"
#######################################
function radp_cli_print_brief_help() {
  local name
  local -a subcommands

  while [[ -n "$1" ]]; do
    case "$1" in
      -n | --name)
        name=${2:?}
        shift 2
        ;;
      -s | --subcommands)
        shift          # 移除 -s 或 --subcommands
        subcommands=() # 初始化数组
        while [[ -n "$1" && "$1" != -* ]]; do
          subcommands+=("$1") # 将参数添加到数组
          shift               # 移动到下一个参数
        done
        ;;
      *)
        radp_log_error "Invalid arg '$1'"
        exit 1
        ;;
    esac
  done

  local -A desc=(["help"]="Display this help and exit")
  if [[ ${#subcommands} -eq 0 ]]; then
    radp_nr_cli_print_detail_help -n "$name" -o "h" -l "help" -d desc
  else
    local formatted_subcommands
    formatted_subcommands="[${subcommands[*]// / | }]"
    radp_nr_cli_print_detail_help -n "$name $formatted_subcommands" -o "h" -l "help" -d desc
  fi
}

#######################################
# 详细打印程序的命令行帮助信息。
# 此函数根据提供的选项和描述构建并打印出格式化的帮助信息，包括用法、选项和示例。
# 支持短选项、长选项以及选项描述的自定义。
# 可选地，如果提供了示例文件路径，则从文件中读取示例信息。
#
# Globals:
#   None
#
# Arguments:
#   -n, --progname        必须. 程序的名称。
#   [-s, --subcmd]        可选. 子命令
#   -o, --options         必须. 程序支持的短选项。
#   -l, --longoptions     必须. 程序支持的长选项，格式为 "option:" 或 "option" 表示有参或无参。
#   -d, --desc            必须. 关联数组变量的名称，包含长选项的描述信息。
#   [-m, --manual-file]   可选. 包含示例信息的文件路径。
#
# Returns:
#   None
#
# Examples:
#   declare -A desc=(["help"]="Display this help and exit" ["version"]="Print version information")
#   radp_nr_print_detail_cli_help -n "my_script" -s "" -o "hv" -l "help,version:" -d desc -m "/path/to/manual_file"
#
# Notes:
#   - 需要 bash 版本支持 -n 名称引用功能。
#   - 确保 desc 关联数组已经正确初始化并传入。
#######################################
function radp_nr_cli_print_detail_help() {
  local subcmd short_opts long_opts prog_name manual_file
  local -n __nr_opts_desc__
  while [[ -n "$1" ]]; do
    case "$1" in
      -n | --progname)
        prog_name=${2:?}
        shift 2
        ;;
      -o | --options)
        short_opts=${2:?}
        shift 2
        ;;
      -l | --longoptions)
        long_opts=${2:?}
        shift 2
        ;;
      -d | --nr-desc)
        __nr_opts_desc__=${2:?}
        shift 2
        ;;
      -m | --manual-file)
        manual_file=$2
        shift 2
        ;;
      --)
        shift
        break
        ;;
      *)
        radp_log_error "Invalid arg '$1'."
        exit 1
        ;;
    esac
  done

  # step1: 构建 usage_info
  local usage_info option_info example_info
  usage_info="Usage: $prog_name [OPTIONS]\n"
  option_info="Options:\n"
  example_info="Examples:\n"

  local long_opts_arr
  IFS=',' read -ra long_opts_arr <<<"$long_opts"
  # 将短选项和长选项关联
  local opt_idx
  local long_opt
  for long_opt in "${long_opts_arr[@]}"; do
    local long_name="${long_opt%:*}"                 # 长选项名
    local require_arg="${long_opt#*:}"               # 是否为有参长选项
    local short_name="${short_opts:opt_idx:1}"       # 对应的短选项名
    local opt_desc="${__nr_opts_desc__[$long_name]}" # 选项对应的描述信息

    # 判断是否为有参短选项. 如果是，则跳过 short_opts 中的参数标识符(:)
    if [[ "${short_opts:opt_idx+1:1}" == ":" ]]; then
      opt_idx=$((opt_idx + 2))
    else
      opt_idx=$((opt_idx + 1))
    fi

    # TODO, 如果存在短选项参数与长选项参数个数不一致的情况时，帮助文档的参数帮助信息存在乱序的问题（映射）
    # step2: 构建 options_info
    local opt_string="  -$short_name, --$long_name"
    if [[ "$require_arg" == "$long_name" ]]; then
      opt_desc="(no argument) $opt_desc"
    else
      if [[ "$long_name" == "function" ]]; then
        local -a ava_functions
        mapfile -t ava_functions < <(radp_cli_get_subcmd_available_functions "${BASH_SOURCE[2]}")
        opt_string="$opt_string [${ava_functions[*]// / | }]"
      else
        opt_string="$opt_string <arg>"
      fi
    fi

    option_info+="$opt_string $opt_desc\n"
  done

  # step3: 构建 example_info
  if [[ -n "$manual_file" && -f "$manual_file" ]]; then
    example_info+=$(cat "$manual_file")
  else
    example_info+="No examples."
  fi

  # 打印帮助信息
  radp_log_info "\n$usage_info$option_info$example_info"
}

#######################################
# 通过脚本文件名获取对应的子命令名称。
# 该函数假定脚本文件遵循特定的命名约定，即文件名以 "_executor" 结尾。
# 它从符合此约定的脚本文件名中提取并返回子命令的名称。
# 如果文件名不包含 "_executor"，则函数返回空字符串，表示没有找到匹配的子命令名称。
#
# Arguments:
#   1 - script_file: 完整路径或相对路径的脚本文件名。
#
# Returns:
#   打印出从脚本文件名中提取的子命令名称。如果文件名不符合预期格式，则输出为空字符串。
#
# Examples:
#   假设有一个脚本文件名为 "install_executor.sh"，
#   调用 `radp_cli_get_subcmd_by_script_file "install_executor.sh"`
#   将输出 "install"。
#
#   如果脚本文件名为 "utility.sh"，不包含 "_executor"，
#   则调用 `radp_cli_get_subcmd_by_script_file "utility.sh"` 将输出空字符串。
#######################################
function radp_cli_get_subcmd_by_script_file() {
  local script_file=${1:?}
  local filename
  filename=$(basename "$script_file")

  local subcmd
  for subcmd in "${!g_cli_subcmd_executor_mapper[@]}"; do
    local valid_executor_filename
    valid_executor_filename=$(basename "${g_cli_subcmd_executor_mapper[$subcmd]}")
    if [[ "$filename" == "$valid_executor_filename" ]]; then
      echo "$subcmd"
      return 0
    fi
  done
  # 如果没有命中的则返回空字符串
  echo ""
}

function radp_cli_get_executor_options_processor_function_name() { #FIXME to validate subcmd
  # 如果没有告知 subcmd，则默认分析根据调用者去分析其对应的 subcmd
  # 你也可以在你的 executor_file 中计算出 subcmd 后传入，使用 ${BASH_SOURCE[0]}
  # 只需要在 executor_file 中这么计算即可 subcmd=$(radp_cli_get_subcmd_by_script_file "${BASH_SOURCE[0]}")
  local default_subcmd
  default_subcmd=$(radp_cli_get_subcmd_by_script_file "${BASH_SOURCE[1]}")
  local subcmd=${1:-$default_subcmd}
  if [[ -z $subcmd ]]; then
    radp_log_error "Invalid subcmd '${subcmd}'"
    exit 1
  fi

  echo "${g_cli_subcmd_executor_processor_function_name_regex//xx/${subcmd}}"
}

function radp_cli_getexecutor_manual_file() { #FIXME to validate subcmd
  local default_subcmd
  default_subcmd=$(radp_cli_get_subcmd_by_script_file "${BASH_SOURCE[1]}")
  local subcmd=${1:-$default_subcmd}

  if [[ -z $subcmd ]]; then
    radp_log_error "Invalid subcmd '${subcmd}'"
    exit 1
  fi

  echo "${g_cli_cmd_man_mapper[$subcmd]}"
}

#######################################
# 根据执行器文件名，获取可用的子命令函数名称列表。
# 该函数首先根据传入的执行器脚本文件名提取子命令名称，然后遍历当前脚本定义的所有函数，
# 筛选出符合“子命令_执行器_函数名”模式的函数名称，并返回这些函数的列表。
# 如果执行器文件名不符合“*_executor.sh”的命名约定，函数将输出错误信息并退出。
#
# Globals:
#   None
#
# Arguments:
#   1 - cur_executor_file: 执行器脚本文件的路径。
#
# Returns:
#   打印出匹配的函数名称列表。如果没有匹配的函数，输出为空。
#
# Examples:
#   假设当前执行器文件名为 "install_executor.sh"，
#   且定义了函数 "install_executor_check" 和 "install_executor_install"，
#   调用 `radp_cli_subcmd_get_available_funcs "install_executor.sh"`
#   将输出 "check install"。
#
# Notes:
#   该函数假设所有相关的函数遵循特定的命名约定，
#   即函数名以“子命令_执行器_函数名”的格式命名。
#######################################
function radp_cli_get_subcmd_available_functions() {
  local cur_executor_file=${1:?}
  local -a all_function_names
  mapfile -t all_function_names < <(declare -F | awk '{print $NF}')
  local subcmd
  subcmd=$(radp_cli_get_subcmd_by_script_file "$cur_executor_file")
  if [[ -z "$subcmd" ]]; then
    radp_log_error "Invalid executor filename '$cur_executor_file', it should follow the naming convention of '*_executor.sh'."
    exit 1
  fi
  local -a matched_function_name f
  for f in "${all_function_names[@]}"; do
    if [[ "$f" =~ ^${subcmd}* ]]; then
      f=${f#"${subcmd}"_executor_}
      matched_function_name+=("$f")
    fi
  done

  echo "${matched_function_name[@]}"
}

#######################################
# 打印提示信息
# 如果用户执行 subcmd -f xxx 输入的 xxx 为非法 function 时，
# 打印输出相关提示信息
# Arguments:
#   1 - subcmd_function_to_run: 命令行 -f 参数后的值
#   2 - executor_file: subcmd 对应的那个 executor_file
#######################################
function radp_cli_print_help_of_invalid_subcmd_function() {
  local subcmd_function_to_run=${1:?}
  local executor_file=${2:?}

  local -a subcmd_available_functions
  mapfile -t subcmd_available_functions < <(radp_cli_get_subcmd_available_functions "$executor_file")
  local err_msg
  err_msg="Miss '-f' option or invalid subcmd function $subcmd_function_to_run."
  err_msg+=" Available functions [${subcmd_available_functions[*]// / | }]."
  err_msg+=' Try '-h' for more information'
  radp_log_error "$err_msg"
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#######################################
# 判断命令行中是否直接运行 executor_file
# Arguments:
#   0
# Returns:
#   0 - 如果直接运行 executor_file, 则返回 0
#   1 - 如果不是直接运行 executor_file, 则返回 1
#######################################
function __framework_cli_check_if_straight_run_executor_file() {
  local subcmd
  subcmd=$(radp_cli_get_subcmd_by_script_file "$0")
  if [[ -n "$subcmd" ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# 根据子命令自动分发给映射的 executor_file 进行执行
# Globals:
#   g_cli_main_prog_name - 主程序的名称。
#   g_cli_subcmd_executor_mapper - 关联数组，映射子命令到其执行脚本。
#
# Arguments:
#   '*' - 包括子命令及其选项在内的任何传递给 CLI 的参数。
# Returns:
#   None
# Examples:
#   1) 运行 'start' 子命令:
#     radp_cli_run_subcmd start --option
#   2) 获取简要的 CLI 帮助:
#     radp_cli_run_subcmd --help
# Notes:
#   1) 根据当前命令行自动判断是否需要执行子命令分发
#      比如：如果是直接运行 executor_file 的话，则无需执行分发逻辑，会跳过这部分逻辑
#   2) 当然也可以手动关闭子命令解析功能
#      通过设定环境变量 G_ENABLE_SUBCMD_EXECUTOR_DISPATCH=false
#######################################
function __framework_cli_run_subcmd() {
  # 以下场景则跳过执行子命令执行器分发逻辑
  # 1) 直接自行 executor_file
  # 2) 手动关闭了 g_enable_subcmd_executor_dispatch=false
  if __framework_cli_check_if_straight_run_executor_file; then
    radp_log_debug "Straight run executor => $0 $*"
    # 如果是直接运行 executor_file 的话，则不再需要解析子命令，进行命令分发的逻辑
    return 0
  fi
  if [[ "$g_enable_subcmd_executor_dispatch" == "false" ]]; then
    return 0
  fi

  if [[ $# -le 0 ]]; then
    radp_cli_print_brief_help -n "$g_cli_help_main_prog_name" -s "${!g_cli_subcmd_executor_mapper[@]}"
    exit 0
  fi
  local subcmd=$1
  shift
  case "$subcmd" in
    -h | --help)
      radp_cli_print_brief_help -n "$g_cli_help_main_prog_name" -s "${!g_cli_subcmd_executor_mapper[@]}"
      exit 0
      ;;
    *)
      local executor_file=${g_cli_subcmd_executor_mapper[$subcmd]}
      if [[ -n "$executor_file" && -f "$executor_file" ]]; then
        [[ ! -x "$executor_file" ]] && chmod +x "$executor_file"
        radp_log_info "$g_cli_help_main_prog_name $subcmd $* -> $executor_file $*"
        # shellcheck disable=SC1090
        source "$executor_file" "$@" || {
          return 1
        }
      else
        radp_cli_print_brief_help -n "$g_cli_help_main_prog_name" -s "${!g_cli_subcmd_executor_mapper[@]}"
        exit 1
      fi
      ;;
  esac
}

#######################################
# 获取当前执行的程序名称。
# 这个函数根据脚本的调用来源确定程序的名称。它旨在用于框架内部，以辅助生成帮助信息和日志记录等。
# 如果当前脚本是主程序脚本，则直接使用其名称；如果是以 executor 形式执行的脚本，
# 则从全局变量 g_cli_main_prog_name 获取主程序名称，并附加当前 executor 的标识。
#
# Globals:
#   g_cli_main_prog_name - 主程序的名称，用于构造完整的命令行工具名称。
#
# Returns:
#   打印出当前执行的程序名称，适用于日志、帮助信息等场景。
#
# Examples:
#   假设主程序名称为 "radpctl"，当前执行的脚本为 "install_executor.sh"，
#   则输出将是 "radpctl install"。
#######################################
function __framework_cli_get_prog_name() {
  local cur_script
  cur_script=$(basename "${BASH_SOURCE[2]}")

  if [[ "$(basename "$g_cli_help_main_prog_name")" == "$cur_script" ]]; then
    echo "$cur_script"
  else
    echo "$g_cli_help_main_prog_name ${cur_script%*_executor.sh}"
  fi
}

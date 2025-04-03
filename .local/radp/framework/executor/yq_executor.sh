#!/usr/bin/env bash

# shellcheck source=../bootstrap.sh
########################################################################################################################
# Note: 在这部分定义具体的函数
function yq_executor_run() {
  local result_type=${1:?'Miss -t or --result-type option'}
  local -n __nr_yq_executor_result__=${2:?'Miss -r or --result option'}
  local yaml_file=${3:?}
  local yq_query=${4:?'Miss -s or --yq option'}
  radp_log_info "yaml_file=$yaml_file"
  radp_plugin_yq_nr_parse_yaml "$result_type" __nr_yq_executor_result__ "${yq_query}" "$yaml_file"
  :
}
#----------------------------------------------------------------------------------------------------------------------=

#######################################
# 命令行参数具体处理函数
# 将对应的选项存储到关联数组中
# @see radp_cli_nr_getopt_parser
# Arguments:
#  1 - __nr_python_executor_parsed_args__: 存储解析后的参数
#######################################
function __yq_executor_process_opts() {
  local -n __nr_yq_executor_parsed_args__=$1
  shift
  local -a remaining_args
  radp_nr_cli_parse_common_options __nr_yq_executor_parsed_args__ remaining_args "$@"

  local idx=0
  while [[ idx -lt "${#remaining_args[@]}" ]]; do
    case "${remaining_args[idx]}" in
      -c | --yaml-file)
        __nr_yq_executor_parsed_args__['yaml-file']=${remaining_args[idx + 1]}
        ((idx += 2))
        ;;
      -e | --active-profile)
        __nr_yq_executor_parsed_args__['active-profile']=${remaining_args[idx + 1]}
        ((idx += 2))
        ;;
      -t | --result-type)
        __nr_yq_executor_parsed_args__['result-type']=${remaining_args[idx + 1]}
        ((idx += 2))
        ;;
      -r | --result)
        __nr_yq_executor_parsed_args__['result']=${remaining_args[idx + 1]}
        ((idx += 2))
        ;;
      -s | --yq)
        __nr_yq_executor_parsed_args__['yq']=${remaining_args[idx + 1]}
        ((idx += 2))
        ;;
      --)
        ((idx++)) || true
        # 保存 -- 之后的参数
        __nr_yq_executor_parsed_args__['extended_args']="${remaining_args[*]:idx}"
        radp_log_debug "cli extended args: ${__nr_yq_executor_parsed_args__['extended_args']}"
        break
        ;;
      *)
        radp_log_error "Unknown option: ${remaining_args[idx]}. Try '-h' for more information"
        return 1
        ;;
    esac
  done
}

#######################################
# 命令行参数解析器
# Globals:
#   g_cli_cmd_man_mapper - 命令行帮助文档映射器
#   g_getopt_common_long_opts - 命令行通用长选项
#   g_getopt_common_short_opts - 命令行通用短选项
# Arguments:
#   @ - 所有命令行参数
#######################################
function __yq_executor_cli_parser() {
  local subcmd parse_args_func
  subcmd=$(radp_cli_get_subcmd_by_script_file "${BASH_SOURCE[0]}")
  parse_args_func="__${subcmd}_executor_process_opts"
  # 命令行参数配置
  local short_opts="${g_getopt_common_short_opts}c:e:t:r:s:"
  local long_opts="${g_getopt_common_long_opts},yaml-file:,active-profile:,result-type:,result:,yq:"
  local -A opts_desc
  radp_nr_lang_copy_from_map opts_desc g_getopt_common_desc
  opts_desc['yaml-file']='Specify yaml file'
  opts_desc['active-profile']='Specify env, eg. local/dev/prod, etc.'
  opts_desc['result-type']='返回值数据类型, eg. -a/-A, etc.'
  opts_desc['result']='接收返回值的变量'
  opts_desc['yq']='Specify the yq query str'
  # 命令行参数解析
  local -A parsed_args
  radp_nr_cli_parser -r parsed_args -o "$short_opts" -l "$long_opts" -d opts_desc -p "$parse_args_func" -m "${g_cli_cmd_man_mapper[$subcmd]}" -- "$@"

  # 命令分发
  case "${parsed_args['function']}" in
    run)
      local result_type=${parsed_args['result-type']}
      local yaml_file=${parsed_args['yaml-file']}
      local env=${parsed_args['active-profile']}
      local yq_query=${parsed_args['yq']}
      if [[ -z "$yaml_file" ]]; then
        yaml_file=$(radp_vagrant_api_get_config_file "$env")
      fi
      local result
      yq_executor_run "$result_type" result "$yaml_file" "${yq_query}"
      radp_log_info "$(radp_nr_utils_print_assoc_arr result)"
      ;;
    *)
      radp_cli_print_help_of_invalid_subcmd_function "${parsed_args['function']}" "${BASH_SOURCE[0]}"
      return 1
      ;;
  esac
}


#######################################
# 声明当前 executor file 的全局常量
# 规范
# 示例: declare -gr default_xx_yyy=default_value, 其中 xx 为 subcmd
# Arguments:
#  None
#######################################
function __declare_constants() {
  # TODO: optional 如果有需要在这里定义常量
  # 如果要定义当前脚本的全局变量，请统一定义在这里
  # 1, 对于 framework executor 将会定义在 framework/includes/vars/constants/executor/constants_$subcmd.sh 中
  # 2. 对于 user executor 你可以定义在这个方法中，也可以考虑定义在 lib 目录下
  :
}

#######################################
# 执行器主函数入口
# Arguments:
#  @ - 所有命令行参数
#######################################
function main() {
  # shellcheck source=./executor.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/executor.sh
  __declare_constants
  __yq_executor_cli_parser "$@"
}

main "$@"

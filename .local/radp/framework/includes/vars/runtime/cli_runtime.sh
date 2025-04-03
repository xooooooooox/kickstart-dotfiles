#!/usr/bin/env bash
# shellcheck source=../global_vars.sh

function main() {
  local main_script_name main_script_bin_path
  main_script_name="$(basename "$0")"
  main_script_bin_path=$(cd "$(dirname "$0")" && pwd)

  # 主脚本信息
  declare -gxr g_main_script_name=${g_main_script_name:-${main_script_name}}
  declare -gxr g_main_script_bin_path=${g_main_script_bin_path:-${main_script_bin_path}} # 之所以这么写，是为了规避在代码运行过程中通过 ${g_cli_subcmd_executor_mapper['subcmd']} 调用时，该变量的值会被重写为 executor_file 所在路径

  # 命令帮助文档相关
  # 1. cli help prog name
  if command -v "$main_script_name" >/dev/null 2>&1; then
    declare -gxr g_cli_help_main_prog_name=${main_script_name%.*}
  else
    declare -gxr g_cli_help_main_prog_name="$0"
  fi

  # 2. cli subcmd, executor, args
  # subcmd -> executor_file 映射器
  declare -gxA g_cli_subcmd_executor_mapper #@see 2_autoconfigure_executor.sh
  # executor_file 与 man 映射器(包含内容如上)
  declare -gxA g_cli_cmd_man_mapper #@see 2_autoconfigure_executor.sh
  # 经过 @radp_cli_nr_getopt_common_args_process 解析后剩下的未解析的参数
  declare -gxa g_cli_remaining_args #@see cli.sh
}

main

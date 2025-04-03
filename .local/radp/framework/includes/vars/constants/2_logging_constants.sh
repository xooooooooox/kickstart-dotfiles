#!/usr/bin/env bash

function main() {
  declare -grA g_log_level_id=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
  )
  declare -gr g_color_no="\033[0m"
  declare -gr g_color_blue="\033[0;34m"
  declare -gr g_color_green="\033[0;32m"
  declare -gr g_color_yellow="\033[1;33m"
  declare -gr g_color_red="\033[0;31m"
  # 定义命令及其对应的日志级别,@see radp_utils_run, 未指定则为 info
  declare -grA g_command_log_levels=(
    ['getopt']="debug"
  )

  declare -gra g_colors=("$g_color_blue" "$g_color_green" "$g_color_yellow" "$g_color_red" "$g_color_no") # 索引 0-4 分别表示 debug, info, error, default; 想要使用什么颜色就使用 g_colors 的索引下标
}

main

#!/usr/bin/env bash

#######################################
# executor_file 初始化
# executor_file 存在两种使用场景:
# 1) 一种是作为 subcommand 子命令被框架分发调用
# 2) 另一种是直接执行 executor_file 脚本
# 对于第一种情况，当前 shell 上下文中一般已经加载了 framework
# 而第二种情况，shell 上下文中是没有加载 framework 的，
# 为了提高代码的强壮性，在这个方法中也显式的 source 了 framework
#
# Globals:
#   BASH_SOURCE
#   g_framework_root
# Arguments:
#  None
#######################################
function __executor_bootstrap() {
  local cur_script_abs_dir framework_home
  cur_script_abs_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  framework_home=${g_framework_root:-$(dirname "${cur_script_abs_dir}")}
  # shellcheck source=../bootstrap.sh
  source "$framework_home"/bootstrap.sh
}

#######################################
# framework 基础执行器
#
# Arguments:
#  None
# Notes:
#  1) framework executor_path 下的所有 executor_file 均需要 source 这个基础执行器
#  2) 这个基础执行器封装了 framework executor_file 的所有公共逻辑
#######################################
function main() {
  __executor_bootstrap "$@"
}

main "$@"

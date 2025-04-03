#!/usr/bin/env bash
# shellcheck source=../global_vars.sh

function main() {
  local cur_user l_sudo
  cur_user=$(id -un 2>/dev/null || true)
  l_sudo=$([[ "${cur_user}" != "root" ]] && echo "sudo " || echo "")

  declare -gr g_current_user=$cur_user
  declare -gr g_sudo="$l_sudo"

  # 避免被重复 source.
  # true 表示已经被 source 过了
  # 如果想要强制重复 source 需要强制，需要先将其置为 false
  declare -g g_flag_framework_loaded # 当前 shell 环境
  declare -gx gx_flag_running        # 标记当前命令行正在运行中
}

main

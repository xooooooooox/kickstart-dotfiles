#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#######################################
# 将 radpctl 安装到本地,并配置环境变量
# Globals:
#   HOME
#   SHELL
#   g_cli_subcmd_executor_mapper
# Arguments:
#   None
# Returns:
#   1 ...
#######################################
function radp_omg_radpctl_install() {
  local srcdir
  srcdir="$(dirname "$(dirname "$(radp_os_get_absolute_path "$0")")")"
  local dist_dir dist_file
  dist_dir=$(mktemp -d) || return 1
  dist_file=${dist_dir}/$(basename "$0").tar.gz

  ${g_cli_subcmd_executor_mapper['framework']} -f build -s "$srcdir" -d "${dist_file}"

  local target="$HOME/.local/radp"
  if [[ -d "$target" ]]; then
    # 创建主脚本软链接到 ~/.local/bin
    if ! command -v "$(basename "$0")" >/dev/null 2>&1; then
      [[ ! -d "$HOME/.local/bin" ]] && mkdir -p "$HOME"/.local/bin
      ln -snf "$target/bin/$(basename "$0")" "$HOME/.local/bin/$(basename "$0")"
    fi
    if radp_io_prompt_continue --level warn --msg "$target existed, overwrite?(y/N)" --default n --timeout 30; then
      #! 避免误删
      if [[ "$target" == "$HOME" || "$target" == '/' ]]; then
        return 1
      fi
      rm -r "$target"
    else
      return 0
    fi
  fi
  # 覆盖安装
  [[ ! -d "$target" ]] && mkdir -p "$target" || return 1
  radp_utils_run "tar -xzf ${dist_file} -C $target" || return 1
  if ! command -v "$(basename "$0")" >/dev/null 2>&1; then
    [[ ! -d "$HOME/.local/bin" ]] && mkdir -p "$HOME"/.local/bin
    ln -snf "$target/bin/$(basename "$0")" "$HOME/.local/bin/$(basename "$0")"
  fi
  if [[ -f "$dist_file" ]]; then
    radp_utils_run "rm -v $dist_file"
  fi
}

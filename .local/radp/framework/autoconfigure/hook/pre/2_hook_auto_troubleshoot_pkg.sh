#!/usr/bin/env bash
# shellcheck source=./../../../bootstrap.sh

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#######################################
# 自动 hook 自定义 yum repo
# Globals:
#   g_hook_custom_yum_repo_flag - 是否已经执行过 hook
#   g_sudo
#   g_user_extra_config_path
# Arguments:
#  None
# Returns:
#   1 ...
# Notes:
#   仅执行一次,由 g_hook_custom_yum_repo_flag 控制
#######################################
function radp_hook_custom_yum_repo() {
  if command -v yum >/dev/null 2>&1; then
    if [[ ! -f "$g_pre_hook_auto_troubleshoot_pkg_flg" ]]; then
      # 避免重复 hook
      $g_sudo touch "$g_pre_hook_auto_troubleshoot_pkg_flg"
      # 自动判断是否需要使用 custom yum repo
      if ! radp_utils_run "$g_sudo yum makecache" >/dev/null 2>&1; then
        radp_log_warn "Hooking custom yum repo"
        local yum_repo_dir=/etc/yum.repos.d
        radp_utils_run "$g_sudo mkdir -pv $yum_repo_dir/backup"
        # backup current yum repo file
        find "$yum_repo_dir" -maxdepth 1 -type f -exec $g_sudo mv -v {} ${yum_repo_dir}/backup \; || return 1
        # copy custom yum repo files to /etc/yum.repos.d
        local _ distro_version
        IFS=':' read -r _ _ distro_version _ < <(radp_os_get_distro_info)
        radp_utils_run "$g_sudo cp -v $g_user_extra_config_path/yum/$distro_version/*.repo $yum_repo_dir" || return 1
      fi
    fi
  fi
}

function main() {
  if [[ "$g_pre_hook_auto_troubleshoot_pkg" == true ]]; then
    case "$g_guest_distro_pkg" in
      yum)
        declare -gr g_pre_hook_auto_troubleshoot_pkg_flg=/etc/yum.repos.d/hook_auto_troubleshoot_pkg.flg
        radp_hook_custom_yum_repo
        ;;
      apt-get)
        declare -gr g_pre_hook_auto_troubleshoot_pkg_flg=/etc/apt/hook_auto_troubleshoot_pkg.flg
        # 避免即使配置了 apt-get http-proxy, 执行 install 时, 还是会失败的问题
        if command -v apt-get >/dev/null; then
          if [[ ! -f "$g_hook_custom_yum_repo_flag" ]]; then
            sudo apt-get update || return 1
            $g_sudo touch "$g_pre_hook_auto_troubleshoot_pkg_flg"
          fi
        fi
        ;;
      *)
        return 0
        ;;
    esac
  fi
}

main

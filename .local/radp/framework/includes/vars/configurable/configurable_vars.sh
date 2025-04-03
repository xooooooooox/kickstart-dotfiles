#!/usr/bin/env bash
# shellcheck source=../global_vars.sh

#######################################
# 用户扩展目录
# Globals:
#   省略
# Arguments:
#  None
# Returns:
#   1 - 如果用户配置文件目录/扩展库根目录 与 框架配置文件目录/扩展库根目录一致，则返回 1
#######################################
function __framework_declare_user_paths_settings() {
  # user path
  local framework_parent_dir
  framework_parent_dir=$(dirname "${g_framework_root}")
  declare -gr g_user_includes_root=${G_USER_INCLUDES_ROOT:-"$framework_parent_dir"/extend}
  declare -gr g_user_integrations_path=${G_USER_INTEGRATIONS_PATH:-"$framework_parent_dir"/extend/integrations}
  declare -gr g_user_plugins_path=${G_USER_PLUGIN_PATH:-"$framework_parent_dir"/extend/plugins}
  declare -gr g_user_executor_path=${G_USER_EXECUTOR_PATH:-"$framework_parent_dir"/executor}
  declare -gr g_user_man_path=${G_USER_MAN_PATH:-"$framework_parent_dir"/man}
  declare -gr g_user_executor_regex=${G_USER_EXECUTOR_REGEX:-${g_framework_executor_regex}}
  declare -gr g_user_man_regex=${G_USER_MAN_REGEX:-${g_framework_man_regex}}
  declare -gr g_user_plugin_regex=${G_USER_PLUGIN_REGEX:-${g_framework_plugin_regex}}
  declare -gr g_user_extra_config_path=${G_USER_EXTRA_CONFIG_PATH:-"$g_user_config_path"/extra}

  # check
  [[ "$g_user_config_path" == "$g_framework_config_path" ]] && {
    echo "Error: invalid G_USER_CONFIG_PATH '$g_user_config_path'"
    return 1
  }
  [[ "$g_user_includes_root" == "$g_framework_includes_root" ]] && {
    echo "Error: invalid G_USER_INCLUDES_ROOT '$g_user_includes_root'"
    return 1
  }
}

#######################################
# 日志配置
#
# Globals:
#   省略
#
# @see 2_logging_constants.sh
# @see g_colors
#######################################
function __framework_declare_logging_settings() {
  declare -gr g_log_level=${G_LOG_LEVEL:-'info'}
  declare -gr g_log_file=${G_LOG_FILE:-"${HOME}"/logs/$(basename "$0").log}
  declare -gr g_log_file_max_size=${G_LOG_FILE_MAX_SIZE:-'10MB'}
  declare -gr g_log_file_retention_days=${G_LOG_FILE_RETENTION_DAYS:-15}
  [[ ${#G_LOG_LEVEL_COLOR_CONFIG[@]} == 5 ]] && g_log_level_color_config=("${G_LOG_LEVEL_COLOR_CONFIG[@]}") || g_log_level_color_config=(0 1 2 3 4)
  declare -gra g_log_level_color_config
}

#######################################
# 调试配置
# Globals:
#   G_DEBUG
#   g_debug
# Arguments:
#  None
#######################################
function __framework_declare_debug_settings() {
  declare -gr g_debug=${G_DEBUG:-'false'}
}

#######################################
# 命令行配置
# Globals:
#   G_ENABLE_SUBCMD_EXECUTOR_DISPATCH
#   g_enable_subcmd_executor_dispatch
# Arguments:
#  None
#######################################
function __framework_declare_cli_settings() {
  declare -gr g_enable_subcmd_executor_dispatch=${G_ENABLE_SUBCMD_EXECUTOR_DISPATCH:-'true'} # 是否启用子命令执行器分发功能
  declare -gr g_cli_subcmd_executor_processor_function_name_regex='__xx_executor_options_processor'
}


#######################################
# 自动配置设置
# Globals:
#   G_PRE_AUTOCONFIGURE_HOOK_CUSTOM_YUM_REPO_ENABLED
#   g_pre_autoconfigure_hook_custom_yum_repo_enabled
# Arguments:
#  None
#######################################
function __framework_declare_autoconfigure_settings() {
  declare -gr g_pre_hook_auto_troubleshoot_pkg=${G_PRE_HOOK_AUTO_TROUBLESHOOT_PKG:-'true'}
}

#######################################
# 集成工具配置
# Globals:
#   省略
#######################################
function __framework_declare_integration_settings() {
  :
}

#######################################
# 插件配置
# Globals:
#   G_SETTINGS_STR_PLUGIN_PROXY
#   G_SETTINGS_STR_PLUGIN_YQ
#   g_settings_str_plugin_proxy
#   g_settings_str_plugin_yq
# Arguments:
#  None
#######################################
function __framework_declare_plugin_settings() {
  declare -gr g_settings_str_plugin_proxy=${G_SETTINGS_STR_PLUGIN_PROXY:-"enabled=false;candidate_ips='';proxy_ip='';http_port=20171;socks5_port=20170"}
  declare -gr g_settings_str_plugin_yq=${G_SETTINGS_STR_PLUGIN_YQ:-"enabled=false;version=latest;url=https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"}
}

#######################################
# 虚拟机配置
# Globals:
#   G_GUEST_CLUSTER_DATA_DIR
#   G_GUEST_DATA_DIR
#   g_guest_cluster_data_dir
#   g_guest_data_dir
# Arguments:
#  None
#######################################
function __framework_declare_guest_settings() {
  declare -gr g_guest_user=${G_GUEST_USER:-x9x}
  declare -gr g_guest_data_dir=${G_GUEST_DATA_DIR:-/data}
  declare -gr g_guest_cluster_data_dir=${G_GUEST_CLUSTER_DATA_DIR:-/cluster_data}
  declare -gr g_guest_public_data_dir=${G_GUEST_PUBLIC_DATA_DIR:-/public_data}
  declare -gr g_guest_docker_volume_root=${G_GUEST_DOCKER_VOLUME_ROOT:-/docker_data}
  declare -gr g_guest_backup_root=${G_GUEST_BACKUP_ROOT:-/backup_data}

  declare -gr g_guest_ssl_root=${G_GUEST_SSL_ROOT:-"${g_guest_public_data_dir}"/ssl}
}

#######################################
# 用户自定义配置
# Globals:
#   g_user_includes_root
# Arguments:
#  None
#######################################
function __framework_declare_user_extended_settings() {
  radp_source_local_scripts "$g_user_includes_root"/vars/configurable
}

function main() {
  __framework_declare_user_paths_settings
  __framework_declare_logging_settings
  __framework_declare_debug_settings
  __framework_declare_cli_settings
  __framework_declare_autoconfigure_settings
  __framework_declare_integration_settings
  __framework_declare_plugin_settings
  __framework_declare_guest_settings
}

main

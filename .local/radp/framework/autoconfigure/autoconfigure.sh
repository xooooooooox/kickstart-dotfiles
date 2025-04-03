#!/usr/bin/env bash
set -e
# shellcheck source=../bootstrap.sh

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#######################################
# 获取所有插件的名称。 #TODO function comment
# 插件文件名应符合 *_autoconfigure_plugin_*.sh 的格式。
# Globals:
#   g_framework_plugin_path - 框架插件脚本所在目录
#   g_framework_plugin_regex - 框架插件脚本文件名正则
#   g_user_plugins_dir - 用户插件脚本所在目录
#   g_user_plugin_regex - 用户插件脚本所在目录
# Arguments:
#   None
# Outputs:
#   将所有插件名打印到标准输出。
#######################################
function __framework_set_plugin_file_mapper() {
  local cur_dir framework_plugins_dir user_plugins_dir
  cur_dir=$(dirname "$(radp_os_get_absolute_path)")
  framework_plugins_dir=${g_framework_plugin_path:-"${cur_dir}/plugins"}
  user_plugins_dir=$g_user_plugins_path

  local -a framework_plugin_names
  local plugin_script plugin_name
  if compgen -G "$framework_plugins_dir"/"$g_framework_plugin_regex" >/dev/null 2>&1; then
    for plugin_script in "$framework_plugins_dir"/$g_framework_plugin_regex; do
      # 从文件名中提取插件名
      plugin_name=$(basename "$plugin_script")              # 获取文件的基本名
      plugin_name="${plugin_name##*_autoconfigure_plugin_}" # 移除前缀
      plugin_name="${plugin_name%.sh}"                      # 移除.sh后缀

      # 将插件名添加到数组
      framework_plugin_names+=("$plugin_name")
      g_plugin_file_mapper["$plugin_name"]=$plugin_script
    done
  fi
  radp_log_debug "Available framework plugin names: ${framework_plugin_names[*]}"

  local -a user_plugin_names
  if compgen -G "$user_plugins_dir"/"$g_user_plugin_regex" >/dev/null 2>&1; then
    for plugin_script in "$user_plugins_dir"/$g_user_plugin_regex; do
      # 从文件名中提取插件名
      plugin_name=$(basename "$plugin_script")              # 获取文件的基本名
      plugin_name="${plugin_name##*_autoconfigure_plugin_}" # 移除前缀
      plugin_name="${plugin_name%.sh}"                      # 移除.sh后缀

      # 将插件名添加到数组
      user_plugin_names+=("$plugin_name")
      g_plugin_file_mapper["$plugin_name"]=$plugin_script
    done
  fi
  radp_log_debug "Available user plugin names: ${user_plugin_names[*]}"

  local -a total_plugin_names
  total_plugin_names=("${framework_plugin_names[@]}" "${user_plugin_names[@]}")
  radp_log_debug "Total available plugins: $(radp_nr_utils_print_assoc_arr g_plugin_file_mapper)"
}

#----------------------------------------------------------------------------------------------------------------------#

#######################################
# 自动配置内置组件
# framework 必定会执行的初始化逻辑.自我检查逻辑等等
#
# Notes:
# 1) __framework_autoconfigure_bash5 表示框架会检查是否满足 bash5 环境,如果不满足则会自动安装,并自动重新执行
#
# Arguments:
#  None
#######################################
function __framework_autoconfigure_builtins() {
  radp_source_local_scripts "$g_framework_root"/autoconfigure/builtin || return 1

  radp_log_debug "Builtins autoconfigured"
}

#######################################
# 框架集成的功能,不可插拔
# Globals:
#   g_framework_integrations_path
# Arguments:
#  None
# Returns:
#   1 ...
#######################################
function __framework_autoconfigure_integrations() {
  radp_source_local_scripts "$g_framework_integrations_path"/api || return 1

  radp_log_debug "Integrations api autoconfigured"
}

#######################################
# 自动注入插件
# Globals:
#   g_plugin_file_mapper - plugin_name -> plugin_file 映射器
# Arguments:
#  None
# @see __framework_declare_plugin_settings
#######################################
function __framework_autoconfigure_plugins() {
  __framework_set_plugin_file_mapper
  local plugin_name enabled_plugin_file
  for plugin_name in "${!g_plugin_file_mapper[@]}"; do
    if [[ $(radp_get_settings_value 'plugin' "$plugin_name" 'enabled') == 'true' ]]; then
      enabled_plugin_file="${g_plugin_file_mapper[$plugin_name]}"
      g_enabled_plugins+=("$plugin_name")
      # 注入启用的插件!!!
      radp_source_local_scripts "${g_plugin_file_mapper["$plugin_name"]}" || return 1
      g_enabled_plugin_file_mapper["$plugin_name"]=${enabled_plugin_file}
    fi
  done
  radp_log_debug "Plugins autoconfigured"
}

#######################################
# 自动配置前置处理器
# Globals:
#   g_framework_root
# Arguments:
#  None
# Returns:
#   1 ...
#######################################
function __framework_pre_autoconfigure() {
  # shellcheck source=pre_autoconfigure.sh
  radp_source_local_scripts "$g_framework_root"/autoconfigure/pre_autoconfigure.sh || return 1
}

function main() {
  __framework_pre_autoconfigure || {
    radp_log_error 'Failed to pre autoconfigure'
    return 1
  }
  __framework_autoconfigure_builtins || {
    radp_log_error 'Failed to autoconfigure builtins'
    return 1
  }
  __framework_autoconfigure_integrations || {
    radp_log_error 'Failed to autoconfigure integrations'
    return 1
  }
  __framework_autoconfigure_plugins || {
    radp_log_error 'Failed to autoconfigure enabled plugins'
    return 1
  }
}

main

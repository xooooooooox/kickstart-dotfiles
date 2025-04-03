#!/usr/bin/env bash

# shellcheck source=./../../bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#######################################
# 启用代理设置。根据配置启用 HTTP 和 SOCKS5 代理。
# 如果代理已启用且代理 IP 可用，则将环境变量配置为使用指定的代理。
# Globals:
#   g_plugin_proxy_config - 关联数组，包含代理的配置信息。
# Arguments:
#   None
# Returns:
#   1 - 如果没有配置有效的代理 IP，则返回 1。
# Examples:
#   radp_enable_proxy
# Notes:
#   仅影响当前正在运行的 Shell 进程
#######################################
function radp_plugin_enable_proxy() {
  local proxy_enabled=${g_settings_assoc_plugin_proxy['enabled']}
  if [[ "$proxy_enabled" == "true" ]]; then
    radp_log_warn "Enable proxy: 'http_proxy=$gx_https_proxy https_proxy=$gx_http_proxy all_proxy=$gx_all_proxy'"
    export "http_proxy=$gx_https_proxy https_proxy=$gx_http_proxy all_proxy=$gx_all_proxy"
  fi
}

#######################################
# 禁用代理设置。如果代理已启用，则清除环境变量中的代理设置。
#
# Globals:
#   g_plugin_proxy_config - 关联数组，包含代理的配置信息。
# Arguments:
#   None
# Returns:
#   None
# Examples:
#   radp_disable_proxy
#######################################
function radp_plugin_disable_proxy() {
  if [[ "${proxy_enabled}" == "true" ]]; then
    local proxy_ip=${g_settings_assoc_plugin_proxy['proxy_ip']}
    if [[ -n ${proxy_ip} ]]; then
      radp_log_warn "Disable proxy: 'unset http_proxy https_proxy all_proxy'"
      unset http_proxy https_proxy all_proxy
    fi
  fi
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function __cache_active_proxy_config() {
  local proxy_enabled=${g_settings_assoc_plugin_proxy['enabled']}
  if [[ "$proxy_enabled" == "true" ]]; then
    local http_port=${g_settings_assoc_plugin_proxy['http_port']}
    local socks5_port=${g_settings_assoc_plugin_proxy['socks5_port']}
    local proxy_ip=${g_settings_assoc_plugin_proxy['proxy_ip']}
    local proxy_candidate_ips=${g_settings_assoc_plugin_proxy['candidate_ips']}
    local no_proxy=${g_settings_assoc_plugin_proxy['no_proxy']}

    # 检测
    if [[ -z ${proxy_ip} ]]; then
      radp_log_error "No available proxy ip in '$proxy_candidate_ips'"
      return 1
    fi

    gx_http_proxy="http://${proxy_ip}:${http_port}"
    gx_https_proxy="http://${proxy_ip}:${http_port}"
    gx_all_proxy="socks5://${proxy_ip}:${socks5_port}"
    gx_no_proxy="$no_proxy"
  fi
}

#######################################
# 配置代理插件
# Globals:
#   g_plugin_proxy_config - @see g_settings_str_plugin_proxy
# Arguments:
#  None
#
# @see __framework_autoconfigure_plugins
#######################################
function __framework_plugin_proxy_setup() {
  radp_log_debug "Configure plugin: proxy"
  local proxy_candidate_ips=${g_settings_assoc_plugin_proxy['candidate_ips']}
  local http_proxy_port=${g_settings_assoc_plugin_proxy['http_port']}
  local ip_arr
  IFS=' ' read -r -a ip_arr <<<"$proxy_candidate_ips"

  local ip
  for ip in "${ip_arr[@]}"; do
    if radp_net_check_ip_port_reachable "$ip" "$http_proxy_port" >/dev/null; then
      g_settings_assoc_plugin_proxy['proxy_ip']="$ip"
      radp_log_debug "Updated proxy plugin settings [$(radp_nr_utils_print_assoc_arr g_settings_assoc_plugin_proxy)]"
      break
    else
      radp_log_debug "'$ip' is not reachable on port '$http_proxy_port'."
    fi
  done
  # 如果没有可达的代理 IP, 将临时关闭该插件
  if [[ -z "${g_settings_assoc_plugin_proxy['proxy_ip']}" ]]; then
    radp_log_warn "Suspend the surge proxy plugin because no available proxy ip in '$proxy_candidate_ips'"
    g_settings_assoc_plugin_proxy['enabled']=false
  fi
  # 缓存当前有效的 proxy config
  __cache_active_proxy_config
}

#######################################
# 代理插件自动配置
# Arguments:
#  None
#######################################
function main() {
  __framework_plugin_proxy_setup
}

main

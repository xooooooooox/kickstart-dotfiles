#!/usr/bin/env bash
# shellcheck source=../../../../bootstrap.sh

#######################################
# 检验是否满足 ip:port 的格式
# Arguments:
#  1 - str, 必须 待校验的字符串
# Returns:
#  1 - 如果不匹配 ip:port 的格式
#  0 - 如果匹配
# Notes:
#  TODO 目前这个版本并不校验是否为合法 IP Rage
#######################################
function radp_regex_match_format_ip_port() {
  local str=${1:?}
  # Regex to validate ip:port format
  if [[ $str =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}

function radp_regex_match_format_ip() {
  local str=${1:?}
  # 定义匹配 IPv4 地址的正则表达式
  local regex='^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'

  # 使用正则表达式匹配
  if [[ $str =~ $regex ]]; then
    return 0
  else
    return 1
  fi
}

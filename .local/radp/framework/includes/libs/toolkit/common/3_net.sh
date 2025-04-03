#!/usr/bin/env bash

#######################################
# 检查指定的IP地址和端口是否可达。这是通过尝试在指定的超时时间内
# 使用 /dev/tcp 文件进行连接来实现的。此方法的优点是不依赖于网络诊断工具，
# 如 nc (Netcat)，但要求运行此脚本的环境支持 /dev/tcp。
# Globals:
#   None
# Arguments:
#   1 - ip: 待检查的IP地址。
#   2 - port: 待检查的端口号。
#   3 - timeout (可选): 连接尝试的超时时间（秒）。如果未指定，默认为 5 秒。
# Returns:
#   0 - 如果指定的IP和端口在给定的超时时间内可达
#   1 - 否则返回 1
# Examples:
#   radp_check_ip_port_reachable 192.168.1.1 80
#   radp_check_ip_port_reachable 192.168.1.1 22 10
#######################################
function radp_net_check_ip_port_reachable() {
  local ip=${1:?}
  local port=${2:?}
  local timeout=${3:-5}

  # 使用 timeout 和 /dev/tcp 尝试连接, 避免不是所有及其都安装了 nc
  radp_log_debug "Checking $ip:$port reachable..."
  if timeout "$timeout" bash -c "echo > /dev/tcp/$ip/$port" 2>/dev/null; then
    return 0
  else
    return 1
  fi
}

#######################################
# 检查一组主机的网络可达性
#
# 通过传入的主机名数组，使用 ping 命令检查每个主机是否可达。如果所有主机都可达，函数返回 0，
# 否则，一旦发现不可达的主机，就记录错误并返回 1。
#
# Arguments:
#   $@ - hostnames 要检查的主机名数组
# Returns:
#   如果所有主机都可达返回 0，否则返回 1
# Examples
#   radp_net_check_hosts_reachability "www.google.com" "www.yahoo.com"
#   如果以上网站都可达，返回 0，否则返回 1。
#######################################
function radp_net_check_hosts_reachability() { #FIXME surge enhanced mode 下这个方法貌似会失效
  local -a hostnames=("$@")

  local hostname
  for hostname in "${hostnames[@]}"; do
    radp_log_debug "Checking reachability for $hostname"
    # 使用 ping 进行探活，只发送两个 ICMP 包
    if ! ping -c 2 "$hostname" >/dev/null 2>&1; then
      radp_log_error "Host $hostname is not reachable"
      return 1
    fi
    radp_log_debug "Host $hostname is reachable"
  done
  radp_log_debug "All hosts are reachable"
  return 0
}

#######################################
# 通过网络接口的序号获取其 IP 地址(默认获取 ipv4 地址)
#
# 本函数通过给定的以太网接口序号来获取相应的 IP 地址。如果找到 IP 地址，就将其输出；
# 否则不输出任何内容。
#
# Arguments:
#   number - 网络接口的序号
# Returns:
#   找到的 IP 地址，或者没有输出
# Examples:
#   ip=$(radp_net_get_ip_by_eth 1)
#   如果 eth0 接口存在并获取到 IP 地址，输出该 IP 地址，否则不输出。
# Notes:
#   1) 默认获取 ipv4 地址
#   2) 极端情况下可能没有 ipv4 地址, 则返回 ipv6
#   3) 如果两者都没有, 则返回 -1
#######################################
function radp_net_get_ip_by_eth() {
  local eth=${1:?}
  local eth_ipv4 eth_ipv6
  if ! command -v ifconfig >/dev/null;then
    radp_os_pkg_install net-tools >/dev/null || return 1
  fi
  # 这里只关心 ipv4 地址
  eth_ipv4=$(ifconfig "$eth" | grep inet | grep -v inet6 | awk 'NR==1' | awk '{print $2}')
  eth_ipv6=$(ifconfig "$eth" | grep inet6 | awk 'NR==1' | awk '{print $2}')
  if [[ -n $eth_ipv4 ]]; then
    echo "$eth_ipv4"
  elif [[ -n $eth_ipv6 ]]; then
    echo "$eth_ipv6"
  else
    return 1
  fi
}

function radp_net_get_eth_by_ip() {
  local ip=${1:?}
  local eth

  # 遍历所有网络接口
  for eth in /sys/class/net/*; do
    eth=$(basename "$eth")
    # 检查接口是否有指定的IP地址
    if ip addr show "$eth" | grep -q "$ip"; then
      echo "$eth"
      return 0
    fi
  done

  # 如果没有找到匹配的接口,返回错误
  return 1
}

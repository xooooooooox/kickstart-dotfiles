#!/usr/bin/env bash
# shellcheck source=../global_vars.sh

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#######################################
# 查询 vagrant.yaml 中指定 hostname 所属的集群 groupId
# Arguments:
#   1 - hostname
#######################################
function radp_yq_query_enabled_clusters_by_hostname() {
  local hostname=${1:?}
  echo ".vagrant.guests[] | select(.network.hostname == \"${hostname}\")|.groupId"
}

#######################################
# 根据 hostname 查询对应的 ip
# Arguments:
#   1 - hostname
#######################################
function radp_yq_query_ip_by_hostname() {
    local hostname=${1:?}
    echo ".vagrant.guests[] | select(.network.hostname == \"${hostname}\")|.network.privateNetwork.ip"
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function main() {
  declare -gr g_yq_query_enabled_clusters='[.vagrant.guests[] | select(.enabled==true) | .groupId] | unique |.[]'
}

main

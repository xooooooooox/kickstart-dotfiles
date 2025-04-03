#!/usr/bin/env bash
# shellcheck source=../global_vars.sh

function main() {
  # uname -m
  declare -glx g_guest_distro_arch
  # x86_64->amd64, aarch64 -> arm64
  declare -glx g_guest_distro_arch_alias
  # uname -s
  declare -glx g_guest_distro_os
  # /etc/os-release $ID
  declare -glx g_guest_distro_id
  # /etc/os-release $NAME
  declare -glx g_guest_distro_name
  # /etc/os-release $VERSION_ID
  declare -glx g_guest_distro_version
  # 根据以上信息计算得到
  declare -glx g_guest_distro_pkg
}

main

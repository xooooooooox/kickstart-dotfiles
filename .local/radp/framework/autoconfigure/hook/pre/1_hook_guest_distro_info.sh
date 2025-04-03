#!/usr/bin/env bash
set -e

# shellcheck source=./../../../bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

function _transform_arch_name() {
  local arch_name=${1:?}
  case "$arch_name" in
    x86_64)
      g_guest_distro_arch_alias="amd64"
      ;;
    aarch64)
      g_guest_distro_arch_alias="arm64"
      ;;
    *)
      echo "Unknown distro arch $arch_name"
      return 1
      ;;
  esac
}

function main() {
  local distro_id distro_name distro_version distro_pkg
  IFS=':' read -r distro_id distro_name distro_version distro_pkg < <(radp_os_get_distro_info)

  # 比如:
  # 1) mbp: x86_64, Darwin, osx, osx, .., brew
  # 2) centos9: x86_64, Linux, centos, CentOS Stream, 9, dnf
  # 3) ubuntu: x86_64, Linux,

  g_guest_distro_arch=$(uname -m)
  _transform_arch_name "$g_guest_distro_arch"
  g_guest_distro_os=$(uname -s)
  g_guest_distro_id=$distro_id
  g_guest_distro_name=$distro_name
  g_guest_distro_version=$distro_version
  g_guest_distro_pkg=$distro_pkg

  radp_log_info "Detected distro info [id=$g_guest_distro_id, name=$g_guest_distro_name, version=$g_guest_distro_version, pkg=$g_guest_distro_pkg, arch=$g_guest_distro_arch, arch_alias=$g_guest_distro_arch_alias]"
}

main

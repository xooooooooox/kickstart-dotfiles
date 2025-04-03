#!/usr/bin/env bash
set -e

# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_ansible_install() {
  if command -v ansible >/dev/null 2>&1; then
    radp_log_info "ansible already installed"
    return 0
  fi

  case "$g_guest_distro_pkg" in
  apt)
    $g_sudo apt update
    $g_sudo apt update
    $g_sudo apt install software-properties-common
    $g_sudo apt-add-repository --yes --update ppa:ansible/ansible
    $g_sudo apt install ansible
    ;;
  *)
    radp_log_error "Not implemented on current os."
    return 1
    ;;
  esac
}
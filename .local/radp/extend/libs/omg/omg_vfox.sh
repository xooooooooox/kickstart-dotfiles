#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_vfox_install() { #TODO 修改 xxx 为需要安装的
  if command -v vfox >/dev/null 2>&1; then
    radp_log_info "vfox already installed"
    return 0
  fi

  case "$g_guest_distro_pkg" in
    brew)
      brew install vfox || return 1
      ;;
    yum | dnf)
      echo '[vfox]
name=VersionFox Repo
baseurl=https://yum.fury.io/versionfox/
enabled=1
gpgcheck=0' | sudo tee /etc/yum.repos.d/versionfox.repo
      $g_sudo yum install -y vfox
      ;;
    apt | apt-get)
      echo "deb [trusted=yes] https://apt.fury.io/versionfox/ /" | sudo tee /etc/apt/sources.list.d/versionfox.list
      sudo apt-get update
      sudo apt-get install vfox
      ;;
    *)
      radp_log_error "Not implemented on current os."
      return 1
      ;;
  esac
}

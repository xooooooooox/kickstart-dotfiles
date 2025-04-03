#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

function radp_omg_maven_install() {
  local version=${1:-3.9.8}
  if command -v mvn >/dev/null 2>&1; then
    radp_log_info "maven already installed"
    return 0
  fi
  case "$g_guest_distro_id" in
    osx)
      radp_alias_brew install maven || return 1
      ;;
    *)
      local tmpdir
      tmpdir=$(mktemp -d)
      pushd "$tmpdir" || return 1
      radp_utils_retry -- "wget https://dlcdn.apache.org/maven/maven-3/${version}/binaries/apache-maven-$version-bin.tar.gz -O apache-maven-$version-bin.tar.gz"
      local latest_mvn_home=/opt/maven/apache-maven-$version
      radp_utils_run "$g_sudo mkdir -p $(dirname "$latest_mvn_home")"
      radp_utils_run "$g_sudo chown ${g_cur_user}:${g_cur_user} $(dirname $latest_mvn_home)"
      tar -xzvf "apache-maven-$version-bin.tar.gz" -C "$(dirname "$latest_mvn_home")"
      ln -snf "$latest_mvn_home" /opt/maven/current
      ;;
  esac
}

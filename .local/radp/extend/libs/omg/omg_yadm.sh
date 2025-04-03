#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_yadm_install() {
  if command -v yadm >/dev/null 2>&1; then
    radp_log_info "yadm already installed"
    return 0
  fi
  radp_omg_gpg_install || return 1
  case "$g_guest_distro_id" in
    osx)
      brew install yadm
      ;;
    *)
      # 为了保证 git restore 等命令可用
      # 之类最好是保证 git 版本不要太低
      # centos7 等 RHEL 默认安装的都是较低的 git 版本,如 1.x
      radp_omg_git_install || return 1
      radp_utils_retry -- "$g_sudo curl -fLo /usr/local/bin/yadm https://github.com/TheLocehiliosan/yadm/raw/master/yadm"
      $g_sudo chmod a+x /usr/local/bin/yadm || return 1
      ;;
  esac
}

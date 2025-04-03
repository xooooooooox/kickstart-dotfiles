#!/usr/bin/env bash
##
# see https://github.com/git-ecosystem/git-credential-manager/releases/tag/v2.5.1

# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_git_credential_manager_install() {
  local version=${1:-2.5.1}
  if ! command -v pass >/dev/null 2>&1; then
    radp_omg_pass_install || return 1
  fi
  if command -v git-credential-manager >/dev/null 2>&1;then
    radp_log_info "git-credential-manager already installed"
    return 0
  fi
  case "$g_guest_distro_id" in
    osx)
      brew install --cask git-credential-manager || return 1
      ;;
    ubuntu|centos)
      local download_url="https://github.com/git-ecosystem/git-credential-manager/releases/download/v${version}/gcm-linux_amd64.${version}.tar.gz"
      local tarball
      tarball=$(basename "$download_url")
      local tmpdir
      tmpdir=$(mktemp -d)
      radp_utils_retry -- "wget -P $tmpdir $download_url" || return 1
      radp_utils_run "$g_sudo tar -xzvf ${tmpdir}/$tarball -C /usr/local/bin" || return 1
      radp_utils_run "rm -rv $tmpdir"
      ;;
    *)
      radp_log_error "Not support install git-credential-manager on $g_guest_distro_id"
      return 1
      ;;
  esac
}

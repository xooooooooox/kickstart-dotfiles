#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_helm_install() {
  if command -v helm >/dev/null 2>&1; then
    radp_log_info "helm already installed"
    return 0
  fi
  case "$g_guest_distro_id" in
    osx)
      brew install helm || return 1
      ;;
    *)
      curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
      helm completion bash | sudo tee /etc/bash_completion.d/helm
      ;;
  esac
}

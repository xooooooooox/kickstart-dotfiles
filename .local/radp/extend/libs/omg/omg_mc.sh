#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_mc_install() {
  if command -v mc >/dev/null 2>&1; then
    radp_log_info "minio clint already installed"
    return 0
  fi
  case "$g_guest_distro_os" in
    darwin)
      brew install minio/stable/mc || return 1
      ;;
    linux)
      curl https://dl.min.io/client/mc/release/linux-${g_guest_distro_arch_alias}/mc \
        --create-dirs \
        -o "$HOME"/minio-binaries/mc || return 1

      chmod +x "$HOME"/minio-binaries/mc
      export PATH=$PATH:$HOME/minio-binaries/

      ;;
    *)
      return 1
      ;;
  esac

  if ! mc alias list | grep -q myminio; then
    bash +o history
    mc alias set myminio https://minio.xozoz.com hlic6XPWMOiJ4gkqsQAA 2hKYBoA7NtxhnE8NfXzaFhzCAFSj9GZng9XpaMg8
    bash -o history
  fi
}

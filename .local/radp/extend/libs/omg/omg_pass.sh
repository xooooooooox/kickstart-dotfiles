#!/usr/bin/env/bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_pass_install() {
  if command -v pass >/dev/null 2>&1;then
    radp_log_info "pass already installed"
    return 0
  fi
  case "$g_guest_distro_pkg" in
  brew | dnf)
    radp_os_pkg_install pass || return 1
    ;;
  *)
    local tarball_url tarball_filename tarball tmpdir
    tarball_url=https://git.zx2c4.com/password-store/snapshot/password-store-1.7.4.tar.xz
    tarball_filename=$(basename "$tarball_url")
    tmpdir=$(mktemp -d) || return 1
    tarball=${tmpdir}/${tarball_filename}
    radp_utils_run "wget -P $tmpdir $tarball_url"
    radp_utils_run "tar -xf $tarball -C $tmpdir"
    if ! command -v make >/dev/null 2>&1;then
      radp_os_pkg_install make
    fi
    pushd "${tmpdir}/${tarball_filename%.tar.xz}" || return 1
    radp_utils_run "$g_sudo make install" || return 1
    popd || return 1
    radp_utils_run "rm -r $tmpdir"
    ;;
  esac
}

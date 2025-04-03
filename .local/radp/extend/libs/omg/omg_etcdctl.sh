#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_etcdctl_install() {
  if command -v etcdctl >/dev/null 2>&1; then
    radp_log_info "etcdctl already installed"
    return 0
  fi

  local version=v${1:-3.5.12}
  local target_base_dir=/opt/etcdctl
  local extension target_base_dir exec_path
  case "$g_guest_distro_os" in
    darwin)
      extension=zip
      target_base_dir="$HOME"/.local
      if [[ ! -d "$target_base_dir" ]]; then
        mkdir -vp "$target_base_dir"
      fi
      exec_path="$HOME"/.local/bin
      ;;
    linux)
      extension=tar.gz
      target_base_dir=/opt/etcd
      if [[ ! -d "$target_base_dir" ]]; then
        mkdir -vp "$target_base_dir" 2>/dev/null || $g_sudo mkdir -vp "$target_base_dir"
      fi
      exec_path=/usr/local/bin
      ;;
  esac
  local download_url=https://storage.googleapis.com/etcd/"$version"/etcd-"$version"-"$g_guest_distro_os"-"$g_guest_distro_arch_alias"."$extension"
  local tmpdir filename target_dir
  tmpdir=$(mktemp -d)
  filename=$(basename "$download_url")
  pushd "$tmpdir" || return 1
  curl -L "$download_url" -o "$filename" || return 1
  case "$extension" in
    zip)
      unzip "$filename" -d "$target_base_dir" || return 1
      target_dir="$target_base_dir"/${filename%.zip}
      ;;
    tar.gz)
      tar -xzf "$filename" -C "$target_base_dir" 2>/dev/null || $g_sudo tar -xzf "$filename" -C "$target_base_dir" || return 1
      target_dir="$target_base_dir"/${filename%.tar.gz}
      ;;
  esac
  $g_sudo ln -snf "$target_dir"/etcdctl "$exec_path"/etcdctl \
    && $g_sudo ln -snf "$target_dir"/etcdutl "$exec_path"/etcdutl \
    && etcdctl version || return 1
  radp_utils_run "rm -rv $tmpdir"
}

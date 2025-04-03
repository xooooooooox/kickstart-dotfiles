#!/usr/bin/env bash
set -e

declare -gx GX_ENABLE_SUBCMD_EXECUTOR_DISPATCH='false'
#######################################################################

function _declare_constants() {
  declare -gr g_default_user='x9x'
  declare -gr g_radpctl="$HOME"/.local/radp/bin/radpctl
}

function _precheck() {
  radp_log_info "pre check..."
  if radp_os_check_user_exists "$g_default_user"; then
    if ! radp_os_check_if_is_sudoer "$g_default_user"; then
      radp_log_error "请给用户 '$g_default_user' 赋予 sudo 权限"
      return 1
    fi
  else
    radp_log_error "请像创建用户 '$g_default_user'"
    return 1
  fi

}

function _prepare_v2raya_proxy() {
  if ! command -v v2raya >/dev/null 2>&1; then
    if radp_io_prompt_continue --msg "install V2rayA, continue(y/N)" --default N --timeout 10; then
      radp_log_info "prepare proxy v2raya"
      GX_ENABLE_SUBCMD_EXECUTOR_DISPATCH='true'
      $g_radpctl omg -f install -n v2raya || return 1
      radp_log_warn "请访问 v2rayA 管理页面进行配置"
      radp_log_warn "配置完成后, 再重新执行一次 [yadm bootstrap]"
      return 1
    fi
  fi
}

function _prepare_epel() {
  local epel_release_url=https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  # 阿里云 ECS 默认并没有启用 epel-releases 源, 因此需要手动添加
  if ! dnf repolist | grep -q 'epel'; then
    radp_log_info "prepare epel"
    $g_sudo dnf install -y $epel_release_url || return 1
  fi
}

function _run_service() {
  # (portainer frps)
  local list=(portainer)
  local svr
  for svr in "${list[@]}"; do
    if radp_io_prompt_continue --msg "run service $svr, continue(y/N)" --default y --timeout 10; then
      "_run_service_${svr}"
    fi
  done
}

function _run_service_portainer() {
  # portainer
  if ! radp_docker_check_if_container_exists "portainer"; then
    radp_log_info "run portainer..."
    docker run -d --restart=always --name portainer -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer || return 1
  else
    radp_log_info "Container 'portainer' already exists."
  fi
  if ! radp_docker_check_if_container_exists "portainer_agent"; then
    radp_log_info "run portainer_agent"
    docker run -d --restart=always --name portainer_agent -p 9001:9001 -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent || return 1
  else
    radp_log_info "Container 'portainer_agent' already exists."
  fi
}

function _run_service_frps() {
  # frps
  local frps_dir="$HOME"/.config/frp/frps
  pushd "$frps_dir" || return 1
  docker compose up -d
}

#######################################################################
function main() {
  local cur_dir radp_root
  cur_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
  radp_root="$(cd "$cur_dir/../../../.local/radp" && pwd)"
  # shellcheck source=../../../.local/radp/framework/bootstrap.sh
  source "$radp_root"/framework/bootstrap.sh
  _declare_constants

  _precheck
  # default skip v2raya step
  _prepare_v2raya_proxy
  _prepare_epel

  # 这里必须启用, 否则子命令将会失效
  GX_ENABLE_SUBCMD_EXECUTOR_DISPATCH=true
  $g_radpctl omg -f bootstrap || return 1
  $g_radpctl cri -f install -n docker -u x9x || return 1

  _run_service
}

main "$@"

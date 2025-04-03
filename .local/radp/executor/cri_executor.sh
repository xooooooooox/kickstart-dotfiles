#!/usr/bin/env bash
set -e

# shellcheck source=./../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#----------------------------------------------- executor private method ----------------------------------------------#
function __configure_systemd_http_proxy() {
  local systemd_http_proxy_conf_file=${1:?}
  if [[ ${g_settings_assoc_plugin_proxy['enabled']} != 'true' ]]; then
    return 1
  fi
  local systemd_http_proxy_conf_dir
  systemd_http_proxy_conf_dir=$(dirname "$systemd_http_proxy_conf_file")
  [[ ! -d "$systemd_http_proxy_conf_dir" ]] && radp_utils_run "$g_sudo mkdir -p $systemd_http_proxy_conf_dir"
  if [[ -f "$g_default_custom_systemd_http_proxy_file" ]]; then
    radp_utils_run "$g_sudo cp -v $g_default_custom_systemd_http_proxy_file $systemd_http_proxy_conf_dir"
  else
    $g_sudo tee "$systemd_http_proxy_conf_file" <<-EOF
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:20171"
Environment="HTTPS_PROXY=http://127.0.0.1:20171"
Environment="NO_PROXY=localhost,127.0.0.1"
EOF
  fi
  # 更新 active proxy
  sudo sed -i "s|^Environment=\"HTTP_PROXY=.*\"|Environment=\"HTTP_PROXY=${gx_http_proxy}\"|g" "$systemd_http_proxy_conf_file"
  sudo sed -i "s|^Environment=\"HTTPS_PROXY=.*\"|Environment=\"HTTPS_PROXY=${gx_https_proxy}\"|g" "$systemd_http_proxy_conf_file"
  sudo sed -i "s|^Environment=\"NO_PROXY=.*\"|Environment=\"NO_PROXY=${gx_no_proxy}\"|g" "$systemd_http_proxy_conf_file"
}

function __configure_docker_daemon() {
  radp_log_info "configure docker daemon, e.g. mirrors"
  local docker_daemon_json_dir
  docker_daemon_json_dir=$(dirname "$g_default_docker_daemon_json_file")
  radp_utils_run "$g_sudo mkdir -p $docker_daemon_json_dir"
  radp_utils_run "$g_sudo cp -v $g_default_custom_docker_daemon_json_file $docker_daemon_json_dir"
}

function __uninstall_old_version_docker() {
  case $g_guest_distro_id in
    centos | rhel | fedora)
      radp_utils_run "$g_sudo yum remove -y docker docker-client docker-client-latest docker-latest docker-latest-logrotate docker-logrotate docker-engine"
      ;;
    ubuntu | debian | linuxmint)
      radp_utils_run "radp_alias_apt_get remove -y docker docker-engine docker.io containerd runc"
      ;;
    opensuse* | sles)
      radp_utils_run "$g_sudo zypper remove -y docker docker-engine docker.io containerd runc"
      ;;
    arch | manjaro)
      radp_utils_run "$g_sudo pacman -Rns --noconfirm docker docker-engine docker.io containerd runc"
      ;;
    alpine)
      radp_utils_run "$g_sudo apk del docker docker-engine docker.io containerd runc"
      ;;
    *)
      radp_log_error "Distribution $g_guest_distro_id is not supported for uninstallation of old Docker versions."
      return 1
      ;;
  esac
}

function __seup_docker_repository() {
  case "$g_guest_distro_id" in
    ubuntu | debian | linuxmint)
      radp_utils_run "radp_alias_apt_get update"
      radp_utils_run "radp_alias_apt_get install -y apt-transport-https ca-certificates curl software-properties-common"
      radp_utils_run "$g_sudo" curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      radp_utils_run "$g_sudo" add-apt-repository "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
      ;;
    centos | rhel | fedora)
      $g_sudo yum install -y yum-utils
      radp_utils_run "$g_sudo" yum-config-manager --add-repo "$g_default_docker_ce_yum_repo_url"
      ;;
    *)
      radp_log_error "Distribution $g_guest_distro_name is not supported yet."
      return 1
      ;;
  esac
}

function __install_docker_from_repository() {
  if command -v docker >/dev/null; then
    radp_log_info "Docker is already installed"
    return 0
  fi

  __uninstall_old_version_docker
  __seup_docker_repository
  case "$g_guest_distro_id" in
    ubuntu | debian | linuxmint)
      radp_utils_run "radp_alias_apt_get update"
      radp_utils_run "radp_alias_apt_get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin"
      ;;
    centos | rhel | fedora)
      radp_utils_retry "$g_sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" || return 1
      ;;
    opensuse* | sles)
      radp_utils_run "$g_sudo zypper install -y docker"
      ;;
    arch | manjaro)
      radp_utils_run "$g_sudo pacman -Sy --noconfirm docker"
      ;;
    alpine)
      radp_utils_run "$g_sudo apk add --no-cache docker"
      ;;
    *)
      return 1
      ;;
  esac
}

function __install_containerd_from_repository() {
  __seup_docker_repository
  case "$g_guest_distro_id" in
    ubuntu | debian | linuxmint)
      radp_utils_run "radp_alias_apt_get update"
      radp_utils_run "radp_alias_apt_get install -y containerd.io"
      ;;
    centos | rhel | fedora)
      radp_utils_retry "$g_sudo yum install -y containerd.io"
      ;;
    *)
      return 1
      ;;
  esac
}

function __configure_containerd_systemd_cgroup_driver() {
  radp_utils_run "$g_sudo bash -c 'containerd config default > /etc/containerd/config.toml'"
  radp_utils_run "$g_sudo sed -i 's|SystemdCgroup = false|SystemdCgroup = true|' /etc/containerd/config.toml"
}

function __install_docker_compose() {
  local version=${1:?}

  if ! command -v docker >/dev/null; then
    radp_log_info "install docker first"
    __install_docker_from_repository || return 1
  fi
  radp_utils_run "$g_sudo curl -L https://github.com/docker/compose/releases/download/v${version}/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose" || return 1
  radp_utils_run "$g_sudo chmod +x /usr/local/bin/docker-compose"
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#----------------------------------------------- supported cli function ------------------------------------------------
function cri_executor_install() {
  local cri=${1:?}
  local user=${2:-}
  local version=${3:-}
  case $cri in
    docker)
      cri_executor_acceleration "$cri"
      __install_docker_from_repository || return 1
      # 开机自启
      radp_utils_run "$g_sudo systemctl enable docker"
      # 启动
      radp_utils_run "$g_sudo systemctl start docker"
      # 让 $user 用户无需 root 即可运行 docker 命令
      cri_executor_rootless "$cri" "$user"
      ;;
    containerd)
      cri_executor_acceleration "$cri"
      __install_containerd_from_repository
      __configure_containerd_systemd_cgroup_driver
      radp_utils_run "$g_sudo systemctl restart containerd"
      radp_utils_run "$g_sudo systemctl enable containerd"
      ;;
    docker-compose)
      [[ -z "$version" ]] && version='2.30.3'
      __install_docker_compose "$version" || return 1
      ;;
    *)
      radp_log_error "Invalid cri $cri"
      return 1
      ;;
  esac
}

function cri_executor_uninstall() {
  local cri=${1:?}
  case $cri in
    docker)
      local pkg_manager _
      IFS=":" read -r _ _ _ pkg_manager < <(radp_os_get_distro_info)
      case $pkg_manager in
        yum)
          radp_utils_run "$g_sudo yum remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras"
          ;;
        apt-get)
          radp_utils_run "radp_alias_apt_get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras"
          ;;
        *)
          return 1
          ;;
      esac
      ;;
    containerd)
      local pkg_manager _
      IFS=":" read -r _ _ _ pkg_manager < <(radp_os_get_distro_info)
      case $pkg_manager in
        yum)
          radp_utils_run "$g_sudo yum remove -y containerd.io"
          ;;
        apt-get)
          radp_utils_run "radp_alias_apt_get purge containerd.io"
          ;;
        *)
          return 1
          ;;
      esac
      ;;
    *)
      return 1
      ;;
  esac
}

function cri_executor_reinstall() {
  local cri=${1:?}
  local user=${2:-}
  if command -v "$cri"; then
    cri_executor_uninstall "$cri"
  fi
  cri_executor_install "$cri" "$user"
}

function cri_executor_rootless() {
  local cri=${1:?}
  local user=${2:?}
  case $cri in
    docker)
      if ! command -v docker >/dev/null 2>&1; then
        radp_log_error "Docker Engine not installed"
        return 1
      fi
      # 如果没有 docker group, 则创建该 group
      if ! getent group docker >/dev/null; then
        radp_utils_run "$g_sudo groupadd docker"
      fi
      # 将用户添加到 docker group 中
      if ! getent group docker | grep -q "\b${user}\b"; then
        radp_utils_run "$g_sudo usermod -aG docker ${user}"
        radp_log_warn "Please log out and log back in or start a new shell session to apply group changes."
      fi
      # 验证
      if ! radp_utils_retry -- "$g_sudo -u $user docker run --rm hello-world" >/dev/null; then
        radp_log_error "Failed to make user $user has ability to run docker command without sudo"
        return 1
      fi
      ;;
    *)
      radp_log_error "Not support"
      return 1
      ;;
  esac
}

function cri_executor_acceleration() {
  local cri=${1:?}
  case $cri in
    docker)
      if ! __configure_systemd_http_proxy '/etc/systemd/system/docker.service.d/http-proxy.conf'; then
        __configure_docker_daemon
      fi
      ;;
    containerd)
      __configure_systemd_http_proxy '/etc/systemd/system/containerd.service.d/http-proxy.conf'
      ;;
    *)
      radp_log_error "Not supported $cri"
      return 1
      ;;
  esac
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#######################################
# 命令行参数具体处理函数
# 将对应的选项存储到关联数组中
#
# Arguments:
#  1 - __nr_cri_executor_parsed_args__: 存储解析后的参数
#######################################
function __cri_executor_options_processor() {
  local -n __nr_cri_executor_parsed_args__=$1
  shift
  local -a remaining_args
  radp_nr_cli_parse_common_options __nr_cri_executor_parsed_args__ remaining_args "$@"

  local idx=0
  while [[ idx -lt "${#remaining_args[@]}" ]]; do
    case "${remaining_args[idx]}" in
      -n | --name)
        __nr_cri_executor_parsed_args__['name']=${remaining_args[idx + 1]}
        ((idx += 2))
        ;;
      -u | --user)
        __nr_cri_executor_parsed_args__['user']=${remaining_args[idx + 1]}
        ((idx += 2))
        ;;
      -v | --version)
        __nr_cri_executor_parsed_args__['user']=${remaining_args[idx + 1]}
        ((idx += 2))
        ;;
      --)
        # 如果计算结果为0（即认为是 false），它会返回一个非零的退出状态
        # 可能会导致脚本立即终止，
        # || true，这样即使这个操作返回非零状态，也不会影响脚本继续执行
        ((idx++)) || true
        # 保存 -- 之后的参数
        __nr_cri_executor_parsed_args__['extended_args']="${remaining_args[*]:idx}"
        radp_log_debug "cli extended args: ${__nr_cri_executor_parsed_args__['extended_args']}"
        break
        ;;
      *)
        radp_log_error "Unknown option: ${remaining_args[idx]}. Try '-h' for more information"
        return 1
        ;;
    esac
  done
}

#######################################
# 命令行参数解析器
# Arguments:
#   @ - 所有命令行参数
#######################################
function __cri_executor_cli_parser() {
  # 声明命令行参数
  local short_opts="u:n:"
  local long_opts="user:,name:"
  local -A opts_desc
  opts_desc['name']='Specify cri, e.g. docker, containerd'
  opts_desc['user']='Linux 用户, default is 'x9x''
  # 获取命令行参数解析后的结果
  local -A parsed_args
  radp_nr_cli_parser -r parsed_args -o "$short_opts" -l "$long_opts" -d opts_desc -p "$(radp_cli_get_executor_options_processor_function_name)" -m "$(radp_cli_getexecutor_manual_file)" -- "$@"

  local cri=${parsed_args['name']}
  # 命令分发
  case "${parsed_args['function']}" in
    install)
      local user=${parsed_args['user']:-x9x}
      local version=${parsed_args['version']}
      cri_executor_install "$cri" "$user" "$version"
      ;;
    reinstall)
      local user=${parsed_args['user']:-x9x}
      cri_executor_reinstall "$cri" "$user"
      ;;
    uninstall)
      cri_executor_uninstall "$cri"
      ;;
    acceleration)
      cri_executor_acceleration "$cri"
      ;;
    rootless)
      local user=${parsed_args['user']:-x9x}
      cri_executor_rootless "$cri" "$user"
      ;;
    *)
      radp_cli_print_help_of_invalid_subcmd_function "${parsed_args['function']}" "${BASH_SOURCE[0]}"
      return 1
      ;;
  esac
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#######################################
# 声明当前 executor file 的全局常量
# 规范
# 示例: declare -gr g_executor_cri_default_yyy=default_value, 其中 xx 为 subcmd
# Arguments:
#  None
#######################################
function __declare_constants() {
  declare -gr g_default_docker_ce_yum_repo_url='https://download.docker.com/linux/centos/docker-ce.repo'
  declare -gr g_default_docker_daemon_json_file=/etc/docker/daemon.json
  declare -gr g_default_custom_docker_daemon_json_file="$g_user_extra_config_path"/docker/daemon.json
  declare -gr g_default_custom_systemd_http_proxy_file="$g_user_extra_config_path"/systemd/http-proxy.conf
}

#######################################
# 执行器主函数入口
# Arguments:
#  @ - 所有命令行参数
#######################################
function main() {
  # shellcheck source=./../framework/executor/executor.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../framework/executor/executor.sh
  __declare_constants
  __cri_executor_cli_parser "$@"
}

main "$@"

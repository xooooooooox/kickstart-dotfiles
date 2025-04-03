#!/usr/bin/env bash
# shellcheck source=./../../../../bootstrap.sh

#######################################
# 检测当前操作系统发行版，并尝试识别使用的包管理工具。
# 此函数主要读取 /etc/os-release 文件来获取发行版的名称和版本，
# 然后基于发行版名称推断包管理工具。
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   输出格式为 "发行版名称:发行版版本:包管理工具"
# Examples:
#   1) 获取完整信息
#      distro_info=$(radp_os_get_distro_info)
#      IFS=':' read -r distro_id distro_name distro_version pkg_manager <<< "$distro_info"
#   2) 如果仅关注 pkg_manager
#      IFS=':' read -r _ _ _ pkg_manager < <(radp_os_get_distro_info)
#######################################
function radp_os_get_distro_info() {
  local distro_id="unknown"
  local distro_name="unknown"
  local distro_version="unknown"
  local pkg_manager="unknown"

  if [[ "$OSTYPE" =~ ^darwin ]]; then
    # macOS 系统
    distro_id="osx"
    distro_name="osx"
    distro_version=$(sw_vers -productVersion)
    pkg_manager="brew" # macOS 常用 Homebrew 作为包管理器
  elif [[ -f /etc/os-release ]]; then
    # 读取 /etc/os-release 文件获取发行版信息
    . /etc/os-release
    distro_id="${ID:-unkownn}"
    distro_name="${NAME:-unknown}"
    distro_version="${VERSION_ID:-unknown}"

    # 基于发行版名称推断包管理工具
    case $distro_id in
      ubuntu | debian | linuxmint)
        pkg_manager="apt-get"
        ;;
      fedora)
        if [[ "$VERSION_ID" -ge 22 ]]; then
          pkg_manager="dnf"
        else
          pkg_manager="yum"
        fi
        ;;
      centos | rhel)
        if [[ "$VERSION_ID" -ge 9 ]]; then
          pkg_manager="dnf"
        else
          pkg_manager="yum"
        fi
        ;;
      arch | manjaro)
        pkg_manager="pacman"
        ;;
      opensuse* | sles)
        pkg_manager="zypper"
        ;;
      alpine)
        pkg_manager="apk"
        ;;
      *)
        pkg_manager="unknown"
        ;;
    esac
  fi

  #  radp_log_info "Detected distro info [id=$distro_id, name=$distro_name, version=$distro_version, pkg=$pkg_manager]"
  # 使用 ':' 作为分隔符输出结果
  echo "${distro_id}:${distro_name}:${distro_version}:${pkg_manager}"
}

#######################################
# 检查目录下是否有匹配的文件
# Arguments:
#   1 - dir_path: 目标目录
#   2 - name: 按照文件名进行查找
# Returns:
#   0 - 存在匹配的文件
#   1 - 没有匹配的文件
#   2 - 如果目标目录不存在
#######################################
function radp_os_check_if_file_exists_by_name() {
  local dir_path=${1:?}
  local name=${2:?}

  if [[ ! -e "$dir_path" ]]; then
    return 2
  fi

  local -a matched_files
  mapfile -t matched_files < <(find "$dir_path" -type f -name "$name")

  if [[ ${#matched_files} -gt 0 ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# 禁用 SELINUX (支持多种类型操作系统)
# Set SELinux to permissive mode
# Globals:
#   g_sudo
# Arguments:
#  None
#######################################
function radp_os_disable_selinux() {
  local distro_id _
  IFS=':' read -r distro_id _ _ _ < <(radp_os_get_distro_info)

  case "$distro_id" in
    centos | rhel | fedora | opensuse* | sles)
      if ! command -v sestatus >/dev/null; then
        radp_log_info "SEStatus command not found. Skipping SELinux status check."
        return 0
      fi

      # 获取当前 SELinux 状态
      local current_status
      current_status=$(getenforce)

      if [[ $current_status == "Disabled" ]]; then
        radp_log_info "SELinux is already disabled."
        return 0
      fi

      radp_log_info "Disabling SELinux..."
      if ! radp_utils_run "$g_sudo" setenforce 0; then
        radp_log_error "Failed to set SELinux into Permissive mode temporarily."
        return 1
      fi

      # 永久禁用 SELinux
      if ! radp_utils_run "$g_sudo" sed -i 's/SELINUX=\(enforcing\|permissive\)/SELINUX=disabled/g' /etc/selinux/config; then
        radp_log_error "Failed to disable SELinux permanently in /etc/selinux/config."
        return 1
      fi

      # 再次检查 SELinux 状态以确认更改
      current_status=$(getenforce)
      if [[ $current_status == "Permissive" || $current_status == "Disabled" ]]; then
        radp_log_info "SELinux has been successfully set to $current_status mode."
      else
        radp_log_error "Unexpected SELinux mode: $current_status. Please check system settings."
        return 1
      fi
      ;;
    *)
      radp_log_info "SELinux is not used or managed on this operating system: $distro_id"
      ;;
  esac
}

#######################################
# 禁用 firewalld (支持多种类型操作系统)
# Globals:
#   g_sudo
# Arguments:
#  None
#######################################
function radp_os_disable_firewalld() {
  local distro_id _
  IFS=':' read -r distro_id _ _ _ < <(radp_os_get_distro_info)

  case "$distro_id" in
    ubuntu | debian | linuxmint)
      if ! command -v ufw >/dev/null; then
        radp_log_info "Skipped disable ufw, not installed."
        return 0
      fi
      if $g_sudo ufw status | grep -q "Status: active"; then
        radp_log_info "Disabling ufw"
        radp_utils_run "sudo systemctl disable --now ufw" || {
          radp_log_error "Failed to disable ufw"
          return 1
        }
        if $g_sudo ufw status | grep -q "Status: active"; then
          radp_log_error "Failed to disable ufw"
          return 1
        fi
        radp_log_info "ufw disabled"
      fi
      ;;
    centos | rhel | fedora)
      if ! command -v firewalld >/dev/null; then
        radp_log_info "Skipped disable firewalld, not installed."
        return 0
      fi
      if systemctl status firewalld >/dev/null 2>&1; then
        radp_log_info "Stopping firewalld"
        radp_utils_run "$g_sudo systemctl stop firewalld" || {
          radp_log_error "Failed to stop firewalld"
          return 1
        }
        radp_log_info "Disabling firewalld permanently"
        radp_utils_run "$g_sudo systemctl disable firewalld" || {
          radp_log_error "Failed to disable firewalld"
          return 1
        }
        if systemctl status firewalld >/dev/null 2>&1; then
          radp_log_error "Failed to disable firewalld"
          return 1
        fi
        radp_log_info "Firewalld disabled permanently"
      fi
      ;;
    alpine)
      radp_log_info "No firewalld or ufw to disable on Alpine Linux."
      ;;
    osx)
      radp_log_info "Skip disable firewall on osx."
      ;;
    *)
      radp_log_error "Unsupported operating system: $distro_id"
      return 1
      ;;
  esac
}

#######################################
# 禁用 swap
# Disable and turn off SWAP
# Globals:
#   g_sudo
# Arguments:
#  None
#######################################
function radp_os_disable_swap() {
  if ! command -v swapoff >/dev/null 2>&1; then
    radp_log_error "Swapoff command not found. Unable to disable swap."
    return 1
  fi

  if ! grep -q 'partition' /proc/swaps; then
    radp_log_info "Swap is already disabled."
    return 0
  else
    radp_log_info "Disabling swap immediately..."
    if ! radp_utils_run "$g_sudo swapoff -a"; then
      radp_log_error "Failed to disable swap immediately."
      return 1
    fi
  fi

  local distro_id _
  IFS=':' read -r distro_id _ _ _ < <(radp_os_get_distro_info)
  case "$distro_id" in
    ubuntu | debian | linuxmint | centos | rhel | fedora | opensuse* | sles | arch | manjaro | alpine)
      if [[ ! -f /etc/fstab ]]; then
        radp_log_error "/etc/fstab file not found."
        return 1
      fi

      if grep -q swap /etc/fstab; then
        radp_log_info "Disabling swap permanently by modifying /etc/fstab..."

        # 注释掉所有非注释的 swap 行
        if ! radp_utils_run "$g_sudo" sed -i '/^[^#].*\bswap\b/s/^/#/' /etc/fstab; then
          radp_log_error "Failed to permanently disable swap in /etc/fstab."
          return 1
        fi
      else
        radp_log_info "Swap is already disabled permanently in /etc/fstab."
      fi
      ;;
    osx)
      radp_log_info "macOS does not use /etc/fstab for swap management. No action needed."
      ;;
    *)
      radp_log_error "Unsupported operating system: $distro_id. Unable to disable swap."
      return 1
      ;;
  esac

  radp_log_info "Swap has been successfully disabled."
}

#######################################
# 检查 sysctl param 设置的值是否符合预期
# Arguments:
#   1 - param: sysctl param
#   2 - expected: 期望的值
# Returns:
#   1 - 不满足返回 1
#   0 - 满足返回 0
#######################################
function radp_os_sysctl_param_check() {
  # 定义一个函数来检查参数是否正确设置
  local param=${1:?}
  local expected=${2:?}
  local value
  value=$(sysctl "$param" | awk '{print $3}')
  if [[ "$value" -ne $expected ]]; then
    radp_log_error "Sysctl param $param is set to $value, expected $expected"
    return 1
  fi
}

#######################################
# 获取指定文件或目录的绝对路径，包括处理符号链接的情况。
# 如果目标是一个目录，返回该目录的绝对路径；
# 如果目标是一个文件，返回包含文件名的完整绝对路径。
# 如果没有提供参数，则默认尝试获取调用该函数的脚本的路径。
# 注意：假定该函数被定义在库文件中，并通过 source 方式被其他脚本引用。
#
# Globals:
#   BASH_SOURCE - Bash 内置数组变量，其中包含当前执行脚本或函数库的路径。
# Arguments:
#   1 - target: 可选. 要获取绝对路径的目标文件或目录。如果未指定，使用调用该函数的脚本路径。
# Outputs:
#   向 stdout 输出目标的绝对路径。
# Returns:
#   None
# Examples:
#   获取当前脚本的绝对路径:
#     script_path=$(radp_os_get_absolute_path)
#     echo "Script absolute path: $script_path"
#
#   获取指定目录的绝对路径:
#     dir_path=$(radp_os_get_absolute_path "/some/directory")
#     echo "Directory absolute path: $dir_path"
#
#   获取指定文件的绝对路径:
#     file_path=$(radp_os_get_absolute_path "/some/directory/file.txt")
#     echo "File absolute path: $file_path"
#######################################
function radp_os_get_absolute_path() {
  local target="${1:-${BASH_SOURCE[1]}}"

  # 解析符号链接
  while [[ -L "$target" ]]; do
    target=$(readlink "$target")
  done

  # 获取绝对路径
  if [[ -d "$target" ]]; then
    # 目标是一个目录
    # shellcheck disable=SC2005
    echo "$(cd "$target" && pwd)"
  else
    # 目标是一个文件
    echo "$(cd "$(dirname "$target")" && pwd)/$(basename "$target")"
  fi
}

#######################################
# 检查系统 CPU 核心数是否满足最小要求。
#
# Globals:
#   None
# Arguments:
#   $1 - 最小 CPU 核心数要求。
# Outputs:
#   如果不满足要求，向 stderr 输出警告信息。
# Returns:
#   0 - 如果满足最小 CPU 核心数要求。
#   1 - 如果不满足最小 CPU 核心数要求。
#######################################
function radp_os_check_minimum_cpu_cores() {
  local expected_min_cores="$1"
  local actual_cores
  actual_cores=$(grep -c ^processor /proc/cpuinfo)

  if [[ "$actual_cores" -lt "$expected_min_cores" ]]; then
    radp_log_error "Your system does not meet the minimum CPU cores requirement. Required: $expected_min_cores, Available: $actual_cores"
    return 1
  else
    return 0
  fi
}

#######################################
# 检查系统 RAM 大小是否满足最小要求。
#
# Globals:
#   None
#
# Arguments:
#   $1 - 最小 RAM 要求 (单位: MB)。
# Outputs:
#   如果不满足要求，向 stderr 输出警告信息。
# Returns:
#   0 - 如果满足最小 RAM 要求。
#   1 - 如果不满足最小 RAM 要求。
#######################################
function radp_os_check_minimum_ram() {
  local expected_min_ram_input="$1"
  local expected_min_ram_mb
  if [[ "$expected_min_ram_input" =~ ([0-9]+)GB$ ]]; then
    expected_min_ram_mb=$(("${BASH_REMATCH[1]}" * 1024))
  elif [[ "$min_ram_input" =~ ([0-9]+)MB$ ]]; then
    expected_min_ram_mb=${BASH_REMATCH[1]}
  else
    radp_log_error "Invalid RAM requirement format. Please specify in 'GB' or 'MB' (e.g., '2GB' or '2048MB')." >&2
    return 1
  fi

  local actual_ram_kb actual_ram_mb
  actual_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  actual_ram_mb=$((actual_ram_kb / 1024))

  if [[ "$actual_ram_mb" -lt "$expected_min_ram_mb" ]]; then
    radp_log_error "Your system does not meet the minimum RAM requirement. Required: ${expected_min_ram_mb}MB, Available: ${actual_ram_mb}MB"
    return 1
  else
    return 0
  fi
}

#######################################
# 检查 Linux 用户是否存在
# Arguments:
#   1 - user
# Returns:
#   1 - 如果不存在，则返回 1
#######################################
function radp_os_check_user_exists() {
  local user=${1:?}
  if ! id -u "$user" >/dev/null 2>&1; then
    radp_log_error "User '${user}' not exist"
    return 1
  fi
}

#######################################
# 重置 linux 用户密码
# 如果在重置密码时，未指定新密码，将会使用生成的随机密码
# Globals:
#   g_sudo
# Arguments:
#   1 - user: 必须
#   2 - new_password: 必须
# Returns:
#   1 - 如果重置失败
#######################################
function radp_os_reset_linux_password() {
  local user=${1:?}
  local new_password=${2:-}
  radp_os_check_user_exists "$user" || return 1

  # 如果是密码文件
  [[ -f "$new_password" ]] && new_password=$(cat "$new_password")

  # 如果密码为空则生成一个新的密码
  if [[ -z "$new_password" ]]; then
    new_password=$(radp_utils_get_strong_random_password) || return 1
  fi

  radp_log_info "Resetting password for user $user"
  if ! echo "$user:$new_password" | $g_sudo chpasswd; then
    radp_log_error "Failed to reset password for user $user"
    return 1
  fi

  echo "$new_password"
}

#######################################
# 获取指定用户的 ssh_home
# Arguments:
#   1 - user: 必须
#######################################
function radp_os_get_ssh_home() {
  local user=${1:?}
  local s_ssh_home
  radp_os_check_user_exists "$user" || return 1
  if [[ $user != 'root' ]]; then
    s_ssh_home=/home/$user/.ssh
  else
    s_ssh_home=/root/.ssh
  fi
  echo "$s_ssh_home"
}

#######################################
# 判断SSH 是否启用了密码登录功能
# Globals:
#   g_sudo
# Arguments:
#  None
# Returns:
#   0 - 如果启用了则返回 0
#   1 - 如果没有启用则返回 1
#######################################
function radp_os_check_if_ssh_password_auth() {
  if $g_sudo grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config; then
    return 1
  else
    return 0
  fi
}

#######################################
# 开启指定用户的无密码 sudo 权限。
# 如果用户已经具备 sudo 权限，则直接返回成功。
# 非 root 用户运行时会提示错误并要求以 root 用户执行。
# 函数会检查用户是否属于 wheel 组，如果不是，则添加用户至该组，并修改 sudoers 文件允许该组无密码 sudo。
# 检验是否成功设置无密码 sudo 权限。
# Globals:
#   None
# Arguments:
#   user - 要开启无密码 sudo 权限的用户名。
# Returns:
#   0 - 成功开启无密码 sudo 权限。
#   1 - 失败，包括非 root 用户执行或无法修改 sudoers 文件等情况。
#######################################
function radp_os_enable_sudo_without_password() {
  local user=${1:?}

  # 当前用户已经具备 sudo
  if sudo -n true >/dev/null 2>&1; then
    return 0
  fi

  # 检查脚本是否以 root 权限运行
  if [[ $(id -u) -ne 0 ]]; then
    radp_log_error "要给 $user 开启 sudo 权限，请先以 root 用户运行当前脚本, 后续便可直接使用 $user 直接运行脚本."
    return 1
  fi

  # 创建 sudoers 文件
  local user_sudo_file="/etc/sudoers.d/$user"
  radp_io_append_single_line_to_file "$user_sudo_file" "$user ALL=(ALL) NOPASSWD: ALL"
  radp_utils_run "chmod 0440 $user" || return 1

  if ! su - "$user" -c 'sudo -n true' >/dev/null 2>&1; then
    radp_log_error "无法给 $user 提权，请手工提权"
    return 1
  fi
}

function radp_os_check_bash_version() {
  local required_version=${1:?}
  local required_major=${required_version%%.*}
  local required_minor=${required_version#*.}

  # 检查 Bash 版本是否符合要求
  if ! ((BASH_VERSINFO[0] > required_major || (BASH_VERSINFO[0] == required_major && BASH_VERSINFO[1] >= required_minor))); then
    radp_log_warn "Required Bash version $required_major.$required_minor or higher. Current version: $BASH_VERSION"
    return 1
  fi

  return 0
}

# 此函数用于创建或更新指定用户的crontab任务
# 参数:
#   $1: 用户名 (必需)
#   $2: crontab内容或文件路径 (必需)
#
# 功能:
#   1. 读取现有crontab任务
#   2. 从文件或直接内容中读取新的任务
#   3. 将新任务与现有任务合并
#   4. 更新用户的crontab
#
# 示例用法:
#   radp_os_create_or_update_crontab "vagrant" "/path/to/crontab_content.txt"
#
function radp_os_create_or_update_crontab() {
  local cron_user=${1:?}
  local content_or_path=${2:?}

  local crontab_current
  crontab_current=$(sudo crontab -u "${cron_user}" -l 2>/dev/null | grep -Ev '^#|^$' || true) # Existing tasks, ignore errors if no crontab set

  local new_tasks
  if [[ -f "${content_or_path}" ]]; then
    # It's a file, read tasks filtering out empty lines and comments
    new_tasks=$(grep -Ev '^#|^$' "${content_or_path}")
  else
    # Assume it's direct content
    new_tasks=$(echo "${content_or_path}" | grep -Ev '^#|^$')
  fi

  local crontab_updated="${crontab_current}"
  local updated="false"
  while read -r line; do
    if [[ -n "${line}" ]] && ! echo "${crontab_current}" | grep -Fq "${line}"; then
      # New task, add it
      crontab_updated+=$'\n'"${line}"
      updated="true"
    fi
  done <<<"${new_tasks}"

  if [[ "${updated}" == "true" ]]; then
    # Write updated crontab to a temporary file
    local tmpfile
    tmpfile=$(mktemp)
    echo "${crontab_updated}" >"${tmpfile}"
    sudo crontab -u "${cron_user}" "${tmpfile}"
    rm "${tmpfile}"
    radp_log_info "Crontab updated for user '${cron_user}'."
    $g_sudo crontab -u vagrant -l
  else
    radp_log_info "No update required for the crontab of user '${cron_user}'."
  fi
}

function radp_os_check_if_is_sudoer() {
  local user=${1:?}
  local sudo_file=/etc/sudoers.d/$user
  if $g_sudo su - "${user}" -c 'sudo -n true' >/dev/null 2>&1 || $g_sudo test -f "$sudo_file"; then
    return 0
  else
    return 1
  fi
}

function radp_os_add_sudoer() {
  local user=${1:?}
  if ! radp_os_check_user_exists "$user"; then
    return 1
  fi
  local sudo_file=/etc/sudoers.d/$user
  if $g_sudo su - "${user}" -c 'sudo -n true' >/dev/null 2>&1 || $g_sudo test -f "$sudo_file"; then
    return 0
  fi
  radp_utils_run "$g_sudo touch $sudo_file"
  radp_io_append_single_line_to_file "$sudo_file" "$user ALL=(ALL) NOPASSWD: ALL"
  radp_utils_run "$g_sudo chmod 440 $sudo_file"
}

function radp_os_chsh_for_user() {
  local user=${1:?}
  local choice1=${2:?}
  local choice2=${3:?}

  local shell_to_use
  if [[ -f $choice1 ]]; then
    shell_to_use=$choice1
  elif [[ -f $choice2 ]]; then
    shell_to_use=$choice2
  else
    radp_log_warn "No available shell found"
    return 1
  fi

  radp_utils_run "$g_sudo usermod -s $shell_to_use $user" || {
    radp_log_error "Failed to change ${user}'s default shell to $shell_to_use"
    return 1
  }
}

function radp_os_append_path() {
  local shells=${1:?}
  local content="$2"
  local -a arr
  IFS=' ' read -ra arr <<<"$shells"
  local shell env_file
  for shell in "${arr[@]}"; do
    case $shell in
      bash)
        env_file="$HOME/.bashrc"
        ;;
      zsh)
        env_file="$HOME/.zshrc"
        ;;
    esac
    if [[ -f "$env_file" ]]; then
      radp_io_append_single_line_to_file "$env_file" "$content"
    fi
  done
}

function radp_os_pkg_install() {
  # type1:pkg1,pkg2,pkg3;type2:pkg_a,pkg_b
  # e.g. yum:nfs-utils,wget;ubuntu,wget
  local use_custom_format=false
  local update_before_install=false
  local packages=()

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --update)
        update_before_install=true
        shift
        ;;
      --format)
        use_custom_format=true
        shift
        ;;
      --)
        shift
        break
        ;;
      *)
        packages+=("$1")
        shift
        ;;
    esac
  done

  #  local pkg_manager _
  #  IFS=':' read -r _ _ _ pkg_manager < <(radp_os_get_distro_info)
  local final_packages=()

  if [[ $use_custom_format == true ]]; then
    local arg
    for arg in "${packages[@]}"; do
      local type_pairs
      IFS=';' read -ra type_pairs <<<"$arg"
      local type_pair type_name pkgs
      for type_pair in "${type_pairs[@]}"; do
        IFS=':' read -r type_name pkgs <<<"$type_pair"
        case "$g_guest_distro_pkg" in
          yum)
            if [[ "$type_name" == "yum" ]]; then
              local pkg_array
              IFS=',' read -ra pkg_array <<<"$pkgs"
              final_packages+=("${pkg_array[@]}")
            fi
            ;;
          apt)
            if [[ "$type_name" == "apt" ]]; then
              IFS=',' read -ra pkg_array <<<"$pkgs"
              final_packages+=("${pkg_array[@]}")
            fi
            ;;
          apt-get)
            if [[ "$type_name" == "apt" ]]; then
              IFS=',' read -ra pkg_array <<<"$pkgs"
              final_packages+=("${pkg_array[@]}")
            fi
            ;;
          brew)
            if [[ "$type_name" == "brew" ]]; then
              IFS=',' read -ra pkg_array <<<"$pkgs"
              final_packages+=("${pkg_array[@]}")
            fi
            ;;
          *)
            radp_log_error "Invalid pkg_manager"
            return 1
            ;;
        esac
      done
    done
  else
    final_packages=("${packages[@]}")
  fi

  if [[ ${#final_packages} -eq 0 ]]; then
    radp_log_error "Undefined package for $g_guest_distro_pkg"
    return 1
  fi

  case $g_guest_distro_pkg in
    yum)
      [[ "$update_before_install" == true ]] && $g_sudo yum update
      $g_sudo yum install -y "${final_packages[@]}"
      ;;
    apt)
      [[ "$update_before_install" == true ]] && $g_sudo apt update
      $g_sudo apt install "${final_packages[@]}"
      ;;
    apt-get)
      [[ "$update_before_install" == true ]] && radp_alias_apt_get update
      radp_alias_apt_get install -y "${final_packages[@]}"
      ;;
    brew)
      [[ "$update_before_install" == true ]] && $g_sudo brew update
      brew install "${final_packages[@]}" || return 1
      ;;
    dnf)
      [[ "$update_before_install" == true ]] && $g_sudo dnf update
      $g_sudo dnf install -y "${final_packages[@]}"
      ;;
    *)
      radp_log_error "Invalid pkg_manager"
      return 1
      ;;
  esac
}

#!/usr/bin/env bash

# shellcheck source=./../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#----------------------------------------------- executor private method ----------------------------------------------#
function __example_private_method() {
  :
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#----------------------------------------------- supported cli function ------------------------------------------------
function omg_executor_install() {
  local name=${1:?"Miss -n|--name option"}
  local version=${2:-}
  local cmd=radp_omg_${name//-/_}_install
  if command -v "$cmd" >/dev/null 2>&1; then
    radp_log_info "Installing $name $version"
    ${cmd} "$version" || {
      radp_log_error "Failed to install '$name'"
      return 1
    }
  else
    radp_log_error "Not support install '$name', because method '$cmd' not found, "
    return 1
  fi
}

function omg_executor_bootstrap() {
  local -n __nr_executor_bootstrap_input__=${1:?}
  shift
  local -a install_order=("$@")

  radp_lang_check_var_type __nr_executor_bootstrap_input__ -A
  local -a installed_list
  if [[ ${#install_order[@]} -eq 0 ]]; then
    # 无需安装
    local k
    for k in "${!__nr_executor_bootstrap_input__[@]}"; do
      omg_executor_install "$k" "${__nr_executor_bootstrap_input__[$k]}" || {
        radp_log_error "Already installed [${installed_list[*]}], expected [${!__nr_executor_bootstrap_input__[*]}]"
        return 1
      }
      installed_list+=("$k")
    done
  else
    # 有序安装
    radp_log_info "Installing with order [${install_order[*]}]..."
    local i
    for i in "${!install_order[@]}"; do
      local key=${install_order[$i]}
      omg_executor_install "$key" "${__nr_executor_bootstrap_input__["$key"]}" || {
        radp_log_error "Already installed [${installed_list[*]}], expected [${install_order[*]}]"
        return 1
      }
      installed_list+=("$key")
    done
    radp_log_info "All have been installed [${install_order[*]}]"
  fi
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#######################################
# 命令行参数具体处理函数
# 将对应的选项存储到关联数组中
#
# Arguments:
#  1 - __nr_omg_executor_parsed_args__: 存储解析后的参数
#######################################
function __omg_executor_options_processor() {
  local -n __nr_omg_executor_parsed_args__=$1
  shift
  local -a remaining_args
  radp_nr_cli_parse_common_options __nr_omg_executor_parsed_args__ remaining_args "$@"

  local idx=0
  while [[ idx -lt "${#remaining_args[@]}" ]]; do
    case "${remaining_args[idx]}" in
      -n | --name)
        __nr_omg_executor_parsed_args__['name']=${remaining_args[idx + 1]}
        ((idx += 2))
        ;;
      -v | --version)
        __nr_omg_executor_parsed_args__['version']=${remaining_args[idx + 1]}
        ((idx += 2))
        ;;
      --)
        # 如果计算结果为0（即认为是 false），它会返回一个非零的退出状态
        # 可能会导致脚本立即终止，
        # || true，这样即使这个操作返回非零状态，也不会影响脚本继续执行
        ((idx++)) || true
        # 保存 -- 之后的参数
        __nr_omg_executor_parsed_args__['extended_args']="${remaining_args[*]:idx}"
        radp_log_debug "cli extended args: ${__nr_omg_executor_parsed_args__['extended_args']}"
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
function __omg_executor_cli_parser() {
  # 声明命令行参数
  local short_opts="n:v:"
  local long_opts="name:,version:"
  local -A opts_desc
  opts_desc['name']='The name of package'
  opts_desc['version']="The version of package to install"
  # 获取命令行参数解析后的结果
  local -A parsed_args
  radp_nr_cli_parser -r parsed_args -o "$short_opts" -l "$long_opts" -d opts_desc -p "$(radp_cli_get_executor_options_processor_function_name)" -m "$(radp_cli_getexecutor_manual_file)" -- "$@"

  # 命令分发
  case "${parsed_args['function']}" in
    install)
      omg_executor_install "${parsed_args['name']}" "${parsed_args['version']}"
      ;;
    bootstrap)
      # 由于 bash 关联数组, 在遍历时, 是无法保证其遍历顺序与声明时一致的
      # 所以这里需要一个 order 辅助数组去保证安装顺序
      local -a osx_install_order=(homebrew gnu-getopt vagrant kubectl helm kubecm telepresence mc bat fastfetch vfox ruby jdk)
      local -A osx_install_map=(
        ['homebrew']='latest'
        ['gnu-getopt']='latest'
        ['vagrant']='latest'
        ['kubectl']='latest'
        ['helm']='latest'
        ['kubecm']='latest'
        ['telepresence']='2.17.0'
        ['mc']='latest'
        ['bat']='latest'
        ['fastfetch']='latest'
        ['vfox']='latest'
        ['ruby']='3.1.2'
        ['jdk']='8'
      )
      local -a linux_install_order=(ruby openjdk)
      local -A linux_install_map=(
        ['openjdk']='8'
        ['ruby']='3.1.2'
      )
      local -a general_install_order=(tmux vim gpg git-credential-manager nodejs zoxide fzf colorls markdownlint-cli fd neovim jq)
      local -A general_install_map=(
        ['tmux']='3.4'
        ['vim']='latest'
        ['gpg']='latest'
        ['git-credential-manager']='2.5.1'
        ['nodejs']='18.20.5'
        ['zoxide']='latest'
        ['fzf']='0.55.0'
        ['colorls']='latest'
        ['markdownlint-cli']='latest'
        ['fd']='10.2.0'
        ['neovim']='0.10.1'
        ['jq']='latest'
      )

      case "$g_guest_distro_pkg" in
        brew)
          local -A merged_result
          radp_nr_merge_map merged_result general_install_map osx_install_map
          osx_install_order+=("${general_install_order[@]}")
          omg_executor_bootstrap merged_result "${osx_install_order[@]}" || return 1
          ;;
        dnf | yum)
          local -A merged_result
          radp_nr_merge_map merged_result general_install_map linux_install_map
          linux_install_order+=("${general_install_order[@]}")
          omg_executor_bootstrap merged_result "${linux_install_order[@]}" || return 1
          ;;
        apt-get)
          local -A merged_result
          radp_nr_merge_map merged_result general_install_map linux_install_map
          linux_install_order+=("${general_install_order[@]}")
          omg_executor_bootstrap general_install_map "${linux_install_order[@]}" || return 1
          ;;
        *)
          radp_log_error "Not support boostrap dotfiles on '$g_guest_distro_pkg'"
          return 1
          ;;
      esac
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
# 示例: declare -gr g_executor_omg_default_yyy=default_value, 其中 xx 为 subcmd
# Arguments:
#  None
#######################################
function __declare_constants() {
  # Linux 三方包默认安装在这里
  #declare -gr g_omg_install_root=/opt/third
  :
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
  __omg_executor_cli_parser "$@"
}

main "$@"

#!/usr/bin/env bash

# shellcheck source=./../bootstrap.sh
########################################################################################################################

#######################################
# 构建分发包。
#
# Global:
#   None
# Arguments:
#   1 - src_path:  必须.待构建的源代码目录，默认够简单是
#   2 - dist_file: 必须. 构建后的构件文件路径
# Returns:
#   0 - 成功创建构件包返回 0，
#   1 - 目标目录不存在或者打包失败，则返回 1
# Examples:
#   构建框架分发包，并将其保存到指定的分发路径：
#   ```
#   framework_executor_build "/path/to/dist"
#   ```
#
# Notes:
#   - 该函数在执行 tar 命令前会尝试切换到框架根目录的父目录，
#     确保打包的 tar 文件包含框架目录本身而非其内容。
#   - 成功执行后会在指定的分发路径下创建一个 tar.gz 文件，文件名由全局变量 g_framework_dist_filename 指定。
#######################################
function framework_executor_build() {
  local src_path=${1:?"Error: miss -s option"}
  local dist_file=${2:?"Error: miss -d or -D option"}

  if [[ ! -d "$src_path" ]]; then
    radp_log_error "src_path '$src_path' does not existed or not a directory"
    return 1
  fi

  (
    radp_log_info "Building from ${src_path}/* to dist file $dist_file"
    pushd "$src_path" || return 1
    local dist_path
    dist_path=$(dirname "$dist_file")
    [[ ! -d "$dist_path" ]] && radp_utils_run mkdir -p "$dist_path"
    if [[ -f "$g_tarignore_file" ]]; then
      radp_utils_run tar -czf "$dist_file" -X "$g_tarignore_file" .
    else
      radp_utils_run tar -czf "$dist_file" .
    fi
    popd || return 1
  ) || {
    radp_log_error "Failed to build $dist_file from $src_path"
    return 1
  }
}

#######################################
# 上传构件到 nexus raw-hosted repository
# Globals:
#   g_cli_subcmd_executor_mapper
# Arguments:
#   1 - nexus_user: 必须
#   2 - nexus_password: 必须
#   3 - nexus_url: 必须，指定远程nexus地址
#   4 - upload_file: 可选，指定构件所在路径，若为指定，则在上传前先在临时目录进行自动构建
# Returns:
#   1 - 如果上传失败或者自动构建失败，返回 1
#   0 - 如果成功上传到 nexus，则返回 0
#######################################
function framework_executor_deploy() {
  local nexus_user=${1:?"Error: miss -u option"}
  local nexus_password=${2:?"Error: miss -u option"}
  local nexus_url=${3:?"Error: miss -n or -N option"}
  local src_path=${4:?"Error: miss -s option"}
  local upload_file=${5:-}

  # 如果未指定构件路径，则先构建再自动上传
  if [[ -z "$upload_file" || ! -f "$upload_file" ]]; then
    local tmpdir
    tmpdir=$(mktemp -d)
    upload_file=${upload_file:-"$tmpdir"/archive.tar.gz}
    src_path=$(cd "$src_path" && pwd)
    ${g_cli_subcmd_executor_mapper['framework']} -f build -s "$src_path" -d "$upload_file" || {
      return 1
    }
  fi

  ${g_cli_subcmd_executor_mapper['nexus']} -f upload -u "$nexus_user" -p "$nexus_password" -T "$upload_file" -n "$nexus_url" || {
    return 1
  }

  # 清理工作
  if [[ -d "$tmpdir" ]]; then
    radp_utils_run rm -r "${tmpdir}" || {
      radp_log_error "Failed to remove tmpdir '$tmpdir'"
      return 1
    }
  fi
}

#######################################
# 下载构件到本地
# Globals:
#   g_cli_subcmd_executor_mapper
# Arguments:
#   1 - nexus_user: 必须.nexus user
#   2 - nexus_password: 必须. nexus password
#   3 - nexus_url: 必须.远程下载地址
#   4 - download_to_pwd: 必须. 是否下载到当前工作目录
#   5 - download_to_path: 必须.本地下载路径
# Returns:
#   1 - 下载失败
#######################################
function framework_executor_download() {
  local nexus_user=${1:?}
  local nexus_password=${2:?}
  local nexus_url=${3:?}
  local download_to_pwd=${4:?}
  local download_to_path=${5:-}

  if [[ "$download_to_pwd" == true ]]; then
    ${g_cli_subcmd_executor_mapper['nexus']} -f download -u "$nexus_user" -p "$nexus_password" -n "$nexus_url" -O || {
      return 1
    }
  else
    ${g_cli_subcmd_executor_mapper['nexus']} -f download -u "$nexus_user" -p "$nexus_password" -n "$nexus_url" -o "$download_to_path" || {
      return 1
    }
  fi

}

######################################
# 重置本地当前框架脚本
# 从远程自动下载当前框架版本的构建包，并覆盖本地的版本
# Globals:
#   g_framework_root
# Arguments:
#   1 - user: nexus user
#   2 - password: nexus password
#   3 - url: nexus download url
#######################################
function framework_executor_reset() {
  local user=${1:?}
  local password=${2:?}
  local url=${3:?}
  local tmpdir reset_to_path
  reset_to_path=${g_framework_root}
  tmpdir=$(mktemp -d)

  # backup
  if [[ -d "$reset_to_path" ]]; then
    local backup_file backup_dir
    backup_dir=$(dirname "$g_framework_root")/backup && radp_utils_run mkdir -p "$backup_dir"
    backup_file=${backup_dir}/${g_framework_dist_filename}.backup_$(date +%Y_%m_%d_%s)
    radp_log_info "Backup old framework $g_framework_root to $backup_file"
    radp_utils_run tar -czf "$backup_file" -C "$g_framework_root" .
  else
    radp_utils_run mkdir -p "$reset_to_path"
  fi

  pushd "${tmpdir}" >/dev/null 2>&1 || return 1 # 临时切换到临时目录
  # download
  ${g_cli_subcmd_executor_mapper['nexus']} -f download -u "$user" -p "$password" -n "$url" -O || {
    return 1
  }
  # extract
  if radp_utils_run "tar -xzf * -C $reset_to_path 2>/dev/null"; then
    radp_log_info "Success to reset radp bash framework"
  else
    radp_log_error "Failed to reset radp bash framework"
    return 1
  fi
  # clean
  radp_utils_run "rm -v *.tar.gz" || radp_log_warn "Failed to remove temp files $(ls -l "$tmpdir")"
  popd >/dev/null 2>&1 || return 1 # 切换回 pushd 前的工作目录
}

#######################################
# 直接调用 radp_xxx 库函数
# Arguments:
#  None
# Returns:
#   1...n - cmds: 要执行的库函数及其参数列表
#######################################
function framework_executor_call() {
  local cmds=("$@")
  local call_whitelist
  mapfile -t call_whitelist < <(compgen -A function | grep '^radp_')
  local fun_to_call=${cmds[0]}
  if radp_lang_check_if_arr_contains "$fun_to_call" "${call_whitelist[@]}"; then
    "${cmds[@]}"
  else
    radp_log_error "Failed to call '$fun_to_call', available list =>\n ${call_whitelist[*]}"
    return 1
  fi
}

#----------------------------------------------------------------------------------------------------------------------=

#######################################
# 命令行参数具体处理函数
# @see radp_cli_nr_getopt_parser
# Arguments:
#  1 - __nr_framework_executor_parsed_args__: 存储解析后的参数
#######################################
#function __framework_executor_process_opts() {
function __framework_executor_options_processor() {
  local -n __nr_framework_executor_parsed_args__=$1
  shift
  local -a remaining_args
  radp_nr_cli_parse_common_options __nr_framework_executor_parsed_args__ remaining_args "$@"

  local idx=0
  while [[ idx -lt ${#remaining_args[@]} ]]; do
    case "${remaining_args[idx]}" in
      -d | --dist-file)
        __nr_framework_executor_parsed_args__['dist-file']="${remaining_args[idx + 1]}"
        ((idx += 2))
        ;;
      -D | --dist-path)
        __nr_framework_executor_parsed_args__['dist-path']="${remaining_args[idx + 1]}"
        __nr_framework_executor_parsed_args__['dist-file']="${remaining_args[idx + 1]}"/${g_framework_dist_filename}
        ((idx += 2))
        ;;
      -T | --upload-file)
        __nr_framework_executor_parsed_args__['upload-file']="${remaining_args[idx + 1]}"
        ((idx += 2))
        ;;
      -u | --user)
        __nr_framework_executor_parsed_args__['user']="${remaining_args[idx + 1]}"
        ((idx += 2))
        ;;
      -p | --password)
        __nr_framework_executor_parsed_args__['password']="${remaining_args[idx + 1]}"
        ((idx += 2))
        ;;
      -s | --src-path)
        __nr_framework_executor_parsed_args__['src-path']="${remaining_args[idx + 1]}"
        ((idx += 2))
        ;;
      -n | --nexus-url)
        __nr_framework_executor_parsed_args__['nexus-url']="${remaining_args[idx + 1]}"
        ((idx += 2))
        ;;
      -N | --relative-nexus-repository-path)
        __nr_framework_executor_parsed_args__['relative-nexus-repository-path']="${remaining_args[idx + 1]}"
        __nr_framework_executor_parsed_args__['nexus-url']=${g_settings_assoc_nexus_repository['raw-hosted']}"${remaining_args[idx + 1]}"
        ((idx += 2))
        ;;
      -o | --output)
        __nr_framework_executor_parsed_args__['output']="${remaining_args[idx + 1]}"
        ((idx += 2))
        ;;
      -O | --remote-name)
        __nr_framework_executor_parsed_args__['remote-name']=true
        ((idx += 1))
        ;;
      --)
        ((idx++)) || true
        # 保存 -- 之后的参数
        __nr_framework_executor_parsed_args__['extended_args']="${remaining_args[*]:idx}"
        radp_log_debug "cli extended args: ${__nr_framework_executor_parsed_args__['extended_args']}"
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
# Globals:
#   g_cli_cmd_man_mapper - 命令行帮助文档映射器
#   g_devops_nexus_repository_config - 关联数组，key=repository_id, value=repository_url
#   g_framework_root - 框架目录
#   g_getopt_common_long_opts - 命令行通用长选项
#   g_getopt_common_short_opts - 命令行通用短选项
# Arguments:
#   @ - 所有命令行参数
#######################################
function __framework_executor_cli_parser() {
  # declare cli opts
  local short_opts="f:D:d:T:u:p:n:N:s:o:O"
  local long_opts="function:,dist-path:,dist-file:,upload-file:,user:,password:,nexus-url:,relative-nexus-repository-path:,source-path:,output:,remote-name:"
  local -A opts_desc
  opts_desc['src-path']="Set the src path for building, default is '$g_framework_root'"
  opts_desc['dist-path']='Set the destination directory for built artifacts.'
  opts_desc['dist-file']='Set the dist file path'
  opts_desc['upload-file']='Set the dist file to upload'
  opts_desc['user']='Set the nexus user.'
  opts_desc['password']='Set the nexus password'
  opts_desc['nexus-url']='Set the nexus url. e.g. the url you want to upload/download to/from'
  opts_desc['relative-nexus-repository-path']="Set the relative path to default nexus repository(${g_settings_assoc_nexus_repository['raw-hosted']})"
  opts_desc['output']='指定下载路径(包括下载文件名)'
  opts_desc['remote-name']='下载到当前工作目录'
  # parse cli args
  local -A parsed_args
  radp_nr_cli_parser -r parsed_args -o "$short_opts" -l "$long_opts" -d opts_desc -p "$(radp_cli_get_executor_options_processor_function_name)" -m "$(radp_cli_getexecutor_manual_file)" -- "$@"

  # declare default value
  local -r default_framework_executor_nexus_url=${g_settings_assoc_nexus_repository['raw-hosted']}/radp/${g_framework_dist_filename}

  case "${parsed_args['function']}" in
    build)
      local src_path=${parsed_args['src-path']:-}
      local dist_file=${parsed_args['dist-file']:-}
      if [[ -z "$src_path" ]]; then
        src_path=$g_framework_root
      fi
      local dist_path
      dist_path=$(dirname "$dist_file")
      if [[ ! -d "$dist_path" ]];then
        radp_log_error "Dist path not exist"
        return 1
      fi
      dist_file=$(radp_os_get_absolute_path "$dist_file")
      framework_executor_build "$src_path" "$dist_file"
      ;;
    deploy)
      local user=${parsed_args['user']:-${g_devops_nexus_user}}
      local password=${parsed_args['password']:-${g_devops_nexus_password}}
      local nexus_url=${parsed_args['nexus-url']:-}
      local src_path="${parsed_args['src-path']:-}"
      local file_to_upload=${parsed_args['upload-file']:-}
      # 如果 -s or -T 均未指定，则默认构建框架源码包
      if [[ -z "$src_path" && -z "$file_to_upload" ]]; then
        src_path=${g_framework_root}
        nexus_url=${nexus_url:-${default_framework_executor_nexus_url}}
      fi
      framework_executor_deploy "$user" "$password" "$nexus_url" "$src_path" "$file_to_upload"
      ;;
    download)
      local user=${parsed_args['user']:-${g_devops_nexus_user}}
      local password=${parsed_args['password']:-${g_devops_nexus_password}}
      local nexus_url=${parsed_args['nexus-url']:-}
      local download_to_pwd=${parsed_args['remote-name']:-'false'}
      local download_to_path=${parsed_args['output']:-}
      framework_executor_download "$user" "$password" "$nexus_url" "$download_to_pwd" "$download_to_path"
      ;;
    reset)
      local user=${parsed_args['user']:-${g_devops_nexus_user}}
      local password=${parsed_args['password']:-${g_devops_nexus_password}}
      local nexus_url=${parsed_args['url']:-${default_framework_executor_nexus_url}}
      framework_executor_reset "$user" "$password" "$nexus_url"
      ;;
    call)
      local cmds
      IFS=' ' read -ra cmds <<<"${parsed_args['extended_args']}"
      framework_executor_call "${cmds[@]}"
      ;;
    *)
      radp_cli_print_help_of_invalid_subcmd_function "${parsed_args['function']}" "${BASH_SOURCE[0]}"
      return 1
      ;;
  esac
}

#######################################
# 声明当前 executor file 的全局常量
# 规范
# 示例: declare -gr default_xx_yyy=default_value, 其中 xx 为 subcmd
# Arguments:
#  None
#######################################
function __declare_constants() {
  # TODO: optional 如果有需要在这里定义常量
  # 如果要定义当前脚本的全局变量，请统一定义在这里
  # 1, 对于 framework executor 将会定义在 framework/includes/vars/constants/executor/constants_$subcmd.sh 中
  # 2. 对于 user executor 你可以定义在这个方法中，也可以考虑定义在 lib 目录下
  :
}

#######################################
# radp bash framework 内置执行器
# 包括：升级框架版本等
# Arguments:
#  None
# Examples
#  xx framework -f upgrade
#######################################
function main() {
  # shellcheck source=./executor.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/executor.sh
  __declare_constants
  __framework_executor_cli_parser "$@"
}

main "$@"

#!/usr/bin/env bash

set -e

#######################################
# 导入指定目录下的脚本(支持文件名排序)
# 如果目标是文件则会导入这个文件
# Arguments:
#   1 - 目标目录或文件
#######################################
function radp_source_local_scripts() {
  local targets=${1:?}
  local target
  for target in ${targets}; do
    if [[ -e "$target" ]]; then
      local -a sorted_scripts
      if [[ -d "$target" ]]; then
        # 如果目标是目录，查找该目录下的所有.sh文件
        mapfile -t sorted_scripts < <(find "${target}" -type f -name "*.sh" | sort -t '_' -k 1,1n)
      elif [[ -f "$target" && "${target: -3}" == ".sh" ]]; then
        # 如果目标是.sh文件，直接将文件名加入数组
        sorted_scripts=("$target")
      else
        continue
      fi

      local script
      for script in "${sorted_scripts[@]}"; do
        # shellcheck disable=SC1090
        source "${script}" || {
          radp_log_error "Failed to source $script" || echo "Failed to source $script" >&2
          return 1
        }
        g_context_sourced_local_scripts+=("$script")
      done
    fi
  done
}

#----------------------------------------------------------------------------------------------------------------------#

#######################################
# 打印欢迎信息
# 打印 banner、版本信息、requirements、激活的插件信息等等
# Globals:
#   g_env
#   g_framework_banner_file
#   g_framework_version
# Arguments:
#  None
#######################################
function __framework_welcome() {
  # 标记框架已经成功加载了(当前 shell，对子 shell 无效)
  g_flag_framework_loaded=true
  gx_flag_running=true

  # print banner
  cat "$g_framework_banner_file" # TODO 未来支持自定义 banner
  echo "RADP BASH FRAMEWORK $g_framework_version"
  # print active env
  radp_log_info "Radpctl run on env: $g_env"
  # print enabled plugins info
  if [[ ${#g_enabled_plugins[@]} -gt 0 ]]; then
    radp_log_info "Enabled plugins [${g_enabled_plugins[*]}]"
    radp_log_debug "autoconfigured plugin files $(radp_nr_utils_print_assoc_arr g_enabled_plugin_file_mapper)"
  fi
  radp_log_info "${g_command_line[*]}"
  :
}

#######################################
# 自动补全
# Arguments:
#  None
#######################################
function __framework_auto_completion() {
  # shellcheck source=./auto_completion.sh
  # shellcheck source=../extend/auto_completion.sh
  :
}

#######################################
# 声明: 脚本需要的全部全局变量（可配置化且支持多环境）
# 该函数是框架全局变量初始化的核心入口点，确保了框架的配置项和环境变量能够
# 在框架启动时被正确地设置和加载。
#
# Arguments:
#  @ - 命令行所有参数
#######################################
function __framework_declare_global_vars() {
  local framework_home
  framework_home=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

  # framework 目录结构
  declare -gr g_framework_root="$framework_home"
  declare -gr g_framework_includes_root="${g_framework_root}"/includes
  declare -gr g_command_line=("$0" "$@") # 缓存当前正在执行的命令(完整命令行)
  # shellcheck source=./includes/vars/global_vars.sh
  radp_source_local_scripts "$g_framework_includes_root"/vars/global_vars.sh || {
    local context_err_msg='Pre defined vars contains invalid value, please check your code.'
    radp_log_error "$context_err_msg" || echo "Warn: $context_err_msg" 2>&1
    return 1
  }
}

#######################################
# 框架内置库函数
#
# 为了保证库函数的可维护性、兼容性、可移植性
# 分为三类：
# 1) 日志库函数: 其它库函数可直接使用
# 2) 通用库函数:
# 3) 高级库函数: require bash version >= 4.3 的库函数
#
# 开发规范
# 1) 尽量保证库函数的原子性，尽量不要互相调用（日志库函数可被其它库函数随意调用）
# 2) 如果一定要互相调用，请注意以下情况
#     不要出现通用库函数 -> 调用高级库函数
#     被调用的库函数所在脚本文件能在调用者之前导入(@see radp_source_local_scripts)
#     存在依赖关系的库函数，尽量定义在同一个脚本文件中
# 3) 所有库函数均能正确的 return 0/1
#
# 库函数命名规范: radp_[使用的高级特性简称]_<script_file_name>_[return_type]_name
# 1) radp_xx_get_yyy: 这是一个 xx.sh 中的库函数，是 getter
# 2) radp_xx_check_yyy: 这是一个 xx.sh 中的库函数, 函数返回值 0/1
# 3) radp_xx_set_yyy: 这是一个 xx.sh 中的库函数，无返回值
# 4) radp_xx_find_yyy: 这是一个 xx.sh 中的库函数，
# 5) radp_xx_add_yyy:
# 6) radp_nr_xx_get_yyy: 这是一个 xx.sh 中的库函数，通过 nameref 的方式返回值
# 7) 等等
#
# Globals:
#   g_framework_includes_root
#
# Arguments:
#  None
#######################################
function __framework_source_internal_libs() {
  # 加载日志组件
  radp_source_local_scripts "$g_framework_includes_root"/libs/logger || {
    echo "Failed to setup logging, please check your code and config file" >&1
    return 1
  }

  # 上面这行代码以后的所有代码就都可以使用 radp_log_xx 进行日志打印了
  radp_source_local_scripts "${g_framework_includes_root}/libs/toolkit/common ${g_framework_includes_root}/libs/toolkit/advanced" || {
    local context_err_msg='Failed to load framework internal libs, please check your code.'
    radp_log_error "$context_err_msg"
    return 1
  }

  radp_log_debug "Framework internal libs included."
}

#######################################
# 框架组件自动配置
# 包括:
# 1) requirements builtins 保证框架能够正常运行的基本组件
# 2) integrations 框架集成的功能(不可插拔)
# 3) plugins 框架集成的功能(可插拔)
# 4) runtime 运行时的动态变量(状态变量)
#
# Arguments:
#  None
#######################################
function __framework_autoconfigure() {
  # shellcheck source=autoconfigure/autoconfigure.sh
  radp_source_local_scripts "$g_framework_root"/autoconfigure/autoconfigure.sh || return 1
}

#######################################
# 框架扩展点
# 用户可对框架进行扩展, 包括
# 1) vars
# Globals:
#   g_user_integrations_path
#   g_user_includes_root
# Arguments:
#  None
#######################################
function __framework_user_extends() {
  # 用户本地扩展
  radp_source_local_scripts "${g_user_includes_root}/vars ${g_user_includes_root}/libs ${g_user_integrations_path}/api" || {
    radp_log_error 'Failed to load user extends, please check your code.'
    return 1
  }
  # 用户外部扩展：指的是先从远程下载的库
  radp_source_local_scripts "${g_user_includes_root}/remote" || {
    radp_log_error "Failed to load user remote extends, please check your code."
    return 1
  }
}

#######################################
# 构建上下文环境
# 包括：全局变量、库函数等
# Arguments:
#  $@ - 命令行参数
#######################################
function __framework_build_context() {
  if [[ "$gx_flag_running" != 'true' ]]; then
    # 记录 sourced 的文件
    declare -gxa g_context_sourced_local_scripts
  fi

  __framework_auto_completion || {
    local context_err_msg='Failed to preload auto completion'
    radp_log_warn "$context_err_msg" || echo "Warn: $context_err_msg" 2>&1
  }
  __framework_declare_global_vars "$@" || return 1
  __framework_source_internal_libs || return 1
  # 上面这行代码的后续代码逻辑就可以使用通用库函数了
  __framework_autoconfigure || return 1
  __framework_user_extends || return 1
}

#----------------------------------------------------------------------------------------------------------------------#

#######################################
# 脚本框架入口
#
# Arguments:
#  None
# Notes:
# 幂等，可以重复 source 这个脚本框架
#######################################
function main() {
  # 幂等控制
  if [[ "$g_flag_framework_loaded" == true ]]; then
    if [[ $g_debug == true ]]; then
      echo "WARN: Skipping to avoid duplicating loading because framework already loaded"
    fi
    # 避免重复加载 Framework
    return 0
  fi

  # 构建脚本上下文环境
  __framework_build_context "$@" || {
    local msg='Failed to build framework context, please check your code and config_file.'
    radp_log_error "$msg" || echo -e "Error: $msg" >&2
    return 1
  }

  # 是否打印欢迎页(避免重复打印)
  if [[ "$gx_flag_running" != 'true' ]]; then
    # 比如：当 executor A 调用 executor B 时，将不再打印欢迎页
    __framework_welcome "$@"
  fi

  # 命令行解析
  __framework_cli_run_subcmd "$@"
}

main "$@"

#!/usr/bin/env bash

#######################################
# 自动补全配置文件中声明的变量
# Arguments:
#  None
#######################################
function __auto_completion_config_file() {
  # shellcheck source=../framework/config/radpctl_config.sh
  # shellcheck source=../config/radpctl.sh
  :
}

#######################################
# 自动补全全局变量
# Arguments:
#  None
# @see global_vars.sh
# @see __framework_declare_constants_vars
# @see __framework_declare_configurable_vars
# @see __framework_declare_dynamic_vars
#######################################
function __auto_completion_vars() {
  # @see global_vars.sh

  # 1. constants
  # shellcheck source=includes/vars/constants/1_framework_constants.sh
  # shellcheck source=includes/vars/constants/2_logging_constants.sh
  # shellcheck source=includes/vars/constants/3_cli_constants.sh
  # shellcheck source=includes/vars/constants/yq_query_constants.sh

  # 2. configurable vars
  # shellcheck source=includes/vars/configurable/configurable_setup.sh
  # shellcheck source=includes/vars/configurable/configurable_vars.sh

  # 3. runtime vars
  # shellcheck source=includes/vars/runtime/guest_runtime.sh
  # shellcheck source=includes/vars/runtime/context_status_runtime.sh
  # shellcheck source=includes/vars/runtime/cli_runtime.sh
  # shellcheck source=includes/vars/runtime/settings_runtime.sh
  # shellcheck source=includes/vars/runtime/plugin_runtime.sh
  # shellcheck source=includes/vars/runtime/vagrant_runtime.sh
  :
}

#######################################
# 自动补全通用库函数
# Arguments:
#  None
# @see __framework_source_internal_libs
#######################################
function __auto_completion_libs() {
  # shellcheck source=./includes/libs/logger/logger.sh

  # shellcheck source=./includes/libs/toolkit/common/1_lang.sh
  # shellcheck source=./includes/libs/toolkit/common/2_utils.sh
  # shellcheck source=./includes/libs/toolkit/common/3_net.sh
  # shellcheck source=./includes/libs/toolkit/common/4_os.sh
  # shellcheck source=./includes/libs/toolkit/common/5_io.sh
  # shellcheck source=./includes/libs/toolkit/common/6_regex.sh
  # shellcheck source=./includes/libs/toolkit/common/alias.sh

  # shellcheck source=./includes/libs/toolkit/advanced/1_lang.sh
  # shellcheck source=./includes/libs/toolkit/advanced/2_utils.sh
  # shellcheck source=./includes/libs/toolkit/advanced/3_net.sh
  # shellcheck source=./includes/libs/toolkit/advanced/4_os.sh
  # shellcheck source=./includes/libs/toolkit/advanced/5_io.sh
  # shellcheck source=./includes/libs/toolkit/advanced/6_regex.sh
  # shellcheck source=./includes/libs/toolkit/advanced/cli.sh
  :
}

#######################################
# 自动补全内置库函数
# Arguments:
#  None
# @see __framework_autoconfigure_builtins
#######################################
function __auto_completion_hook() {
  # shellcheck source=./autoconfigure/hook/pre/1_hook_guest_distro_info.sh
  # shellcheck source=./autoconfigure/hook/pre/2_hook_auto_troubleshoot_pkg.sh
}

#######################################
# 自动补全内置库函数
# Arguments:
#  None
# @see __framework_autoconfigure_builtins
#######################################
function __auto_completion_builtins() {
  # shellcheck source=./autoconfigure/builtin/1_autoconfigure_bash5.sh
  # shellcheck source=./autoconfigure/builtin/2_autoconfigure_executor.sh
  # shellcheck source=./autoconfigure/builtin/3_autoconfigure_settings.sh
  :
}

#######################################
# 自动补全集成的库函数
# Arguments:
#  None
# @see __framework_autoconfigure_integrations
#######################################
function __auto_completion_integrations() {
  :
}

#######################################
# 自动补全插件库函数
# Arguments:
#  None
# @see __framework_autoconfigure_plugins
#######################################
function __auto_completion_plugins() {
  # shellcheck source=./autoconfigure/plugins/1_autoconfigure_plugin_proxy.sh
  # shellcheck source=./autoconfigure/plugins/2_autoconfigure_plugin_yq.sh
  :
}

#######################################
# 自动补全
# Arguments:
#  None
#######################################
function main() {
  __auto_completion_config_file
  __auto_completion_vars
  __auto_completion_libs
  __auto_completion_hook
  __auto_completion_builtins
  __auto_completion_integrations
  __auto_completion_plugins
}

main

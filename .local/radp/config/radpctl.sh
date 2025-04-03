#!/usr/bin/env bash

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# @see configurable_setup.sh
# --------------------------------------------- configurable setup --------------------------------------------#
# !!! 如果期望覆盖框架中(configurable_setup.sh)定义的变量，你必须通过环境变量进行覆盖，如以下四个变量
# !!! 在配置文件中是无法覆盖这几个变量的默认值的
# export GX_ENV=xxx
# export GX_USER_BASE_CONFIG_FILENAME=xxx #用户基础配置文件名
# export GX_USER_CONFIG_PATH=xxx #用户配置文件目录
# export GX_FRAMEWORK_DIST_FILENAME=xxx #框架本地构件名
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# @see configurable_vars.sh
# path:         @see __framework_declare_user_paths_settings
# log:          @see __framework_declare_log_settings
# debug:        @see __framework_declare_debug_settings
# cli:          @see __framework_declare_cli_settings
# integrations: @see __framework_declare_integration_settings.sh
# plugin:       @see __framework_declare_plugin_settings
# guest:        @see __framework_declare_guest_settings
# devops:       @see __framework_declare_devops_settings
#--------------------------------------------- framework defined configurable vars -----------------------------------#
# 用户扩展目录
declare -gx G_USER_INCLUDES_ROOT
declare -gx G_USER_INTEGRATIONS_PATH
declare -gx G_USER_PLUGIN_PATH
declare -gx G_USER_EXECUTOR_PATH
declare -gx G_USER_MAN_PATH
declare -gx G_USER_EXTRA_CONFIG_PATH

G_USER_INCLUDES_ROOT="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")"/extend
G_USER_INTEGRATIONS_PATH=${G_USER_INCLUDES_ROOT}/integrations
G_USER_PLUGIN_PATH=${G_USER_INCLUDES_ROOT}/plugins
G_USER_EXECUTOR_PATH="$(dirname "${G_USER_INCLUDES_ROOT}")"/executor
G_USER_MAN_PATH="$(dirname "${G_USER_INCLUDES_ROOT}")"/man
G_USER_EXTRA_CONFIG_PATH="$(dirname "${G_USER_INCLUDES_ROOT}")"/config/extra

# log
declare -gx G_LOG_LEVEL=${GX_LOG_LEVEL:-'info'}
declare -gx G_LOG_FILE=${GX_LOG_FILE:-"${HOME}/logs/radp/$(basename "$0").log"}
#declare -gxa G_LOG_LEVEL_COLOR_CONFIG=(0 4 2 3 4)

# debug
declare -gx G_DEBUG=${GX_DEBUG:-'false'} # 是否开启 debug 模式，将会打印更多日志

# autoconfigure
declare -gx G_PRE_HOOK_AUTO_TROUBLESHOOT_PKG=${GX_PRE_HOOK_AUTO_TROUBLESHOOT_PKG:-} # 是否开启解决 pkg 问题

# plugin
declare -gx G_SETTINGS_STR_PLUGIN_PROXY=${GX_SETTINGS_STR_PLUGIN_PROXY:-"enabled=true;candidate_ips=127.0.0.1;proxy_ip=;http_port=20171;socks5_port=20170;no_proxy=.svc,.svc.cluster.local,.cluster.local,localhost, 127.0.0.1"}
declare -gx G_SETTINGS_STR_PLUGIN_YQ=${GX_SETTINGS_STR_PLUGIN_YQ:-"enabled=true;version=latest;url=https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"}

# devops
declare -gx G_DEVOPS_NEXUS_USER=${GX_DEVOPS_NEXUS_USER:-} #nexus user
declare -gx G_DEVOPS_NEXUS_PASSWORD=${GX_DEVOPS_NEXUS_PASSWORD:-} #nexus password
declare -gx G_SETTINGS_STR_NEXUS_REPOSITORY=${GX_SETTINGS_STR_NEXUS_REPOSITORY:-} # nexus repositories

#--------------------------------------------- user defined configurable vars -----------------------------------#
# integration vagrant
declare -gx G_INTEGRATIONS_VAGRANT_ROOT=${GX_INTEGRATIONS_VAGRANT_ROOT:-} #vagrant 根目录
declare -gx G_INTEGRATIONS_VAGRANT_CONFIG_DIR=${GX_INTEGRATIONS_VAGRANT_CONFIG_DIR:-} #vagrant 配置文件目录
declare -gx G_INTEGRATIONS_VAGRANT_CONFIG_FILE_PREFIX=${GX_INTEGRATIONS_VAGRANT_CONFIG_FILE_PREFIX:-} #vagrant 配置文件名前缀

# others
declare -gx G_TARIGNORE_FILE=${GX_TARIGNORE_FILE:-} # 打包时忽略哪些文件
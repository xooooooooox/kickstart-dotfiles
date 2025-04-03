#!/usr/bin/env bash

########################################################################################################################
###
# 可配置的全局变量
# 为了后文描述方便，所有变量统称为 configurable_vars
#
# 命名规范
# declare -gx G_YYY=${GX_YYY:-default_value}
# 1. 变量名
#   1) G_YYY: 配置文件中声明的变量必须均为大写, 且前缀必须为 G_
#   2) 变量名必须与 configurable_vars.sh 或者 $g_user_includes_root/vars/configurable 目录中声明的全局变量一一对应
#   3) 如: G_USER_INCLUDES_ROOT -> 对应 configurable_vars.sh 中的 g_user_includes_root
# 2. 变量值
#   1) ${GX_YYY:-default_value}: GX_YYY 表示这是一个环境变量，表示可通过环境变量进行覆盖，
#   2) ${default_value}: 如果不希望受环境变量影响，可省略 GX_YYY 部分
#
# 加载顺序
# 1). 框架基础配置文件 -> 框架环境配置文件 -> 用户基础配置文件 -> 用户环境配置文件
# 2). 以上加载顺序，同名变量后者覆盖前置
#
# 注意
# 1. configurable_var 中所有变量基本均支持多环境
# 2. configurable_var 都有哪些?
#   1) @see global_vars.sh#__framework_declare_configurable_vars
#   2) @see configurable/configurable_vars.sh
# 3. 为了脚本的可维护性, 将会把目前支持的 configurable_vars 均会在框架基础配置文件 radpctl_config.sh 中声明一次
#   用户配置文件以及环境配置文件可参考该配置文件，选择性覆盖
#
# 特别说明
# @see configurable_setup.sh 中声明的变量
# 1）是不可以被用户配置文件覆盖的
# 2) 仅可通过框架基础配置文件 radpctl_config.sh 或 环境变量进行覆盖
########################################################################################################################

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# @see configurable_setup.sh
# --------------------------------------------- configurable setup --------------------------------------------#
declare -gx G_ENV=${GX_ENV:-}
declare -gx G_USER_BASE_CONFIG_FILENAME=${GX_USER_BASE_CONFIG_FILENAME:-} # 用户配置文件名(必须通过环境变量才可变更该值)
declare -gx G_USER_CONFIG_PATH=${GX_USER_CONFIG_PATH:-} #用户配置文件目录
declare -gx G_FRAMEWORK_DIST_FILENAME=${GX_FRAMEWORK_DIST_FILENAME:-} #框架本地构件名
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# @see configurable_vars.sh
#--------------------------------------------- configurable vars --------------------------------------------#
# path: @see __framework_declare_user_paths_settings
declare -gx G_USER_INCLUDES_ROOT=${GX_USER_INCLUDES_ROOT:-} #用户扩展通用库脚本目录
declare -gx G_USER_INTEGRATIONS_PATH=${GX_USER_INTEGRATIONS_PATH:-} #用户扩展集成库函数目录
declare -gx G_USER_PLUGIN_PATH=${GX_USER_PLUGIN_PATH:-} #用户扩展插件库函数目录
declare -gx G_USER_EXECUTOR_PATH=${GX_USER_EXECUTOR_PATH:-} #用户子命令脚本目录
declare -gx G_USER_MAN_PATH=${GX_USER_MAN_PATH:-} #用户子命令帮助文档目录
declare -gx G_USER_EXECUTOR_REGEX=${GX_USER_EXECUTOR_REGEX:-} #用户子命令脚本名正则表达式
declare -gx G_USER_MAN_REGEX=${GX_USER_MAN_REGEX:-} #用户子命令帮助文档文件名正则
declare -gx G_USER_PLUGIN_REGEX=${GX_USER_PLUGIN_REGEX:-} #用户子命令帮助文档文件名正则
declare -gx G_USER_EXTRA_CONFIG_PATH=${GX_USER_EXTRA_CONFIG_PATH:-} #一些用户外挂配置文件，如 gitlab.rb 等

# log: @see __framework_declare_log_settings
declare -gx G_LOG_LEVEL=${GX_LOG_LEVEL:-} #日志级别
declare -gx G_LOG_FILE=${GX_LOG_FILE:-} #日志文件
declare -gxa G_LOG_LEVEL_COLOR_CONFIG=(0 1 2 3 4) # 目前支持的颜色 @see g_colors

# debug: @see __framework_declare_debug_settings
declare -gx G_DEBUG=${GX_DEBUG:-'true'} # 是否开启 debug 模式，将会打印更多日志

# cli: @see __framework_declare_cli_settings
# 是否开启自动解析子命令后自动分发给相应的执行器的功能(默认为开启)
# 如果不涉及子命令或者说执行器分发，则设定为 false.
declare -gx G_ENABLE_SUBCMD_EXECUTOR_DISPATCH=${GX_ENABLE_SUBCMD_EXECUTOR_DISPATCH:-}

# autoconfigure: @see __framework_declare_autoconfigure_settings
declare -gx G_PRE_HOOK_AUTO_TROUBLESHOOT_PKG=${GX_PRE_HOOK_AUTO_TROUBLESHOOT_PKG:-} # 是否开启解决 pkg 问题

# integrations: @see __framework_declare_integration_settings.sh
# 框架集成的工具, 如 vagrant、docker等
# :::

# plugin: @see __framework_declare_plugin_settings
declare -gx G_SETTINGS_STR_PLUGIN_PROXY=${GX_SETTINGS_STR_PLUGIN_PROXY:-} # plugin: proxy
declare -gx G_SETTINGS_STR_PLUGIN_YQ=${GX_SETTINGS_STR_PLUGIN_YQ:-} # plugin: yq

# guest: @see __framework_declare_guest_settings
# 虚拟机相关
declare -gx G_GUEST_USER=${GX_GUEST_USER:-} # guest 默认用户
declare -gx G_GUEST_DATA_DIR=${GX_GUEST_DATA_DIR:-} # guest 本机数据目录
declare -gx G_GUEST_CLUSTER_DATA_DIR=${GX_GUEST_CLUSTER_DATA_DIR:-} # guest 集群共享目录
declare -gx G_GUEST_PUBLIC_DATA_DIR=${GX_GUEST_PUBLIC_DATA_DIR:-} # guest 公共共享目录
declare -gx G_GUEST_DOCKER_VOLUME_ROOT=${GX_GUEST_DOCKER_VOLUME_ROOT:-}
declare -gx G_GUEST_BACKUP_ROOT=${GX_GUEST_BACKUP_ROOT:-}

# devops: @see __framework_declare_devops_settings
# devops 环境相关
declare -gx G_DEVOPS_NEXUS_USER=${GX_DEVOPS_NEXUS_USER:-} #nexus user
declare -gx G_DEVOPS_NEXUS_PASSWORD=${GX_DEVOPS_NEXUS_PASSWORD:-} #nexus password
declare -gx G_SETTINGS_STR_NEXUS_REPOSITORY=${GX_SETTINGS_STR_NEXUS_REPOSITORY:-} # nexus repositories

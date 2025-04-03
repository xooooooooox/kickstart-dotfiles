#!/usr/bin/env bash
# shellcheck source=../global_vars.sh

#######################################
# 该函数中定义的变量
# 1) 不可被外部用户配置文件覆盖
# 2) 但可通过环境变量进行覆盖
# 3) 或者在框架基础配置文件 @radpctl_config.sh 中修改默认值
# Globals:
#   G_ENV
#   G_USER_BASE_CONFIG_FILENAME
#   g_default_user_base_config_filename
#   g_env
#   g_user_base_config_filename
# Arguments:
#  None
# Notes:
#  也就是如果期望切换环境，正确的打开方式为
#  1) export GX_ENV=xxx; 然后执行你的脚本
#  2) 你可以将 export GX_ENV 放到 ~/.bashrc 中
#######################################
function main() {
  declare -gr g_env=${G_ENV:-'default'}
  declare -gr g_user_base_config_filename=${G_USER_BASE_CONFIG_FILENAME:-"$g_default_user_base_config_filename"}
  local framework_parent_dir
  framework_parent_dir=$(dirname "${g_framework_root}")
  declare -gr g_user_config_path=${G_USER_CONFIG_PATH:-"$framework_parent_dir"/config}
  declare -gr g_framework_dist_filename=${G_FRAMEWORK_DIST_FILENAME:-"radp_bash_framework-${g_framework_version}.tar.gz"}
}

main

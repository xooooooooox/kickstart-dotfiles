#!/usr/bin/env bash
# shellcheck source=../global_vars.sh

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#######################################
# 获取环境配置文件名
# Globals:
#   g_base_config_filename - 基础配置文件名
# Arguments:
#   1 - env: eg. default/local/dev/prod, etc.
#######################################
function radp_vars_get_env_config_filename() {
  local active_profile=${1:?}
  local base_config_filename=${2:-"$g_framework_base_config_filename"}
  if [[ ${active_profile} == 'default' ]]; then
    echo "$base_config_filename"
  else
    echo "${base_config_filename/.sh/}_${active_profile}.sh"
  fi
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function main() {
  # 1. framework path
  declare -gr g_framework_config_path="${g_framework_root}"/config
  declare -gr g_framework_executor_path="$g_framework_root"/executor
  declare -gr g_framework_integrations_path="$g_framework_root"/autoconfigure/integrations
  declare -gr g_framework_plugin_path="$g_framework_root"/autoconfigure/plugins
  declare -gr g_framework_cache_path="$g_framework_root"/cache
  declare -gr g_framework_man_path="$g_framework_root"/man
  declare -gr g_framework_tmp_path="${g_framework_root}"/tmp

  # 2. framework file
  # 框架内的配置文件名是写死的，不可配置化
  # 但用户的配置文件名是可以通过环境变量进行覆盖的 @see g_user_base_config_filename
  declare -gr g_framework_base_config_filename=radpctl_config.sh
  declare -gr g_framework_banner_file="$g_framework_config_path"/banner.txt
  local framework_version_file="$g_framework_config_path"/version.txt

  # 3. framework regex
  # file regex
  declare -gr g_framework_executor_regex='^(.*)_executor.*\.sh$'
  declare -gr g_framework_man_regex='^(.*)_executor.*\.man$'
  declare -gr g_framework_plugin_regex='*_plugin_*.sh'
  # var name regex
  declare -gr g_regex_settings_str_var_name='g_settings_str_'
  declare -gr g_regex_settings_assoc_var_name='g_settings_assoc_'

  # 4. framework required
  # bash 下载地址，版本必须大于等于 4.3
  declare -gr g_framework_builtin_bash_download_url='https://ftp.gnu.org/gnu/bash/bash-5.2.21.tar.gz'

  # 5. framework info
  # shellcheck disable=SC2155
  declare -gr g_framework_version=$(cat "$framework_version_file") # x.x.x 不是 vx.x.x

  # 6. 默认用户配置
  declare -gr g_default_user_base_config_filename='radpctl.sh'

  g_today=$(date '+%Y%m%d')
  g_cur_user=$(whoami)
  declare -gr g_today
  declare -gr g_cur_user
}

main

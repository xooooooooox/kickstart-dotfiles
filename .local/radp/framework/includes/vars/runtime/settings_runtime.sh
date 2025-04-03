#!/usr/bin/env bash

#######################################
# 如果期望在配置文件中，配置hashmap 形式的配置时
# 则可以参考以下步骤：
# 1) 在配置文件中,定义字符串变量 declare -gr g_settings_str_<settings_id>_<settings_name>="key=value;key2=value2;..."
# 2) 然后在这里声明关联数组变量 declare -gA g_settings_assoc_<settings_id>_<settings_name>
# 3) 完成以上两步后，你便可以直接在代码中直接使用这个关联数组变量了，它的值会被提前自动注入
#
# Globals:
#   省略
# Arguments:
#  None
#
# @see 3_autoconfigure_setting.sh
# @see configurable_vars.sh
# @see radp_nr_convert_to_associative_array
#######################################
function main() {
  # available settings id @see __framework_auto_convert_settings_str_to_associative_ary
  declare -ga g_available_settings_id

  # settings_assoc_var_name: g_settings_assoc_<settings_id>_<settings_name>
  # plugin settings
  declare -gA g_settings_assoc_plugin_proxy
  declare -gA g_settings_assoc_plugin_yq
  # nexus settings
  declare -gxA g_settings_assoc_nexus_repository
}

main

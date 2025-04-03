#!/usr/bin/env bash
set -e
# shellcheck source=../../bootstrap.sh

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

function radp_get_settings_assoc_var() {
  local settings_id=${1:?}
  local settings_name=${2:?}

  if ! radp_lang_check_if_arr_contains "$settings_id" "${g_available_settings_id[@]}"; then
    radp_log_error "Invalid settings_id, available settings_id: [${g_available_settings_id[*]}]"
    return 1
  fi

  local settings_var_name="${g_regex_settings_assoc_var_name}${settings_id}_${settings_name}"
  echo "$settings_var_name"
}

function radp_get_settings_value() {
  local settings_id=${1:?}
  local settings_name=${2:?}
  local key=${3:?}

  if ! radp_lang_check_if_arr_contains "$settings_id" "${g_available_settings_id[@]}"; then
    radp_log_error "Invalid settings_id, available settings_id: [${g_available_settings_id[*]}]"
    return 1
  fi

  local settings_var_name="${g_regex_settings_assoc_var_name}${settings_id}_${settings_name}"
  local -n settings_var=$settings_var_name
  local value=${settings_var[$key]}
  radp_log_debug "${settings_var_name}[$key]=${value}"
  echo "$value"
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#######################################
# 根据预设的变量命名正则
# 计算 settings_str_var_name -> 对应的 setting_assoc_var_name
# Arguments:
#   1 - settings_str_var_name 变量名
#######################################
function __framework_get_settings_associative_arr_var_name() {
  local settings_str_var_name=${1:?}
  echo "${settings_str_var_name//${g_regex_settings_str_var_name}/${g_regex_settings_assoc_var_name}}"
}

function __framework_get_settings_id_via_settings_str_var_name() {
  local settings_str_var_name=${1:?}
  # 移除前缀
  local stripped="${settings_str_var_name#"$g_regex_settings_str_var_name"}"
  # 提取 xxx, 即直到第一个下划线前的部分
  echo "${stripped%%_*}"
}

#######################################
# 自动将配置文件中的 g_settings_str_xxx -> g_settings_map_xx
# Arguments:
#  None
#######################################
function __framework_auto_convert_settings_str_to_associative_ary() {
  local declared_settings_str_var_name declared_settings_str_var_value
  local print_original_settings='Original setting:\n'
  local print_autoconfigured_settings='Autoconfigured settings:\n'
  for declared_settings_str_var_name in $(compgen -A variable | grep "$g_regex_settings_str_var_name"); do
    # 1. 记录有效地 settings id
    local settings_id
    settings_id=$(__framework_get_settings_id_via_settings_str_var_name "$declared_settings_str_var_name")
    radp_nr_lang_add_item_to_set "$settings_id" g_available_settings_id

    # 2. 缓存配置文件中所有声明的 g_settings_str_xx
    declared_settings_str_var_value=${!declared_settings_str_var_name}
    print_original_settings+="$declared_settings_str_var_name -> $declared_settings_str_var_value\n" # print debug info

    # 3. 将配置文件中的字符串格式的设置 -> 转化为关联数组
    # 即 g_settings_str_xx -> g_settings_assoc_xx
    local settings_associative_array_var_name
    settings_associative_array_var_name=$(__framework_get_settings_associative_arr_var_name "$declared_settings_str_var_name")

    # 动态 declare -gA 这个转换后的变量 ${settings_associative_array_var_name}
    # 保证了即使 settings_runtime 没有 declare 也不会报错
    declare -gA "$settings_associative_array_var_name"
    # 提示：如果打印警告日志 'Variable 'g_settings_assoc_xx' not defined'
    # 只需要在 @see settings_runtime.sh 中 declare -gA g_settings_assoc_xx 即可消除警告
    radp_nr_lang_convert_str_to_assoc_arr "${declared_settings_str_var_value}" "${settings_associative_array_var_name}"

    local -n __nr_converted_settings_var__=$settings_associative_array_var_name
    print_autoconfigured_settings+="$settings_associative_array_var_name $(radp_nr_utils_print_assoc_arr __nr_converted_settings_var__)\n" # 打印信息
  done
  radp_log_debug "Available settings id: ${g_available_settings_id[*]}"
  radp_log_debug "$print_original_settings"
  radp_log_debug "$print_autoconfigured_settings"
}

function main() {
  __framework_auto_convert_settings_str_to_associative_ary
}

main

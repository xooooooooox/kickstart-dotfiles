#!/usr/bin/env bash

#######################################
# 从一个关联数组复制所有键值对到另一个关联数组。
# 此函数用于在两个关联数组间进行深拷贝。
# 被复制的键值对将直接覆盖目标数组中相同键的值，
# 不会改变目标数组中其他已存在但在源数组中不存在的键值对。
# Globals:
#   无
# Arguments:
#   [1] - 目标关联数组的名称。必须提供且不能为空。
#   [2] - 源关联数组的名称。必须提供且不能为空。
# Returns:
#   None - 该函数不直接返回值，但会修改第一个参数指定的关联数组的内容。
# Notes:
#   - 该函数使用局部的名称引用（local -n）来操作数组，这要求 Bash 版本至少为 4.3。
#   - 在调用此函数之前，确保两个关联数组已经声明。
#   - 函数内部调用了 radp_check_var_type 来检查提供的变量名确实是关联数组。
# Examples:
#   declare -A dest_map origin_map
#   origin_map["key1"]="value1"
#   origin_map["key2"]="value2"
#   radp_nr_copy_from_map dest_map origin_map
#   # 此时 dest_map 将包含 origin_map 中的所有键值对
#######################################
function radp_nr_lang_copy_from_map() {
  local -n __nr_dest_map__=${1:?}
  local -n __nr_origin_map__=${2:?}

  radp_lang_check_var_type __nr_dest_map__ -A
  radp_lang_check_var_type __nr_origin_map__ -A

  local key
  for key in "${!__nr_origin_map__[@]}"; do
    __nr_dest_map__["$key"]="${__nr_origin_map__["$key"]}"
  done
}

function radp_nr_merge_map() {
  local -n __nr_merged_result__=${1:?}
  shift
  local -n __nr_src_map_1__=${1:?}
  local -n __nr_src_map_2__=${2:?}

  # 将第一个数组的键值对加入结果数组
  for key in "${!__nr_src_map_1__[@]}"; do
    __nr_merged_result__["$key"]="${__nr_src_map_1__[$key]}"
  done

  # 将第二个数组的键值对加入结果数组，如果键已存在则覆盖
  for key in "${!__nr_src_map_2__[@]}"; do
    __nr_merged_result__["$key"]="${__nr_src_map_2__[$key]}"
  done
}

#######################################
# 将特定格式的字符串转换成关联数组。
# 1) 字符串格式: 应为 "key=value;key2=value2;..."。
# 2) 此函数利用本地 -n 引用（nameref）特性，允许直接在提供的关联数组变量中设置键值对。
# 注意，此函数要求调用方确保提供的数组变量已经被声明为关联数组，并且 Bash 版本支持 -A 和 -n 选项。
#
# Globals:
#   无
# Arguments:
#   1 - config_string: 要转换的配置字符串，格式为 "key=value;key2=value2;..."。
#   2 - __nr_config_array__: 一个关联数组变量的名称，该函数将在其中设置解析后的键值对。(必须事先声明为关联数组，并且传递其名称作为参数。)
# Returns:
#   None - 但会修改第二个参数指定的关联数组，为其添加转换后的键值对。
# Examples:
#   declare -A my_config
#   radp_nr_convert_to_associative_array "ip=127.0.0.1;port=8080" my_config
#   echo "IP: ${my_config[ip]}, Port: ${my_config[port]}"
# Notes:
#   - 函数内部调用 `radp_check_var_type` 来检查提供的数组是否为关联数组，
#   - 使用 -n 引用特性，要求 Bash 版本至少为 4.3。
#######################################
function radp_nr_lang_convert_str_to_assoc_arr() {
  local config_string=${1:?}
  local -n __nr_config_array__=${2:?}

  radp_lang_check_var_type config_string -s || return 1
  radp_lang_check_var_type --ignore-not-defined __nr_config_array__ -A || return 1

  local kv key value
  local IFS=';'
  for kv in $config_string; do
    IFS='=' read -r key value <<<"$kv"
    __nr_config_array__["$key"]="$value"
  done
}

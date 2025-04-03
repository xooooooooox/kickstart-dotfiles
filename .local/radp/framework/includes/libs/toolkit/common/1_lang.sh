#!/usr/bin/env bash

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#######################################
# 检查给定变量的类型是否符合预期。
# 此函数可用于验证变量是否为关联数组、索引数组、整数等特定类型，支持通过 nameref 间接引用的变量。
# 如果变量类型不匹配，将记录错误日志并返回非零状态。
#
# Globals:
#   None
#
# Arguments:
#   1 - var_name: 要检查类型的变量名。
#   2 - expected_type: 预期的变量类型标识。
#                      '-A' 表示关联数组，'-a' 表示索引数组，'-i' 表示整数, '-s' 表示字符串等
#
# Returns:
#   0 - 变量类型符合预期。
#   1 - 变量未定义或类型不匹配预期。
#
# Examples:
#   1) 声明一个关联数组并检查其类型：
#     declare -A my_assoc_array
#     radp_lang_check_var_type my_assoc_array -A || echo "Type mismatch"
#   2) 声明一个整数变量并检查其类型：
#     declare -i my_int=42
#     radp_lang_check_var_type my_int -i || echo "Type mismatch"
#   3) 试图检查一个未声明的变量或类型不匹配的变量：
#     radp_lang_check_var_type undefined_var -A  # 将返回 1 并记录错误日志
#     declare my_string="not an array"
#     radp_lang_check_var_type my_string -A  # 将返回 1 并记录错误日志
#
# Note:
#   - 当变量通过 nameref 间接引用时，此函数能够递归地解析实际引用的变量，以检查其类型。
#   - 除了直接支持的类型标识之外，expected_type 参数可以扩展为 bash declare 命令支持的其他类型标识。
#######################################
function radp_lang_check_var_type() {
  local ignore_not_defined=false
  if [[ "$1" == '--ignore-not-defined' ]]; then
    ignore_not_defined=true
    shift
  fi

  local var_name=${1:?}
  local expected_type=${2:?} # Expected types: '-A' for associative array, '-a' for indexed array, '-i' for integer, etc.

  local actual_type_info=""
  local cur_var_name="$var_name"

  while true; do
    # Retrieve the type of the current variable
    actual_type_info=$(declare -p "${cur_var_name}" 2>/dev/null)
    if [[ -z $actual_type_info ]]; then
      local msg="Variable '$cur_var_name' not defined"
      if [[ "$ignore_not_defined" != true ]]; then
        radp_log_error "$msg"
        return 1
      else
        radp_log_warn "$msg"
        return 0
      fi
    fi

    # Check if the current variable is a nameref
    if [[ $actual_type_info =~ ^declare\ -n ]]; then
      # Extract the name of the variable referenced by the current nameref
      cur_var_name="${actual_type_info#*=}"
      # Remove quotes if present
      cur_var_name="${cur_var_name#\"}"
      cur_var_name="${cur_var_name%\"}"
    else
      # Not a nameref, so break out of the loop
      break
    fi
  done

  # Check the type of the actual variable
  # Check the type of the actual variable
  if [[ $expected_type == "-s" ]]; then
    # Check if it's not declared as any special type
    if [[ $actual_type_info =~ ^declare\ -[^iAa]*$ ]]; then
      radp_log_error "'$var_name' must be a string."
      return 1
    fi
  elif [[ ! $actual_type_info =~ ^declare\ $expected_type ]]; then
    case "$expected_type" in
      -A) radp_log_error "'$var_name' must be an associative array." ;;
      -a) radp_log_error "'$var_name' must be an indexed array." ;;
      -i) radp_log_error "'$var_name' must be an integer." ;;
      *) radp_log_error "'$var_name' type mismatch, expected type was '$expected_type'." ;;
    esac
    return 1
  fi

  return 0 # Type matches
}

#######################################
# 检查数组中是否包含指定元素
# 遍历数组，如果发现数组中有元素与指定元素相等，则立即返回状态码 0。
# 如果遍历完成后未找到匹配的元素，则返回状态码 1。
# Arguments:
#  1 - element: 需要检查的元素
#  2...n - arr: 数组
# Returns:
#   0 - 如果数组中包含元素，返回 0
#   1 - 如果数组中不包含元素，返回 1
# Examples:
#  local arr=(apple banana orange)
#  radp_lang_check_if_arr_contains "apple" "${arr[@]}"
#######################################
function radp_lang_check_if_arr_contains() {
  local element=${1:?}
  shift
  local arr=("$@")
  local e
  for e in "${arr[@]}"; do
    if [[ "$e" == "$element" ]]; then
      return 0
    fi
  done
  return 1
}

#######################################
# 添加元素到数组中，并保证该数组中的元素具备唯一性
# Arguments:
#   1 - element: 待添加的元素
#   2 - __nr_array_ref__: 目标数组变量
# Returns:
#   1 - 如果目标数组不是集合，或者待添加的元素集合中已经存在
#######################################
function radp_nr_lang_add_item_to_set() {
  local element=${1:?}
  local -n __nr_array_ref__=${2:?}

  radp_lang_check_var_type __nr_array_ref__ -a || return 1
  if ! radp_lang_check_if_arr_contains "$element" "${__nr_array_ref__[@]}"; then
    __nr_array_ref__+=("$element")
  else
    radp_log_debug "Skip to add because duplicate element '$element'"
    return 1
  fi
}

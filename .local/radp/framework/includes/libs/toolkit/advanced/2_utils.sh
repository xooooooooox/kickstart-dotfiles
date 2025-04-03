#!/usr/bin/env bash

#######################################
# 将关联数组转化为string，供日志输出
# Globals:
#   None
# Arguments:
#   1 - __nr_arr__: 关联数组
#######################################
function radp_nr_utils_print_assoc_arr() {
  local -n __nr_arr__=${1:?}
  local content=" =>\n(\n"

  local key
  for key in "${!__nr_arr__[@]}"; do
    content+="[$key]=${__nr_arr__[$key]}\n"
  done
  echo "${content})"
}

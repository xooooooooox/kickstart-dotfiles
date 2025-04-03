#!/usr/bin/env bash

# shellcheck source=./../../bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#######################################
# 使用 yq 解析 YAML 数据，并将结果存储在命名引用变量中
# Globals:
#   无
# Arguments:
#   1 - <type>: 解析数据的类型 (-A 关联数组, -a 索引数组, -s 字符串, -i 整数)
#   2 - <__nr_parsed_properties__>: 将数据存储的命名引用变量
#   3 - <query>: yq 路径表达式，指定要提取的数据
#   4 - <yaml_file>: YAML 文件的路径
# Returns:
#   成功返回 0, 不支持的类型返回 1
# Examples:
#   local -A map
#   radp_plugin_yq_nr_parse_yaml -A map ".vagrant.x" '/path/to/file/yaml'
#######################################
function radp_plugin_yq_nr_parse_yaml() {
  local type=${1:?}
  local -n __nr_parsed_properties__=${2:?}
  local query=${3:?}
  local yaml_file=${4:?}

  local yq_result
  case "$type" in
    -A | --map)
      # 使用 yq 输出 Bash 可解析的键值对形式，用于关联数组
      yq_result=$(__framework_plugin_yq_safe_call "$query | to_entries | .[] | \"\(.key)=\(.value)\"" "$yaml_file") || return 1
      local entries entry
      mapfile -t entries <<<"$yq_result"
      for entry in "${entries[@]}"; do
        local key="${entry%%=*}"
        local value="${entry#*=}"
        value="${value%\"}" # 去除尾部引号
        value="${value#\"}" # 去除头部引号
        __nr_parsed_properties__["$key"]="$value"
      done
      ;;
    -a | --array)
      # 使用 yq 直接解析为索引数组
      yq_result=$(__framework_plugin_yq_safe_call "$query " "$yaml_file") || return 1
      mapfile -t __nr_parsed_properties__ <<<"$yq_result"
      ;;
    -s | --string)
      # 解析为字符串
      # shellcheck disable=SC2178
      __nr_parsed_properties__=$(__framework_plugin_yq_safe_call "$query" "$yaml_file") || return 1
      ;;
    -i | --integer)
      # 解析为整数
      # shellcheck disable=SC2178
      __nr_parsed_properties__=$(__framework_plugin_yq_safe_call "$query" "$yaml_file") || return 1
      ;;
    *)
      echo "Unsupported type. Available types: -A (map), -a (array), -s (string), -i (integer)"
      return 1
      ;;
  esac
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function __framework_plugin_yq_safe_call() {
  local query=${1:?}
  local file=${2:?}

  local result
  if result=$(yq "$query" "$file" 2>/dev/null); then
    echo "$result"
  else
    radp_log_error "Failed to execute yq with query '$query' on file '$file'"
    return 1
  fi
}

function _install_yq_by_binary() {
  local url=${g_settings_assoc_plugin_yq['url']}
  if radp_utils_run radp_utils_retry -- "$g_sudo wget --no-check-cert --progress=bar:force $url -O /usr/bin/yq"; then
    radp_utils_run "$g_sudo chmod +x /usr/bin/yq" || return 1
  else
    radp_log_error "failed to download yq '$url'"
    return 1
  fi
}

function _install_yq_by_pkg_manager() {
  if command -v brew >/dev/null; then
    brew install yq
  fi
}

#######################################
# 初始化插件
# Globals:
#   g_plugin_yq_config - @see g_settings_str_plugin_yq
#   g_sudo
# Arguments:
#  None
# Returns:
#   1 ...
#
# @see radp_get_settings_value
#######################################
function __framework_plugin_yq_setup() {
  # 安装 yq
  if ! command -v yq >/dev/null; then
    local _ distro_id
    IFS=':' read -r distro_id _ _ _ < <(radp_os_get_distro_info)
    local yq_version=${g_settings_assoc_plugin_yq['version']}
    case "$distro_id" in
      osx)
        if ! radp_utils_run "brew install yq"; then
          radp_log_error "failed to install yq"
          return 1
        fi
        ;;
      *)
        _install_yq_by_binary || return 1
        ;;
    esac
    radp_log_info "yq $yq_version installed."
  fi
}

function main() {
  __framework_plugin_yq_setup
}

main

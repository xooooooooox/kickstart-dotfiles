#!/usr/bin/env bash

function radp_alias_brew() {
  local args=("$@")
  if ! command -v brew >/dev/null 2>&1; then
    radp_log_error "Homebrew not installed."
  fi
  brew "${args[@]}" || return 1
}

function radp_alias_apt_get() {
  local args=("$@")
  if ! command -v apt-get >/dev/null 2>&1; then
    radp_log_error "command apt-get not found"
  fi
  # 由于 http_proxy 对于 sudo 执行可能会失效
  # 所以这里通过手动设定代理进行再一次尝试
  $g_sudo apt-get "${args[@]}" || {
    radp_log_warn "Retry apt-get ${args[*]} with proxy $gx_http_proxy"
    $g_sudo apt-get -o Acquire::http::Proxy="$gx_http_proxy" "${args[@]}"
  } || return 1
}

# shellcheck disable=SC1090
function radp_alias_source() {
  local cur_shell
  cur_shell=$(ps -p $$ -ocomm=)
  case $cur_shell in
    zsh)
      radp_log_info "source $HOME/.zshrc"
      source "$HOME"/.zshrc || return 1
      ;;
    bash)
      radp_log_info "source $HOME/.bashrc"
      source "$HOME"/.bashrc || return 1
      ;;
  esac
}

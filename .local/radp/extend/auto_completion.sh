#!/usr/bin/env bash

#######################################
# 用户扩展全局变量自动补全
# Arguments:
#  None
#######################################
function __auto_completion_user_vars() {
  # 1. constants

  # 2. configurable vars
  # shellcheck source=vars/configurable/configurable_vars.sh

  # 3. dynamic vars
  # shellcheck source=vars/dynamic/proxy_runtime.sh
  :
}

#######################################
# 用户扩展通用库函数自动补全
# Arguments:
#  None
#######################################
function __auto_completion_user_libs() {

  # shellcheck source=libs/omg/omg_bat.sh
  # shellcheck source=libs/omg/omg_colorls.sh
  # shellcheck source=libs/omg/omg_fastfetch.sh
  # shellcheck source=libs/omg/omg_fd.sh
  # shellcheck source=libs/omg/omg_fzf.sh
  # shellcheck source=libs/omg/omg_git.sh
  # shellcheck source=libs/omg/omg_git_credential_manager.sh
  # shellcheck source=libs/omg/omg_goenv.sh
  # shellcheck source=libs/omg/omg_gpg.sh
  # shellcheck source=libs/omg/omg_helm.sh
  # shellcheck source=libs/omg/omg_jdk.sh
  # shellcheck source=libs/omg/omg_jq.sh
  # shellcheck source=libs/omg/omg_lazygit.sh
  # shellcheck source=libs/omg/omg_kubecm.sh
  # shellcheck source=libs/omg/omg_kubectl.sh
  # shellcheck source=libs/omg/omg_markdownlint_cli.sh
  # shellcheck source=libs/omg/omg_mvn.sh
  # shellcheck source=libs/omg/omg_neovim.sh
  # shellcheck source=libs/omg/omg_nodejs.sh
  # shellcheck source=libs/omg/omg_pass.sh
  # shellcheck source=libs/omg/omg_python.sh
  # shellcheck source=libs/omg/omg_radpctl.sh
  # shellcheck source=libs/omg/omg_ruby.sh
  # shellcheck source=libs/omg/omg_shellcheck.sh
  # shellcheck source=libs/omg/omg_telepresence.sh
  # shellcheck source=libs/omg/omg_tig.sh
  # shellcheck source=libs/omg/omg_tmux.sh
  # shellcheck source=libs/omg/omg_vim.sh
  # shellcheck source=libs/omg/omg_yadm.sh
  # shellcheck source=libs/omg/omg_zoxide.sh
  # shellcheck source=libs/omg/omg_zsh.sh

  # shellcheck source=libs/docker/docker_utils.sh
  :
}

#######################################
# 用户集成库函数自动补全
# Arguments:
#  None
#######################################
function __auto_completion_user_integrations() {
  :
}

#######################################
# 用户扩展插件自动补全
# Arguments:
#  None
#######################################
function __auto_completion_user_plugins() {
  :
}

function main() {
  __auto_completion_user_vars
  __auto_completion_user_libs
  __auto_completion_user_integrations
  __auto_completion_user_plugins
}

main

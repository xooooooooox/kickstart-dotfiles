#!/usr/bin/env bash

if ! yadm untracked >/dev/null 2>&1; then
  # 这里借助 sh -c, 避免 $HOME 需要写死的问题
  yadm gitconfig alias.untracked '!sh -c "$HOME/.config/yadm/commands/yadm-untracked"'
fi

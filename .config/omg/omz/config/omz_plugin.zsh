_zsh_syntax_highlighting_dracula(){
    # Dracula Theme (for zsh-syntax-highlighting)
    #
    # https://github.com/zenorocha/dracula-theme
    #
    # Copyright 2021, All rights reserved
    #
    # Code licensed under the MIT license
    # http://zenorocha.mit-license.org
    #
    # @author George Pickering <@bigpick>
    # @author Zeno Rocha <hi@zenorocha.com>
    # Paste this files contents inside your ~/.zshrc before you activate zsh-syntax-highlighting
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main cursor)
    typeset -gA ZSH_HIGHLIGHT_STYLES
    # Default groupings per, https://spec.draculatheme.com, try to logically separate
    # possible ZSH_HIGHLIGHT_STYLES settings accordingly...?
    #
    # Italics not yet supported by zsh; potentially soon:
    #    https://github.com/zsh-users/zsh-syntax-highlighting/issues/432
    #    https://www.zsh.org/mla/workers/2021/msg00678.html
    # ... in hopes that they will, labelling accordingly with ,italic where appropriate
    #
    # Main highlighter styling: https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md
    #
    ## General
    ### Diffs
    ### Markup
    ## Classes
    ## Comments
    ZSH_HIGHLIGHT_STYLES[comment]='fg=#6272A4'
    ## Constants
    ## Entitites
    ## Functions/methods
    ZSH_HIGHLIGHT_STYLES[alias]='fg=#50FA7B'
    ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#50FA7B'
    ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#50FA7B'
    ZSH_HIGHLIGHT_STYLES[function]='fg=#50FA7B'
    ZSH_HIGHLIGHT_STYLES[command]='fg=#50FA7B'
    ZSH_HIGHLIGHT_STYLES[precommand]='fg=#50FA7B,italic'
    ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#FFB86C,italic'
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#FFB86C'
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#FFB86C'
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#BD93F9'
    ## Keywords
    ## Built ins
    ZSH_HIGHLIGHT_STYLES[builtin]='fg=#8BE9FD'
    ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#8BE9FD'
    ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#8BE9FD'
    ## Punctuation
    ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#FF79C6'
    ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=#F8F8F2'
    ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-unquoted]='fg=#F8F8F2'
    ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=#F8F8F2'
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg=#FF79C6'
    ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#FF79C6'
    ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#FF79C6'
    ## Serializable / Configuration Languages
    ## Storage
    ## Strings
    ZSH_HIGHLIGHT_STYLES[command-substitution-quoted]='fg=#F1FA8C'
    ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-quoted]='fg=#F1FA8C'
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#F1FA8C'
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]='fg=#FF5555'
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#F1FA8C'
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]='fg=#FF5555'
    ZSH_HIGHLIGHT_STYLES[rc-quote]='fg=#F1FA8C'
    ## Variables
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#F8F8F2'
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]='fg=#FF5555'
    ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#F8F8F2'
    ZSH_HIGHLIGHT_STYLES[assign]='fg=#F8F8F2'
    ZSH_HIGHLIGHT_STYLES[named-fd]='fg=#F8F8F2'
    ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg=#F8F8F2'
    ## No category relevant in spec
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#FF5555'
    ZSH_HIGHLIGHT_STYLES[path]='fg=#F8F8F2'
    ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#FF79C6'
    ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#F8F8F2'
    ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=#FF79C6'
    ZSH_HIGHLIGHT_STYLES[globbing]='fg=#F8F8F2'
    ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#BD93F9'
    #ZSH_HIGHLIGHT_STYLES[command-substitution]='fg=?'
    #ZSH_HIGHLIGHT_STYLES[command-substitution-unquoted]='fg=?'
    #ZSH_HIGHLIGHT_STYLES[process-substitution]='fg=?'
    #ZSH_HIGHLIGHT_STYLES[arithmetic-expansion]='fg=?'
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument-unclosed]='fg=#FF5555'
    ZSH_HIGHLIGHT_STYLES[redirection]='fg=#F8F8F2'
    ZSH_HIGHLIGHT_STYLES[arg0]='fg=#F8F8F2'
    ZSH_HIGHLIGHT_STYLES[default]='fg=#F8F8F2'
    ZSH_HIGHLIGHT_STYLES[cursor]='standout'
}

_omg_omz_plugin_zsh_autosuggestions(){
    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]];then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi

    export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
}

_omg_omz_plugin_you_should_use(){
    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use ]];then
        git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use
    fi

    export YSU_MESSAGE_POSITION="after"
}

_omg_omz_plugin_zsh_vi_mode(){
    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-vi-mode ]];then
        git clone https://github.com/jeffreytse/zsh-vi-mode ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-vi-mode
    fi

    # Only changing the escape key to `jk` in insert mode, we still
    # keep using the default keybindings `^[` in other modes
    typeset -g ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
}


_omg_omz_plugin_zsh_syntax_highlighting(){
    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]];then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi

    # Gruvboxdark color scheme 下，命令行高亮看起来很暗，对比度不够
    _zsh_syntax_highlighting_dracula
}

_omg_omz_plugin_zsh_history_substring_search(){
    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search ]];then
        git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
    fi
    :
}

_omg_omz_plugin_zsh_nvm(){
    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-nvm ]];then
        git clone https://github.com/lukechilds/zsh-nvm ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-nvm
    fi
}

_omg_omz_plugin_nvm(){
    # 懒加载 nvm,不然 zsh startup slow
    zstyle ':omz:plugins:nvm' lazy yes
    # zstyle ':omz:plugins:nvm' lazy-cmd eslint prettier typescript
    export NVM_COMPLETION=true
    export NVM_LAZY_LOAD=true
}

_omg_omz_plugin_zsh_better_npm_completion(){
    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-better-npm-completion ]];then
        git clone https://github.com/lukechilds/zsh-better-npm-completion ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-better-npm-completion
    fi
}

_omg_omz_plugin_zsh_bat(){
    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-bat ]];then
        git clone https://github.com/fdellwing/zsh-bat.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-bat
    fi
}

_omg_omz_plugin_fzf_tab(){
    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab ]];then
        git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab
    fi
}

_omg_omz_plugin_docker(){
    zstyle ':completion:*:*:docker:*' option-stacking yes
    zstyle ':completion:*:*:docker-*:*' option-stacking yes
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#-------------------------------------------------------------------------------------#
omg_omz_plugins() {
    local enabled_plugins=("$@")
    local pl
    for pl in "${enabled_plugins[@]}";do
        pl=${pl//-/_}
        if command -v _omg_omz_plugin_"$pl" >/dev/null 2>&1;then
            _omg_omz_plugin_"$pl"
        fi
    done
}


omg_omz_plugins "$@"

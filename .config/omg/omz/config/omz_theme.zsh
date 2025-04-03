_p10k_setup(){
    local target_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    if [[ ! -d $target_dir ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$target_dir"
        omz reload
    fi
}

_omg_omz_theme_p10k(){
    local prompt_style=${1:-rainbow}
    _p10k_setup
    # 如果需要修改 powerlevel10k 的设置，直接修改对应的 p10k_xxx.zsh 即可
    local cur_dir="${OMG_ROOT}"/omz/config
    [[ ! -f ${cur_dir}/themes/p10k_${prompt_style}.zsh ]] || source ${cur_dir}/themes/p10k_${prompt_style}.zsh
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#-------------------------------------------------------------------------------------#
omg_omz_theme() {
    local theme="${1:-p10k}"
    local prompt_style=${2:-}
    case "$theme" in
    p10k|powerlevel10k|powerlevel10k/powerlevel10k)
        _omg_omz_theme_p10k "${prompt_style}"
        ;;
    *)
        echo "Invalid oh-my-zsh theme '$theme_to_use', use ohmyzsh default theme 'robbyrussell'"
        omg_omz "$ZSH" "$ZSH_CUSTOM" 'robbyrussell'
        ;;
    esac
}

omg_omz_theme "$@"

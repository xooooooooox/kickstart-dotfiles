#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#---------------------------------- 不用改 -------------------------------------------#
_omz_install() {
    local zsh_install_path=${1:?}
    if ! command -v git >/dev/null 2>&1;then
      (brew install git || sudo yum install -y git || sudo dnf install -y git || agt-get install -y git) 2>/dev/null
    fi
    local tmp_dir
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || return 1
    export ZSH="$zsh_install_path"
    wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh || return 1
    chmod +x install.sh
    ./install.sh --unattended || return 1
    popd || reutrn 1
}
#-------------------------------------------------------------------------------------#
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#---------------------------------- oh-my-zsh [config] --------------------------------#

_omz_internal_settings() {
# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#---------------------------------- oh-my-zsh [main] --------------------------------#
export ZSH="${1:-$HOME/.oh-my-zsh}"
typeset -g ZSH_CUSTOM="${2:-$HOME/.oh-my-zsh/custom}"
typeset -g ZSH_THEME="${3:-powerlevel10k/powerlevel10k}"
prompt_style_to_use=${4:-}

# install oh-my-zsh
if [[ ! -f "$ZSH"/oh-my-zsh.sh ]]; then
    _omz_install "$ZSH"
fi

# oh-my-zsh 设置项
_omz_internal_settings

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
git
tig
zsh-vi-mode
zsh-history-substring-search
zsh-autosuggestions
you-should-use
zsh-syntax-highlighting
fzf
fzf-tab
brew
gitignore
nvm
zsh-nvm
zsh-better-npm-completion
jenv
pyenv
rbenv
cp
command-not-found
colored-man-pages
safe-paste
extract
web-search
jsontools
copypath
copyfile
copybuffer
history
docker
docker-compose
macos
vagrant
dash
minikube
helm
kubectl
zsh-bat
golang
zoxide
mvn
aliases
)
source "$OMG_ROOT"/omz/config/omz_plugin.zsh "${plugins[@]}"

source $ZSH/oh-my-zsh.sh

source "$OMG_ROOT"/omz/config/omz_theme.zsh "${ZSH_THEME}" "${prompt_style_to_use}"
#-------------------------------------------------------------------------------------#
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

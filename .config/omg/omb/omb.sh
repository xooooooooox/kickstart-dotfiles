_omb_install() {
  local osh_install_path=${1:?}
  if ! command -v git >/dev/null 2>&1; then
    (brew install git || sudo yum install -y git || sudo dnf install -y git || agt-get install -y git) 2>/dev/null
  fi
  local tmp_dir
  tmp_dir=$(mktemp -d)
  pushd "$tmp_dir" || return 1
  export OSH="$osh_install_path"
  wget https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh || return 1
  chmod +x install.sh
  ./install.sh --unattended || return 1
  popd || return 1
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#---------------------------------- oh-my-bash [config] --------------------------------#
# oh-my-bash 默认支持的设置项
# 注意: 记得在前面加上 declare -g
_omb_internal_settings() {
  # Uncomment the following line to use case-sensitive completion.
  # OMB_CASE_SENSITIVE="true"

  # Uncomment the following line to use hyphen-insensitive completion. Case
  # sensitive completion must be off. _ and - will be interchangeable.
  # OMB_HYPHEN_SENSITIVE="false"

  # Uncomment the following line to disable bi-weekly auto-update checks.
  # DISABLE_AUTO_UPDATE="true"

  # Uncomment the following line to change how often to auto-update (in days).
  # export UPDATE_OSH_DAYS=13

  # Uncomment the following line to disable colors in ls.
  # DISABLE_LS_COLORS="true"

  # Uncomment the following line to disable auto-setting terminal title.
  # DISABLE_AUTO_TITLE="true"

  # Uncomment the following line to enable command auto-correction.
  # ENABLE_CORRECTION="true"

  # Uncomment the following line to display red dots whilst waiting for completion.
  # COMPLETION_WAITING_DOTS="true"

  # Uncomment the following line if you want to disable marking untracked files
  # under VCS as dirty. This makes repository status check for large repositories
  # much, much faster.
  # DISABLE_UNTRACKED_FILES_DIRTY="true"

  # Uncomment the following line if you don't want the repository to be considered dirty
  # if there are untracked files.
  # SCM_GIT_DISABLE_UNTRACKED_DIRTY="true"

  # Uncomment the following line if you want to completely ignore the presence
  # of untracked files in the repository.
  # SCM_GIT_IGNORE_UNTRACKED="true"

  # Uncomment the following line if you want to change the command execution time
  # stamp shown in the history command output.  One of the following values can
  # be used to specify the timestamp format.
  # * 'mm/dd/yyyy'     # mm/dd/yyyy + time
  # * 'dd.mm.yyyy'     # dd.mm.yyyy + time
  # * 'yyyy-mm-dd'     # yyyy-mm-dd + time
  # * '[mm/dd/yyyy]'   # [mm/dd/yyyy] + [time] with colors
  # * '[dd.mm.yyyy]'   # [dd.mm.yyyy] + [time] with colors
  # * '[yyyy-mm-dd]'   # [yyyy-mm-dd] + [time] with colors
  # If not set, the default value is 'yyyy-mm-dd'.
  # HIST_STAMPS='yyyy-mm-dd'

  # Uncomment the following line if you do not want OMB to overwrite the existing
  # aliases by the default OMB aliases defined in lib/*.sh
  # OMB_DEFAULT_ALIASES="check"

  # To disable the uses of "sudo" by oh-my-bash, please set "false" to
  # this variable.  The default behavior for the empty value is "true".
  declare -g OMB_USE_SUDO=true

  # To enable/disable display of Python virtualenv and condaenv
  # OMB_PROMPT_SHOW_PYTHON_VENV=true  # enable
  # OMB_PROMPT_SHOW_PYTHON_VENV=false # disable
}

_omb_theme_setting() {
  local theme_to_use=${1:?}
  local custom_theme_settings_file="${OMG_ROOT}/omb/config/themes/${theme_to_use}.sh"

  if [[ -f "$custom_theme_settings_file" ]]; then
    source "${custom_theme_settings_file}"
  fi
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#---------------------------------- oh-my-bash [main] --------------------------------#
# Enable the subsequent settings only in interactive sessions
case $- in
*i*) ;;
*) return ;;
esac

# Path to your oh-my-bash installation.
export OSH="${1:-$HOME/.oh-my-bash}"
declare -g OSH_CUSTOM=${2:-$HOME/.oh-my-bash/custom}
declare -g OSH_THEME="${3:-font}"

# oh-my-bash install
if [[ ! -f "$OSH"/oh-my-bash.sh ]]; then
  _omb_install "$OSH"
fi

# oh-my-bash 设置项
_omb_internal_settings
_omb_theme_setting "$OSH_THEME"

# Which completions would you like to load? (completions can be found in ~/.oh-my-bash/completions/*)
# Custom completions may be added to ~/.oh-my-bash/custom/completions/
# Example format: completions=(ssh git bundler gem pip pip3)
# Add wisely, as too many completions slow down shell startup.
completions=(
  git
  composer
  ssh
  nvm
)

# Which aliases would you like to load? (aliases can be found in ~/.oh-my-bash/aliases/*)
# Custom aliases may be added to ~/.oh-my-bash/custom/aliases/
# Example format: aliases=(vagrant composer git-avh)
# Add wisely, as too many aliases slow down shell startup.
aliases=(
  general
)

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-bash/plugins/*)
# Custom plugins may be added to ~/.oh-my-bash/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  bashmarks
)

# Which plugins would you like to conditionally load? (plugins can be found in ~/.oh-my-bash/plugins/*)
# Custom plugins may be added to ~/.oh-my-bash/custom/plugins/
# Example format:
#  if [ "$DISPLAY" ] || [ "$SSH" ]; then
#      plugins+=(tmux-autoattach)
#  fi

source "$OSH"/oh-my-bash.sh
#-------------------------------------------------------------------------------------#
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

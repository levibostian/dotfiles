# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="dracula"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

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

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git asdf)

# always answers "yes" to the "update oh my zsh?" prompt. 
# MUST be set before sourcing oh-my-zsh.sh
# docs: https://github.com/ohmyzsh/ohmyzsh#getting-updates
zstyle ':omz:update' mode auto

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Homebrew
# 
# put this towards the top of the file so we can use "brew" commands in the rest of the file
eval "$(/opt/homebrew/bin/brew shellenv)"

# zsh-autosuggestions
# 
# Install: brew install zsh-autosuggestions
# That is all you need to do to install it because of the lines below. 
# docs for homebrew install method: https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#homebrew
# 
# Customize zsh-autosuggestions (auto complete)
# https://github.com/zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# github copilot suggest a bash command. 
# requires github copilot cli: brew install copilot-cli
# Use: `suggest "homebrew show outdated"`
suggest() {
    copilot --prompt "suggest a bash command for the given input. ONLY respond with the command, do not include any explanations or additional text, newline characters, or \`\`\`. Here is the input: $1" --silent 
}

# homebrew 
# run command to do all the updates. 
alias brew-update='brew update && brew install --cask --force `brew list --cask` && brew cleanup -s && brew cleanup --prune 0 && rm -rf "$(brew --cache)"'

# fixes sublime merge to find langs installed with asdf
# https://github.com/sublimehq/sublime_merge/issues/1106#issuecomment-807701130
export PATH="${HOME}/.asdf/shims:${PATH}:$PATH"

# Android
#
# sometimes gradle asks you for ANDROID_HOME to run when you download an open source Android app and try running it 
export ANDROID_HOME=~/Library/Android/sdk

# nest (swift CLIs)
export PATH="$PATH:${HOME}/.nest/bin"

# Set default applications for various file types
if [[ -f "$HOME/.dotfiles/default-apps.sh" ]]; then
    "$HOME/.dotfiles/default-apps.sh" > /dev/null 2>&1  # Run silently to avoid cluttering terminal output
fi

# uv - python package manager
export PATH="$HOME/.local/bin:$PATH"

# autowt 
alias wt='autowt'
export AUTOWT_WORKTREE_DIRECTORY_PATTERN="../{branch}"
export AUTOWT_CLEANUP_DEFAULT_MODE="github"

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section


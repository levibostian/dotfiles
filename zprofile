# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
# Alias to do a full homebrew update.
alias brew-update='brew update && brew upgrade && brew install --cask --force `brew list --cask` && brew cleanup -s && brew cleanup --prune 0 && rm -rf "$(brew --cache)"'

# mise
#
# Activation handled by oh-my-zsh `mise` plugin in ~/.zshrc.
# Keep this file free of `mise activate ...` to avoid duplicate hooks.

# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

# Note: Sublime merge uses only this file and not .zshrc, so I have to add these lines here to get the PATH updates in sublime merge.
# 
# binnys - a personal collection of scripts that I want added to path 
export PATH="$HOME/.binnys:$PATH"

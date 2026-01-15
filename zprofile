# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
# Alias to do a full homebrew update.
alias brew-update='brew update && brew upgrade && brew install --cask --force `brew list --cask` && brew cleanup -s && brew cleanup --prune 0 && rm -rf "$(brew --cache)"'

# asdf
#
# Adds directories to my PATH which allows programs like sublime merge
# to be able to find the language binaries to use.
#if [ -d "$HOME/.asdf" ]; then
#  . $HOME/.asdf/asdf.sh
#  . $HOME/.asdf/completions/asdf.bash
#fi
export PATH="$HOME/.asdf/shims:$PATH"
export PATH="$HOME/.asdf/bin:$PATH"
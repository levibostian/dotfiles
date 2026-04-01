# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
# Alias to do a full homebrew update.
alias brew-update='brew update && brew upgrade && brew install --cask --force `brew list --cask` && brew cleanup -s && brew cleanup --prune 0 && rm -rf "$(brew --cache)"'

# mise 
#
# fixes sublime merge to find langs installed with asdf
# https://github.com/sublimehq/sublime_merge/issues/1106#issuecomment-807701130
# 
# docs to get this command: 
# https://mise.jdx.dev/dev-tools/shims.html#how-to-add-mise-shims-to-path
eval "$(mise activate zsh --shims)"

# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

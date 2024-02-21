# colors and styles the $ prompt. 
# Designed specifically for item theme: https://draculatheme.com/iterm
RED='\[\e[1;31m\]'
GREEN='\[\e[1;32m\]'
YELLOW='\[\e[1;33m\]'
BLUE='\[\e[1;34m\]'
PURPLE='\[\e[1;35m\]'
CYAN='\[\e[1;36m\]'
WHITE='\[\e[1;37m\]'
GIT_BRANCH='`git branch 2> /dev/null | grep -e ^* | sed -E  s/^\\\\\*\ \(.+\)$/\(\\\\\1\)\ /`'
export PS1="$BLUE\u:$CYAN\w $GREEN$GIT_BRANCH$BLUE$\[\e[m\] "

# Add ssh keys to agent to not have to have you type in your password when using SSH keys anymore
# ssh-add -A

# git auto complete
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

alias gwd='gh browse --branch $(git branch-name)' # open the current directory repo in browser. requires https://cli.github.com/

# homebrew stuff, https://docs.brew.sh/Shell-Completion
if type brew &>/dev/null; then
  HOMEBREW_PREFIX="$(brew --prefix)"
  if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
    source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
  else
    for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
      [[ -r "$COMPLETION" ]] && source "$COMPLETION"
    done
  fi
fi

# Deno 
# 
# Allows running executables installed
export PATH="/Users/$USER/.deno/bin:$PATH"

# iterm2 integration. https://iterm2.com/documentation-shell-integration.html
source ~/.iterm2_shell_integration.bash

#
# Android
#
# Add `adb` to path for using as a CLI
export ANDROID_HOME=/Users/$USER/Library/Android/sdk
export PATH=${PATH}:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
# thanks https://stackoverflow.com/a/48266060
alias studio='open -b com.google.android.studio' # allows you to run 'studio .' to open project in android studio

# gcloud SDK adding to path 
# install gcloud: https://gist.github.com/levibostian/8e578cee23ed6b8c078561f8302660e5
# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/apps/google-cloud-sdk/path.bash.inc" ]; then . "$HOME/apps/google-cloud-sdk/path.bash.inc"; fi
# The next line enables shell command completion for gcloud.
if [ -f "$HOME/apps/google-cloud-sdk/completion.bash.inc" ]; then . "$HOME/apps/google-cloud-sdk/completion.bash.inc"; fi

# asdf, install langs
# https://asdf-vm.com/guide/getting-started.html
. /usr/local/opt/asdf/libexec/asdf.sh

# allow using a private bashrc file, if you wish. 
# thanks, https://stackoverflow.com/a/32107680
if [ -f $HOME/.bashrc_private ]; then
    . $HOME/.bashrc_private
    echo ".bashrc_private loaded"
fi

#
# Misc
#
# Handy to get local IP for setting up proxy on mobile devices to this computer
alias localip='ipconfig getifaddr en0'

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
ssh-add -A

# git auto complete
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

alias gwd='gh browse --branch $(git branch-name)' # open the current directory repo in browser. requires https://cli.github.com/

# rbenv stuff
## This script below initializes rbenv for the current session. we will 'eval' it so that every shell session has rbenv setup and ready to go. 
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Java 
# Use brew with a tap to install Java versions. 
# Using this --> https://adoptium.net/installation/, it's the updated version of https://github.com/AdoptOpenJDK/homebrew-openjdk
#
# brew install --cask temurin  # installs tool 
# brew tap homebrew/cask-versions # captures all of the available verions you can download 
# brew install --cask temurin8 # installs a version of java 
# 
# if you ever want to change the version of java being used, just run `javaX` where X is the major version you want. Example `java11` will enable java 11. 
export JAVA_8_HOME=$(/usr/libexec/java_home -v1.8)
export JAVA_9_HOME=$(/usr/libexec/java_home -v9)
export JAVA_10_HOME=$(/usr/libexec/java_home -v10)
export JAVA_11_HOME=$(/usr/libexec/java_home -v11)
export JAVA_12_HOME=$(/usr/libexec/java_home -v12)
export JAVA_13_HOME=$(/usr/libexec/java_home -v13)
export JAVA_14_HOME=$(/usr/libexec/java_home -v14)
export JAVA_15_HOME=$(/usr/libexec/java_home -v15)
export JAVA_16_HOME=$(/usr/libexec/java_home -v16)
export JAVA_17_HOME=$(/usr/libexec/java_home -v17)
export JAVA_18_HOME=$(/usr/libexec/java_home -v18)
export JAVA_19_HOME=$(/usr/libexec/java_home -v19)
export JAVA_20_HOME=$(/usr/libexec/java_home -v20)
#
alias java8='export JAVA_HOME=$JAVA_8_HOME'
alias java9='export JAVA_HOME=$JAVA_9_HOME'
alias java10='export JAVA_HOME=$JAVA_10_HOME'
alias java11='export JAVA_HOME=$JAVA_11_HOME'
alias java12='export JAVA_HOME=$JAVA_12_HOME'
alias java13='export JAVA_HOME=$JAVA_13_HOME'
alias java14='export JAVA_HOME=$JAVA_14_HOME'
alias java16='export JAVA_HOME=$JAVA_16_HOME'
alias java17='export JAVA_HOME=$JAVA_17_HOME'
alias java18='export JAVA_HOME=$JAVA_18_HOME'
alias java19='export JAVA_HOME=$JAVA_19_HOME'
alias java20='export JAVA_HOME=$JAVA_20_HOME'
# In order to use a version of java, it must be installed. 
# See what versions you have installed now:
alias javals='ls /Library/Java/JavaVirtualMachines/'
# use `brew search temurin` to find all of the versions of java you *can* install.
#
# can set default if you want by uncommenting below:
java20
# 
alias javav='java --version' 

# NVM stuff
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

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

# kubernetes
## autocomplete
source <(kubectl completion bash)
alias k='kubectl'
alias kc='kubectx'
alias kn='kubens'

# helm
helm completion bash | bash

# go dev
# From: https://ahmadawais.com/install-go-lang-on-macos-with-homebrew/
# Assumes that you install go with `brew install go`
export GOPATH="${HOME}/.go"
export GOROOT="$(brew --prefix golang)/libexec"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"
test -d "${GOPATH}" || mkdir "${GOPATH}"
test -d "${GOPATH}/src/github.com" || mkdir -p "${GOPATH}/src/github.com"

# iterm2 integration. https://iterm2.com/documentation-shell-integration.html
source ~/.iterm2_shell_integration.bash

# transfer.sh service. Alias that allows you to simply use `transfer ...`
transfer() { if [ $# -eq 0 ]; then echo -e "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"; return 1; fi
tmpfile=$( mktemp -t transferXXX ); if tty -s; then basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g'); curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile; else curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ; fi; cat $tmpfile; rm -f $tmpfile; } 

#
# Android
#
# Add `adb` to path for using as a CLI
export ANDROID_HOME=/Users/$USER/Library/Android/sdk
export PATH=${PATH}:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
# thanks https://stackoverflow.com/a/48266060
alias studio='open -b com.google.android.studio' # allows you to run 'studio .' to open project in android studio

# Python (with pyenv)
# got this from 'pyenv init'
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# gcloud SDK adding to path 
# install gcloud: https://gist.github.com/levibostian/8e578cee23ed6b8c078561f8302660e5
# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/apps/google-cloud-sdk/path.bash.inc" ]; then . "$HOME/apps/google-cloud-sdk/path.bash.inc"; fi
# The next line enables shell command completion for gcloud.
if [ -f "$HOME/apps/google-cloud-sdk/completion.bash.inc" ]; then . "$HOME/apps/google-cloud-sdk/completion.bash.inc"; fi

# sed 
# the default sed CLI that's installed with macos isn't the same as linux so you might have some weird behavior. 
# to fix this problem, install gnu sed and set it as the default sed program on the machine. 
# Install gnu sed from homebrew and the install script gives you instructions on how to make gnu sed the default. 
# From: https://gist.github.com/andre3k1/e3a1a7133fded5de5a9ee99c87c6fa0d
PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"

# bat (a more powerful cat)
# https://github.com/sharkdp/bat
if ! [ -x "$(command -v bat)" ]; then
  echo "Install bat if you want a more powerful cat https://github.com/sharkdp/bat#installation"
else
  alias cat='bat'
fi

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

# colors and styles the $ prompt. 
export PS1='\[\e[1;32m\]\u@\h:\[\e[0;31m\]\w$\[\e[m\] '

# Add ssh keys to agent to not have to have you type in your password when using SSH keys anymore
ssh-add -A

# git auto complete
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

alias gwd='gh repo view --web' # open the current directory repo in browser. requires https://cli.github.com/

# rbenv stuff
## This script below initializes rbenv for the current session. we will 'eval' it so that every shell session has rbenv setup and ready to go. 
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Java 
# Use brew with a tap to install Java versions. 
# brew tap AdoptOpenJDK/openjdk    # https://github.com/AdoptOpenJDK/homebrew-openjdk
# brew install --cask adoptopenjdk # this installs the latest version of java. 
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
#
alias java8='export JAVA_HOME=$JAVA_8_HOME'
alias java9='export JAVA_HOME=$JAVA_9_HOME'
alias java10='export JAVA_HOME=$JAVA_10_HOME'
alias java11='export JAVA_HOME=$JAVA_11_HOME'
alias java12='export JAVA_HOME=$JAVA_12_HOME'
alias java13='export JAVA_HOME=$JAVA_13_HOME'
alias java14='export JAVA_HOME=$JAVA_14_HOME'
alias java16='export JAVA_HOME=$JAVA_16_HOME'
# In order to use a version of java, it must be installed. 
# See what versions you have installed now:
alias javals='ls /Library/Java/JavaVirtualMachines/'
# use `brew search adoptopenjdk` to find all of the versions of java you *can* install.
#
# can set default if you want by uncommenting below:
# java15
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

# Add `adb` to path for using as a CLI
export ANDROID_HOME=/Users/$USER/Library/Android/sdk
export PATH=${PATH}:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# pip
export PATH="$HOME/Library/Python/3.9/bin:$PATH"

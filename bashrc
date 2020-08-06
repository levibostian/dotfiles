# colors and styles the $ prompt. 
export PS1='\[\e[1;32m\]\u@\h:\[\e[0;31m\]\w$\[\e[m\] '

# Add ssh keys to agent to not have to have you type in your password when using SSH keys anymore
ssh-add -A

# git auto complete
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

# If using https://hub.github.com/
alias git=hub
alias gwd='hub browse' # open the current directory repo in browser

# rbenv stuff
## This script below initializes rbenv for the current session. we will 'eval' it so that every shell session has rbenv setup and ready to go. 
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# jenv stuff. Don't set JAVA_HOME as jenv will do it for you. 
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

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
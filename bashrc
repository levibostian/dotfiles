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

### Java, Help: https://gist.github.com/levibostian/3c70bd7e78d76454c165a8f32f1ff6e9
export JAVA_11_HOME=$(/usr/libexec/java_home -v11)
alias java11='export JAVA_HOME=$JAVA_11_HOME'
java11 # default to Java 11
### end of java

# rbenv stuff
## This script below initializes rbenv for the current session. we will 'eval' it so that every shell session has rbenv setup and ready to go. 
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# NVM stuff
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="/usr/local/share/rsi/idl/bin:/home/username/anaconda/bin:$PATH"

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


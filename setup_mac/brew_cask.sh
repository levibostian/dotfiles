#!/bin/bash

source "_utils.sh"

############################################################################################
# BREW CASK
############################################################################################

log_header "BREW CASK"

# Check for Homebrew cask, install if we don't have it
if test ! $(brew cask help); then
  log "INFO" "Installing homebrew cask."
  brew install caskroom/cask/brew-cask
fi

# Install apps to /Applications (The default is: /Users/$user/Applications)
log "INFO" "Installing brew cask apps."
while read LINE; do
  log "DEBUG" "Installing app: ${LINE}."
  brew cask install --appdir="/Applications" "${LINE}"
done < <(parse_section_of_config_ini "BREW_CASK")
#!/bin/bash

source "_utils.sh"

############################################################################################
# BREW CASK
############################################################################################

log_header "BREW CASK"


# Install apps to /Applications (The default is: /Users/$user/Applications)
log "INFO" "Installing brew cask apps."
while read LINE; do
  log "DEBUG" "Installing app: ${LINE}."
  brew install --cask --appdir="/Applications" "${LINE}"
done < <(parse_section_of_config_ini "BREW_CASK")

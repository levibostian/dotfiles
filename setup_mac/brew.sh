#!/bin/bash

source "_utils.sh"

############################################################################################
# BREW
############################################################################################

log_header "BREW"

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
  log "INFO" "Installing homebrew."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update homebrew recipes
log "INFO" "Updating homebrew."
brew update
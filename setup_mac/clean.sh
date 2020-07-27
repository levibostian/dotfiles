#!/bin/bash

source "_utils.sh"

############################################################################################
# CLEAN
############################################################################################

log_header "CLEANING"

log "INFO" "Cleaning brew and brew cask."
brew cleanup

log "INFO" "Applying all settings immediatly."
log "DEBUG" "Restarting SystemUIServer."
sudo killall SystemUIServer
log "DEBUG" "Restarting Finder."
sudo killall Finder
log "DEBUG" "Restarting Dock."
sudo killall Dock
#!/bin/bash

source "_utils.sh"

############################################################################################
# LANGS
############################################################################################

log_header "LANGS"

log "INFO" "Node via nvm"
brew install nvm
nvm install --lts
log "INFO" "LTS node installed. Open a new shell, type 'node' and see if it works. Continue when it does."
wait_for_keypress

log "INFO" "Ruby via rbenv"
brew install rbenv
rbenv install $(rbenv install -l | grep -v - | tail -1) # thanks, https://stackoverflow.com/a/30191850/1486374
rbenv global $(rbenv install -l | grep -v - | tail -1)
log "INFO" "Open a new terminal and try 'irb' and 'ruby' commands to see if they work. Continue when it does."
wait_for_keypress
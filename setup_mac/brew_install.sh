#!/bin/bash

source "_utils.sh"

############################################################################################
# BREW INSTALL
############################################################################################

log_header "BREW INSTALL"

log "INFO" "Installing brew apps."
while read LINE; do
  log "DEBUG" "Installing app: ${LINE}."
  brew install "${LINE}"
done < <(parse_section_of_config_ini "BREW")
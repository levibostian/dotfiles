#!/bin/bash

source "_utils.sh"

############################################################################################
# XCODE AND DEVELOPER TOOLS
############################################################################################

log_header "XCODE and DEV TOOLS"

log "INFO" "Installing xCode and developer tools."
xcode-select --install 2> /dev/null
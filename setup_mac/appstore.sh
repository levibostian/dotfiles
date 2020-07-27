#!/bin/bash

source "_utils.sh"

############################################################################################
# APPSTORE APPS
############################################################################################

log_header "APPSTORE APPS"

while read LINE; do
  log "DEBUG" "Please install the app on the page that will be opened in Safari."
  open ${LINE}
  wait_for_keypress
done < <(parse_section_of_config_ini "APPSTORE_APPS")
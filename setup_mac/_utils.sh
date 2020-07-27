#!/bin/bash

# Parse a setup_mac_apps.ini file to be more bash friendly.
# The ini file will be transformed where each line wil look like the following:
#     <SECTION_NAME>=<KEY>=<VALUE>
# This way, we can grep values more easily in bash, avoiding the need of specialized tools (extra dependencies)
parse_config_ini () {
  awk '/\[/{prefix=$0; next} $1{print prefix $0}' setup_mac_apps.ini | sed -e 's/\[//' -e 's/\]/=/'
}

# Get the content of a certain section in the setup_mac_apps.ini file
# Arguments:
#   - $1: Name of the section to be parsed
parse_section_of_config_ini () {
  local SECTION="${1}"
  while read LINE; do
    if [[ ${LINE} = "${SECTION}"* ]]; then
      echo "${LINE}" | sed -e "s/^${SECTION}=//g" -e "s/^#.*//g"
    fi
  done < <(parse_config_ini)
}

# Get the value of a certain KEY in a certain SECTION of the setup_mac_apps.ini file
# Arguments:
#   - SECTION: The section in which the key resides
#   - KEY: The key of which the value needs to be retrieved
get_value_from_section_in_config_file () {
  local SECTION="${1}"
  local KEY="${2}"

  while read LINE; do
    if [[ ${LINE} = "${KEY}="* ]]; then
      echo "${LINE}" | cut -d '=' -f 2
    fi
  done < <(parse_section_of_config_ini "${SECTION}")
}

# Print a colored message
# Arguments:
#   - SEV: The sevirity of the log (DEBUG, INFO, SUCCESS, ERROR)
#   - MSG: The message
log () {
  local SEV="$1"
  local MSG="$2"
  local COLOR=""
  local NC="\033[0m"

  if [[ "${SEV}" == "DEBUG" ]]; then
    COLOR="\033[1;30m"
  fi  
  if [[ "${SEV}" == "INFO" ]]; then
    COLOR="\033[0;36m"
  fi  
  if [[ "${SEV}" == "SUCCESS" ]]; then
    COLOR="\033[0;32m"
  fi  
  if [[ "${SEV}" == "ERROR" ]]; then
    COLOR="\033[0;31m"
  fi  

  echo -e "[$(date "+%Y-%m-%d %H:%M:%S")][${COLOR}${SEV}${NC}] ${COLOR}${MSG}${NC}"

  if [[ ${SEV} == "ERROR" ]]; then
    exit 1
  fi  
}

# Print a colored header
# Arguments:
#   - MSG: The message
log_header () {
  local SEV="SUCCESS"
  local MSG="$1"
  
  log "${SEV}" "--------------------------------------------------------------------------------------------------"
  log "${SEV}" "${MSG}"
  log "${SEV}" "--------------------------------------------------------------------------------------------------"
}

# Wait for user input
wait_for_keypress () {
  read -p "Press [Enter] key to continue..."
}
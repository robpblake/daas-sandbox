#!/usr/bin/env bash

set -e

# import
source ${DAAS_HOME}/launch/logging.sh

# debug
if [ "${SCRIPT_DEBUG}" = "true" ] ; then
    set -x
    log_debug "Script debugging is enabled, allowing bash commands and their arguments to be printed as they are executed"
fi

# config (any configurations script that needs to run on image startup must be added here)
# CONFIGURE_SCRIPTS=(
# )
# source ${DAAS_HOME}/launch/configure.sh
#############################################

log_info "Launching placeholder (while-true-sleep loop)..."

while true ; do
    sleep 1000
done

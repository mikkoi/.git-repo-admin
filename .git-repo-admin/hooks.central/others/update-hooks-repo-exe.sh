#!/usr/bin/env bash

# Activate verbose if desired
VERBOSE=0
CONF_DBG=$(git config --get githooks.debug) && [ "${CONF_DBG}" = "1" ] && VERBOSE=1
BARE_REPO_DIR=$(pwd)
if [ "$VERBOSE" = "1" ]; then echo "post-receive/I am $0: Parameters:$@"; fi
if [ "$VERBOSE" = "1" ]; then echo "I am in dir ${BARE_REPO_DIR}"; fi
if [ "$VERBOSE" = "1" ]; then echo "Now executing git pull origin master"; fi
sleep 5
date
git pull origin master


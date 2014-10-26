#!/usr/bin/env bash

# Activate verbose if desired
VERBOSE=0
CONF_DBG=$(git config --get githooks.debug) && [ "${CONF_DBG}" = "1" ] && VERBOSE=1
BARE_REPO_DIR=$(pwd)
if [ "$VERBOSE" = "1" ]; then echo "post-receive/I am $0: Parameters:$@"; fi
if [ "$VERBOSE" = "1" ]; then echo "I am in dir ${BARE_REPO_DIR}"; fi
cd ../repo.hooks
if [ "$VERBOSE" = "1" ]; then echo "Now in dir $(pwd)"; fi
if [ "$VERBOSE" = "1" ]; then echo "Now executing: nohup ../others/update-hooks-repo-exe.sh ..."; fi
# git pull origin master

#./test.sh < /dev/null > nohup.out 2>&1 &
WAIT_SECS=5
nohup .git-repo-admin/hooks.central/others/update-hooks-repo-exe.sh ${WAIT_SECS} < /dev/null >> ../update-hooks-repo.log 2>&1 &


#!/bin/bash
BARE_REPO_DIR=$(pwd)
echo "post-receive/update_hooks_repo.sh: Now in dir ${BARE_REPO_DIR}"
cd ../repo.hooks
echo "Now executing: git pull origin master"
# git pull origin master


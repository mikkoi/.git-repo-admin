#!/usr/bin/env bash
BARE_REPO_DIR=$(pwd)
echo "post-receive/update_hooks_repo.sh: Now in dir ${BARE_REPO_DIR}"
cd ../repo.hooks
echo "Now executing: git pull origin master"
# git pull origin master

#./test.sh < /dev/null > nohup.out 2>&1 &
nohup "sleep 5; date; git pull origin master" < /dev/null >> ../update-hooks-repo.log 2>&1 &


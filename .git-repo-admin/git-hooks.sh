#!/bin/bash
echo "params:$@"
BARE_REPO_DIR=$(pwd)
HOOK_NAME=${BASH_SOURCE} # Actually "hooks/<hook name>"
echo "HOOK_NAME=${HOOK_NAME}"
#git config --list
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
cd ${DIR}
echo "Now in dir ${DIR}"
carton exec ./git-hooks.pl ${BARE_REPO_DIR} ${HOOK_NAME} $@


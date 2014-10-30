#!/bin/bash

# Activate verbose if desired
VERBOSE=0
CONF_DBG=`git config --get githooks.debug` && [ "${CONF_DBG}" = "1" ] && VERBOSE=1
if [ "$VERBOSE" = "1" ]; then echo "Parameters:$@"; fi
BARE_REPO_DIR=$(pwd)
if [ "$VERBOSE" = "1" ]; then echo "post-receive/inform_user.sh: Now in dir ${BARE_REPO_DIR}"; fi
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
cd ${DIR}
if [ "$VERBOSE" = "1" ]; then echo "post-receive/inform_user.sh: Now in dir ${DIR}"; fi
if [ "$VERBOSE" = "1" ]; then echo "Now executing: carton exec ./inform_user.sh ${BARE_REPO_DIR} $@"; fi
carton exec ../others/inform_user.pl ${BARE_REPO_DIR} $@


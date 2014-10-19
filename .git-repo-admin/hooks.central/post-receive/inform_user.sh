#!/bin/bash
echo "Params:$@"
BARE_REPO_DIR=$(pwd)
echo "post-receive/inform_user.sh: Now in dir ${BARE_REPO_DIR}"
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
cd ${DIR}
echo "post-receive/inform_user.sh: Now in dir ${DIR}"
echo "Now executing: carton exec ./inform_user.sh ${BARE_REPO_DIR} $@"
carton exec ../carton_executables/inform_user.pl ${BARE_REPO_DIR} $@


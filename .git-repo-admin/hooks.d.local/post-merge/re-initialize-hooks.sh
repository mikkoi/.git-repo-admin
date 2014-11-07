#!/usr/bin/env bash

#
# Rerun the initialize-hooks.sh script.
# Parameters:
# --dry-run, don't install, just show what would do.
# --remove, instead of installing the hooks, remove them.
# --central, normally you want to install the local hooks.
#       Use "central" to install the central repo hooks.
#
# Activate verbose by setting the git config item githooks.debug to "1".
#

# Activate verbose if desired
VERBOSE=0
CONF_DBG=`git config --get githooks.debug` && [ "${CONF_DBG}" = "1" ] && VERBOSE=1
if [ "$VERBOSE" = "1" ]; then echo "($0) Params:$@"; fi
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
THIS_SCRIPT=`basename ${SOURCE}`
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
if [ "$VERBOSE" = "1" ]; then echo "DIR=${DIR}"; fi
cd ${DIR}
CMD="../../initialize-hooks.sh $@"
if [ "$VERBOSE" = "1" ]; then echo "CMD=${CMD}"; fi
exec ${CMD}

# *** End of Bash script ***


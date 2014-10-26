#!/usr/bin/env bash

#
# Jumps to the admin directory and executes the perl script underneath
# this Bash script.
# The directory is "controlled" by plenv and Carton, forces perl 
# to be desired version, not system perl.

# Activate verbose if desired
VERBOSE=0
CONF_DBG=`git config --get githooks.edebug` && [ "${CONF_DBG}" = "1" ] && DEBUG=1
if [ "$VERBOSE" = "1" ]; then echo "Parameters:$@"; fi
BARE_REPO_DIR=$(pwd)
HOOK_NAME=${BASH_SOURCE} # Actually "hooks/<hook name>"
if [ "$VERBOSE" = "1" ]; then echo "HOOK_NAME=${HOOK_NAME}"; fi
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
THIS_SCRIPT="${SOURCE}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
cd ${DIR}
exec carton exec perl -x ${THIS_SCRIPT} ${BARE_REPO_DIR} ${HOOK_NAME} $@
# *** End of Bash script ***



# *** Start of Perl script
#!/usr/bin/env perl
use strict; use warnings;
my $verbose = 0;
$verbose = $ENV{'VERBOSE'} if defined $ENV{'VERBOSE'};
my $central_repo_dir = shift @ARGV;
my $hook_name = shift @ARGV;
chdir $central_repo_dir;
print "git-hooks.sh(pl) now in dir '$central_repo_dir'.\n" if ($verbose);
use Git::Hooks;
print "Executing: run_hook($hook_name, @ARGV)\n" if ($verbose);
run_hook($hook_name, @ARGV);


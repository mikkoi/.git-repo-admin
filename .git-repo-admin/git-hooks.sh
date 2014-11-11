#!/usr/bin/env bash

#
# Jumps to the admin directory and executes the perl script underneath
# this Bash script.
# The directory is "controlled" by plenv and Carton, forces perl 
# to be desired version, not system perl.

# Activate verbose if desired
VERBOSE=${VERBOSE}
CONF_DBG=`git config --get githooks.debug` && [ "${CONF_DBG}" = "1" ] && VERBOSE=1
if [ "$VERBOSE" = "1" ]; then echo "PATH:${PATH}"; fi
if [ "$VERBOSE" = "1" ]; then echo "Parameters:$@"; fi
REPO_DIR=$(pwd)
if [ "$VERBOSE" = "1" ]; then echo "REPO_DIR=${REPO_DIR}"; fi
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
if [ "$VERBOSE" = "1" ]; then echo "DIR=${DIR}"; fi
cd ${DIR}
export VERBOSE
export DEBUG=1
if [ -e "git-hooks-hook.sh" ]; then source ./git-hooks-hook.sh; fi
CMD="exec carton exec perl -x ${THIS_SCRIPT} ${REPO_DIR} ${HOOK_NAME} $@"
if [ "$VERBOSE" = "1" ]; then echo "CMD=${CMD}"; fi
${CMD}
# *** End of Bash script ***

# *** Start of Perl script
#!/usr/bin/env perl
use strict; use warnings;
my $verbose = 0;
$verbose = $ENV{'VERBOSE'} if defined $ENV{'VERBOSE'};
my $repo_dir = shift @ARGV;
my $hook_name = shift @ARGV;
chdir $repo_dir;
print "git-hooks.sh(pl) now in dir '$repo_dir'.\n" if ($verbose);
my $subgit_change = $hook_name =~ s/\/(user-)([^\/]+)/\/$2/msx;
if($subgit_change) { print "This is SubGit repo, removed 'user-' from hooks name.\n" if $verbose; }
use Git::Hooks;
print "Executing: run_hook($hook_name, @ARGV)\n" if ($verbose);
run_hook($hook_name, @ARGV);


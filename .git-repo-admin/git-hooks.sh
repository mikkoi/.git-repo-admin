#!/usr/bin/env bash

#
# Jumps to the admin directory and executes the perl script underneath this
# Bash script. The directory is "controlled" by plenv and Carton, forces perl
# to be desired version, not system perl.

# Activate verbose if desired
VERBOSE=${VERBOSE}
CONF_DBG=`git config --get githooks.debug` && [ "${CONF_DBG}" = "1" ] && VERBOSE=1
if [ "$VERBOSE" = "1" ]; then echo "PATH:${PATH}"; fi
if [ "$VERBOSE" = "1" ]; then echo "Command line: '$0 $@'"; fi
REPO_DIR=$(pwd)
if [ "$VERBOSE" = "1" ]; then echo "Repository dir: '${REPO_DIR}'"; fi
HOOK_NAME=${BASH_SOURCE} # Actually "hooks/<hook name>"
if [ "$VERBOSE" = "1" ]; then echo "Executing hook file '${HOOK_NAME}'."; fi
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
THIS_SCRIPT="${SOURCE}"
THIS_SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
if [ "$VERBOSE" = "1" ]; then echo "This script located in '${THIS_SCRIPT_DIR}'. Changing there."; fi
cd ${THIS_SCRIPT_DIR}
if [ -e "git-hooks-aux.sh" ]; then source ./git-hooks-aux.sh; fi
export VERBOSE
export REPO_ADMIN_DIR=$THIS_SCRIPT_DIR
CMD="exec carton exec perl -x ${THIS_SCRIPT} ${REPO_DIR} ${HOOK_NAME} $@"
if [ "$VERBOSE" = "1" ]; then echo "Executing: ${CMD}"; fi
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
print "git-hooks.sh(pl) running in dir '$repo_dir'.\n" if ($verbose);
my $subgit_change = $hook_name =~ s/\/(user-)([^\/]+)/\/$2/msx;
if($subgit_change) { print "This is SubGit repo, removed 'user-' from hooks name.\n" if $verbose; }
use Git::Hooks;
print "Executing: run_hook($hook_name, @ARGV)\n" if ($verbose);
run_hook($hook_name, @ARGV);


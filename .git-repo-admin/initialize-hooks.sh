#!/usr/bin/env bash

#
# Jumps to the admin directory and executes the perl script underneath
# this Bash script.
# Install hooks.
# Parameters:
# --dry-run, don't install, just show what would do.
# --remove, instead of installing the hooks, remove them.
# --central, normally you want to install the local hooks.
#       Use "central" to install the central repo hooks.
#
# Activate verbose by setting the git config item githooks.debug to "1".
#

# Activate verbose if desired
VERBOSE=${VERBOSE}
CONF_DBG=`git config --get githooks.debug` && [ "${CONF_DBG}" = "1" ] && VERBOSE=1
if [ "$VERBOSE" = "1" ]; then echo "PATH:${PATH}"; fi
if [ "$VERBOSE" = "1" ]; then echo "Command line: '$0 $@'"; fi
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
THIS_SCRIPT=`basename ${SOURCE}`
THIS_SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
if [ "$VERBOSE" = "1" ]; then echo "This script located in '${THIS_SCRIPT_DIR}'. Changing there."; fi
cd ${THIS_SCRIPT_DIR}
CMD="perl -x ${THIS_SCRIPT} $@"
if [ "$VERBOSE" = "1" ]; then CMD="${CMD} --verbose"; fi
if [ "$VERBOSE" = "1" ]; then echo "Executing: ${CMD}"; fi

if [ "$VERBOSE" = "1" ]; then echo "Set environment PLENV_VERSION=system"; fi
export PLENV_VERSION="system" # This script executed without plenv and Carton
# (in case Carton or the required perl version not yet installed).
exec ${CMD}

# *** End of Bash script ***


# *** Start of Perl script
#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
my $verbose = 0;
my $action = 'INSTALL';
my $dry_run = 0;
my $install_central = 0;
# Cannot pass --verbose because Carton will snatch it before us!
#$verbose = $ENV{'VERBOSE'} if defined $ENV{'VERBOSE'};
grep { if($_ =~ /^(--){0,1}verbose$/i) { $verbose = 1; } } @ARGV;
grep { if($_ =~ /^(--){0,1}remove$/i) { $action = 'REMOVE'; } } @ARGV;
grep { if($_ =~ /^(--){0,1}dry-run$/i) { $dry_run = 1; } } @ARGV;
grep { if($_ =~ /^(--){0,1}central$/i) { $install_central = 1; } } @ARGV;
print "Verbose activated!\n" if $verbose;
print "Delete the plenv fooling variable.\n" if $verbose;
delete $ENV{'PLENV_VERSION'};
print Dumper(\%ENV) if $verbose;
use InitializeHooks qw();
my $hooks_cfg_filename;
my $userhooks_dirname;
my $repo_cfg_dir;
my @GIT_HOOKS;
if($install_central) {
   @GIT_HOOKS = qw(
      pre-receive
      post-receive
      update
   );
   $hooks_cfg_filename = 'config_hooks.central';
   $userhooks_dirname = 'hooks.d.central';
   $repo_cfg_dir = File::Spec->catfile( InitializeHooks::get_bare_repo_dir() );
}
else {
   @GIT_HOOKS = qw(
      pre-receive
      pre-rebase
      pre-commit
      pre-auto-gc
      pre-applypatch
      post-update
      post-rewrite
      post-receive
      post-merge
      post-commit
      post-checkout
      post-applypatch
      commit-msg
      applypatch-msg
      update
      prepare-commit-msg
   );
   $hooks_cfg_filename = 'config_hooks.local';
   $userhooks_dirname = 'hooks.d.local';
   $repo_cfg_dir = File::Spec->catfile( File::Spec->updir(), '.git' );
}
InitializeHooks::execute('verbose' => $verbose,
   'dry_run' => $dry_run,
   'hooks' => \@GIT_HOOKS,
   'hooks_cfg_filename' => $hooks_cfg_filename,
   'userhooks_dirname' => $userhooks_dirname,
   'repo_cfg_dir' => $repo_cfg_dir,
   'action' => $action,
   'local_hooks' => !$install_central,
   );
exit 0;


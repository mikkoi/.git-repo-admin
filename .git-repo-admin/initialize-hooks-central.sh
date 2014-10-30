#!/usr/bin/env bash

#
# Jumps to the admin directory and executes the perl script underneath
# this Bash script.

# Activate verbose if desired
VERBOSE=1
CONF_DBG=`git config --get githooks.debug` && [ "${CONF_DBG}" = "1" ] && VERBOSE=1
if [ "$VERBOSE" = "1" ]; then echo "Parameters:$@"; fi
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
CARTON_CMD="carton exec perl -x ${THIS_SCRIPT} $@"
if [ "$VERBOSE" = "1" ]; then echo "CARTON_CMD=${CARTON_CMD}"; fi
exec ${CARTON_CMD}

# *** End of Bash script ***


# *** Start of Perl script
#!/usr/bin/env perl
use strict;
use warnings;
my $verbose = 0;
$verbose = $ENV{'VERBOSE'} if defined $ENV{'VERBOSE'};
print "Verbose activated!\n" if $verbose;
use InitializeHooks;
use constant GIT_HOOKS => [qw(
   pre-receive
   post-receive
   update
)];
#my $repo_cfg_dir = File::Spec->catfile( File::Spec->updir(), '.git', 'config' );
my $repo_cfg_dir = File::Spec->catfile( InitializeHooks::get_bare_repo_dir() );
InitializeHooks::execute('verbose' => $verbose,
   'dry-run' => 1,
   'hooks' => GIT_HOOKS(),
   'hooks_cfg_filename' => 'hooks_config.central',
   'bare_repo_path' => InitializeHooks::get_bare_repo_dir(),
   'repo_cfg_dir' => $repo_cfg_dir,
   );
exit 0;


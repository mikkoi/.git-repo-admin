package InitializeHooks;

my $esing = 0;
use strict;
use warnings 'all';

my $verbose = 0;
$verbose = $ENV{'VERBOSE'} if defined $ENV{'VERBOSE'};
# This file creates the necessary links to get the hooks working.
# It is safe to run this multiple times.
# The actual script is perl and embedded in this file.
# 
# Modify the config to include an additional file:
# 1) add rows to config ([include] path).
# 2) create a link to the correct config file (in this dir).
# 3) create hook links 
#

use English qw( -no_match_vars );
use File::Spec qw();
use Tie::File;
use File::Copy qw();
use File::Path qw();
use Data::Dumper qw(Dumper);
use Module::Load::Conditional qw[can_load];

# Constants

# Some globals:
my $timestamp = (localtime)[5]+1900 . '-'
      . qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec )[(localtime time)[4]]
      . '-' . sprintf "%02d", (localtime time)[3];

# The Perl version to use with plenv in local directory (for Git::Hooks).
my $perl_version_filename = File::Spec->rel2abs(File::Spec->catfile(
      File::Spec->curdir, '.perl-version' ));
my $perl_version_fh;
if(! open $perl_version_fh, "<", $perl_version_filename) {
   die "Cannot open file '$perl_version_filename' for reading."
}
my $perl_version_file_contents = <$perl_version_fh>;
close $perl_version_fh;
chomp $perl_version_file_contents;
my ($perl_version) = $perl_version_file_contents =~ /(.*)(-git-hooks)/;
my $perl_name = $perl_version_file_contents;
my $RED = "\033[0;31m";
my $NO_COLOUR="\033[0m";


# params: [NONE]
# Check that we have plenv in the system. Otherwise complain!
sub check_plenv {
   if(system('command -v plenv >/dev/null') ) {
      print "*" x 50, "\n";
      print "*" x 50, "\n";
      print "$RED *** You do not have 'plenv' in your system! ***$NO_COLOUR\n";
      print " *** You must first install plenv. The easiest way to do that\n";
      print " *** is to install anyenv package:\n";
      print " *** 'git clone https://github.com/riywo/anyenv ~/.anyenv'\n";
      print " *** Follow the instructions in anyenv! Finish with:\n";
      print " *** 'anyenv install plenv'\n";
      print "*" x 50, "\n";
      print "*" x 50, "\n";
      return 0;
   }
   else {
      return 1;
   }
}

# If we have plenv in the system, continue with it to install Carton,
# perl compiler and the modules.
sub install_prerequisites {
   my %params = @_;
   my $verbose = defined $params{'verbose'} ? $params{'verbose'} : 0;
   my $dry_run = defined $params{'dry_run'} ? $params{'dry_run'} : 0;
   my $repo_cfg_dir = defined $params{'repo_cfg_dir'} ? $params{'repo_cfg_dir'} : 0;
   my $perl_version = defined $params{'perl_version'} ? $params{'perl_version'} : 0;
   my $perl_name = defined $params{'perl_name'} ? $params{'perl_name'} : 0;
   my $action = defined $params{'action'} ? $params{'action'} : 0;
   die "Unknown action '$action'!" if ($action !~ /^(INSTALL|REMOVE)$/);

   print "Checking (and installing missing) prerequisites...\n" if $verbose;
   print "Installing Perl v.$perl_version into 'plenv' as '$perl_name'.\n" if $verbose;
   my $plenv_install_cmd = "cd ..; plenv install $perl_version --as=$perl_name";
   print "plenv_install_cmd=$plenv_install_cmd.\n" if $verbose;
   # cd to root. Otherwise file .perl-version prevents from installing.
   system($plenv_install_cmd);
   system("plenv rehash");
   system("plenv install-cpanm");
   system("plenv rehash");
   print "Installing 'Carton'.\n";
   system("cpanm Carton");
   print "Installing Perl dependencies using 'Carton'.\n" if $verbose;
   my $link_filepath = File::Spec->rel2abs(File::Spec->catdir(File::Spec->curdir(), 'local')); # This link already exists!
   my $link_to_filepath = File::Spec->rel2abs(File::Spec->catdir($repo_cfg_dir, 'git-hooks-carton-local'));
   if( -e $link_filepath && ! -l $link_filepath ) {
      die "The file '$link_filepath' already exists and it is not a link. Aborting...";
   }
   elsif( -e $link_to_filepath && ! -d $link_to_filepath ) {
      die "The file '$link_to_filepath' already exists and it is not a directory. Aborting...";
   }
   else {
      my @unlink_params = ($link_filepath);
      my @symlink_params = ($link_to_filepath, $link_filepath);
      if($action eq 'INSTALL') {
         print "Execute: make_path($link_to_filepath)" if $verbose;
         File::Path::make_path($link_to_filepath, { 'verbose' => 1, }) unless $dry_run;
      }
      else {
         print "Not removing Carton installed CPAN files (in dir '.git/carton_local').\n";
      }
   }
   if($action eq 'INSTALL') {
      system("carton install --deployment");
   }
   return 1;
}

# Try to find the bare repo.
# This is of use only to central repo.
sub get_bare_repo_dir {
   my %params = @_;
   my $verbose = defined $params{'verbose'} ? $params{'verbose'} : 0;
   my $dry_run = defined $params{'dry_run'} ? $params{'dry_run'} : 0;
   my $bare_repo_dir;
   my $cmd = "git config --get remote.origin.url";
   print "Executing: '$cmd'.\n" if $verbose;
   eval {
      $bare_repo_dir = `$cmd`;
   };
   die "Where is this script being run? I cannot get git config item 'remote.origin.url'!" if $EVAL_ERROR;
   chomp $bare_repo_dir;
   print "bare repo dir: '$bare_repo_dir'.\n" if $verbose;
   my $bare_repo_HEAD_filename = File::Spec->rel2abs(File::Spec->catfile(
      $bare_repo_dir, 'HEAD'));
   print "bare repo HEAD filename: '$bare_repo_HEAD_filename'.\n" if $verbose;
   my $bare_repo_git_dirname = File::Spec->rel2abs(File::Spec->catfile(
      $bare_repo_dir, '.git'));
   print "bare repo git dirname: '$bare_repo_git_dirname'.\n" if $verbose;
   if(-e $bare_repo_HEAD_filename && ! -e $bare_repo_git_dirname) {
      return $bare_repo_dir;
   }
   else {
      die "'$bare_repo_dir' is not a bare repository!";
   }
}

# params: [NONE]
# Backup old and add to config only if the config didn't have it before.
# The config must contain the rows:
# [include]
# 	path = config_hooks
sub fix_git_config {
   my %params = @_;
   print Dumper(\%params) if ($verbose);
   my $verbose = defined $params{'verbose'} ? $params{'verbose'} : 0;
   my $dry_run = defined $params{'dry_run'} ? $params{'dry_run'} : 0;
   my $repo_cfg_dir = defined $params{'repo_cfg_dir'} ? $params{'repo_cfg_dir'} : 0;
   my $hooks_cfg_linkname = defined $params{'hooks_cfg_linkname'} ? $params{'hooks_cfg_linkname'} : 0;
   my $action = defined $params{'action'} ? $params{'action'} : 0;
   die "Unknown action '$action'!" if ($action !~ /^(INSTALL|REMOVE)$/);

   my @config_rows;
   my $config_filename = File::Spec->rel2abs(File::Spec->catfile(
      $repo_cfg_dir, 'config' ));
   my $config_bak_filename = File::Spec->rel2abs(File::Spec->catfile(
      $repo_cfg_dir, 'config.bak_' . $timestamp));
   tie @config_rows, 'Tie::File', $config_filename || die;
   my $already_set = 0;
   foreach my $config_row (@config_rows) {
      print "Existing config:$config_row.\n" if $verbose;
      $already_set = 1 if($config_row =~ /path[\s]*=[\s]*$hooks_cfg_linkname/);
   }
   if($action eq 'INSTALL') {
      print "Making a backup of the existing config and adding rows\n" if $verbose;
      print "(to include the config file '$hooks_cfg_linkname').\n" if $verbose;
      if(! $already_set) {
         File::Copy::copy($config_filename, $config_bak_filename) unless $dry_run;
         push @config_rows, "[include]\n" unless $dry_run;
         push @config_rows, "\tpath = $hooks_cfg_linkname\n" unless $dry_run;
         print "Added rows to config 'config_filename':\n" if $verbose;
         print "[include]\n\tpath = $hooks_cfg_linkname\n" if $verbose;
      }
      else {
         print "Already set, no changes.\n" if $verbose;
      }
   }
   else {
      print "Removing rows from file 'config'.\n";
      print "Making a backup of the existing config and adding rows \n(to include the config file '$hooks_cfg_linkname').\n" if $verbose;
      File::Copy::copy($config_filename, $config_bak_filename) unless $dry_run;
      for(my $i = 0; $i < @config_rows; $i++) {
         my $config_row = $config_rows[$i];
         print ":'$config_row'\n" if $verbose;
         if($config_row =~ /path[\s]*=[\s]*$hooks_cfg_linkname/) {
            print "Remove the following rows:\n:$config_rows[$i-1]\n:$config_rows[$i]\n" if $verbose;
            my @removed;
            @removed = splice @config_rows, $i-1, 2 unless $dry_run;
            print "Removed the following rows:\n", (join "\n", @removed), "\n" unless $dry_run;
            $already_set = 0;
            last;
         }
      }
   }
   return $already_set;
}

# Params: [NONE]
# Symlink always, even if link/file already exists.
# The file mentioned in config (path = file), where "file" is a local file.
# Instead of the file, we create a link which points to the real config_hooks(central|local) file.
sub link_file_to_other_config {
   my %params = @_;
   my $verbose = defined $params{'verbose'} ? $params{'verbose'} : 0;
   my $dry_run = defined $params{'dry_run'} ? $params{'dry_run'} : 0;
   my $repo_cfg_dir = defined $params{'repo_cfg_dir'} ? $params{'repo_cfg_dir'} : 0;
   my $hooks_cfg_linkname = defined $params{'hooks_cfg_linkname'} ? $params{'hooks_cfg_linkname'} : '';
   my $hooks_cfg_filename = defined $params{'hooks_cfg_filename'} ? $params{'hooks_cfg_filename'} : 0;
   my $action = defined $params{'action'} ? $params{'action'} : 0;

   my $link_filepath = File::Spec->rel2abs(File::Spec->catdir($repo_cfg_dir, $hooks_cfg_linkname));
   my $link_to_filepath = File::Spec->rel2abs(File::Spec->catdir(File::Spec->curdir(), $hooks_cfg_filename));
   if( -e $link_filepath && ! -l $link_filepath ) {
      die "The file '$link_filepath' already exists and it is not a link. Aborting...";
   }
   else {
      my @unlink_params = ($link_filepath);
      my @symlink_params = ($link_to_filepath, $link_filepath);
         print "Execute: unlink ", (join ",", @unlink_params), "\n" if($verbose);
         unlink $link_filepath if (! $dry_run);
      if($action eq 'INSTALL') {
         print "Execute:", " symlink ", (join ",", @symlink_params), "\n" if($verbose);
         symlink $link_to_filepath, $link_filepath if ( ! $dry_run);
         print "Created symlink from '$link_to_filepath' to '$link_filepath'.\n" if $verbose;
      }
   }
   return 1;
}

#
sub setup_git_hooks {
   my %params = @_;
   my $verbose = defined $params{'verbose'} ? $params{'verbose'} : 0;
   my $dry_run = defined $params{'dry_run'} ? $params{'dry_run'} : 0;
   my $hooks = defined $params{'hooks'} ? $params{'hooks'} : [ ];
   my $repo_cfg_dir = defined $params{'repo_cfg_dir'} ? $params{'repo_cfg_dir'} : 0;
   my $action = defined $params{'action'} ? $params{'action'} : 0;
   my $userhooks_dirname = defined $params{'userhooks_dirname'} ? $params{'userhooks_dirname'} : 0;

   my $link_to_filename = 'git-hooks.sh';
   my $link_dirpath = File::Spec->rel2abs(File::Spec->catfile( $repo_cfg_dir, 'hooks'));
   my $link_to_filepath = File::Spec->rel2abs(File::Spec->catfile(
         File::Spec->curdir(), $link_to_filename));
   foreach my $hook_filename ( @{$hooks} ) {
      my $link_filepath = File::Spec->rel2abs(File::Spec->catfile(
            $repo_cfg_dir, 'hooks', $hook_filename));
      print "symlink from '$link_filepath'...\n" if $verbose;
      # Make sure we behave correctly also in a SubGit controlled repo!
      my $subgit_sample_hook = $link_filepath;
      $subgit_sample_hook =~ s/$hook_filename$/user-$hook_filename.sample/g;
      print "Checking for file '$subgit_sample_hook'...\n" if $verbose;
      if( -e $subgit_sample_hook ) {
         $link_filepath =~ s/$hook_filename$/user-$hook_filename/g;
         print "copy $link_filepath, $link_filepath.bak_$timestamp\n" if $verbose;
         File::Copy::copy($link_filepath, "$link_filepath.bak_" . $timestamp) unless $dry_run;
         print "unlink $link_filepath\n" if $verbose;
         unlink $link_filepath unless $dry_run;
      }
      print "Creating symlink from '$link_filepath' "
            . "to connect to Git::Hooks ($link_to_filepath).\n" if $verbose;
      if( -e $link_filepath && ! -l $link_filepath ) {
         die "The file '$link_filepath' already exists and it not a link. Aborting...";
      }
      else {
         my @unlink_params = ($link_filepath);
         my @symlink_params = ($link_to_filepath, $link_filepath);
         print "Execute: unlink ", (join ",", @unlink_params), "\n" if($verbose);
         unlink $link_filepath unless $dry_run;
         if($action eq 'INSTALL') {
            print "Execute: symlink ", (join ",", @symlink_params), "\n" if($verbose);
            symlink $link_to_filepath, $link_filepath unless $dry_run;
            print "Created symlink from '$link_to_filepath' to '$link_filepath'.\n" if($verbose);
         }
      }
   }
   print "Created/renewed symlinks for main Git hooks (total " . scalar @{$hooks} . ").\n";
   $link_to_filepath = File::Spec->rel2abs(File::Spec->catfile(File::Spec->curdir(), $userhooks_dirname));
   my $link_filepath = File::Spec->rel2abs(File::Spec->catfile($repo_cfg_dir, 'hooks.d'));

   print "Link to directory 'hooks.d'... " if $verbose;
   print "(used by Git::Hooks for user hooks).\n" if $verbose;
   if( -e $link_filepath && ! -l $link_filepath ) {
      die "The file '$link_filepath' already exists and it not a link. Aborting...";
   }
   else {
      my @unlink_params = ($link_filepath);
      my @symlink_params = ($link_to_filepath, $link_filepath);
      print "Execute: unlink ", (join ",", @unlink_params), "\n" if $verbose;
      unlink $link_filepath if (! $dry_run);
      if($action eq 'INSTALL') {
         print "Execute: symlink ", (join ",", @symlink_params), "\n" if $verbose;
         symlink $link_to_filepath, $link_filepath if ( ! $dry_run);
         print "Created symlink from '$link_to_filepath' to '$link_filepath'.\n" if $verbose;
      }
   }
   return 1;
}

# Place here required bits for local hooks,
# Except CPAN Perl modules. Place those in cpanfile.
sub handle_local_hooks_prerequisites {
   my %params = @_;
   my $verbose = defined $params{'verbose'} ? $params{'verbose'} : 0;
   my $dry_run = defined $params{'dry_run'} ? $params{'dry_run'} : 0;
   my $action = defined $params{'action'} ? $params{'action'} : 0;

   my $loaded = can_load('modules' => { 'InitializeHooksLocal' => undef });
   if($loaded) {
      print "Loading local InitializeHooksLocal module.\n" if $verbose;
      InitializeHooksLocal::execute('verbose' => $verbose,
            'dry_run' => $dry_run,
            'action' => $action,
         );
   }
   else { print "No InitializeHooksLocal module. Do not load.\n" if $verbose; }

   return 1;
}

# Place here required bits for central repo hooks,
# Except CPAN Perl modules. Place those in cpanfile.
sub handle_central_hooks_prerequisites {
   my %params = @_;
   my $verbose = defined $params{'verbose'} ? $params{'verbose'} : 0;
   my $dry_run = defined $params{'dry_run'} ? $params{'dry_run'} : 0;
   my $action = defined $params{'action'} ? $params{'action'} : 0;

   my $loaded = can_load('modules' => { 'InitializeHooksCentral' => undef });
   if($loaded) {
      print "Loading local InitializeHooksCentral module.\n" if $verbose;
      InitializeHooksCentral::execute('verbose' => $verbose,
            'dry_run' => $dry_run,
            'action' => $action,
         );
   }
   else { print "No InitializeHooksCentral module. Do not load.\n" if $verbose; }

   return 1;
}

sub centrify_text {
   my ($text, $field_width) = @_;
   my $text_width = length $text;
   my $space = sprintf ' ' x int (($field_width - $text_width) / 2);
   my $result = $space . $text . $space;
   return length $result == $field_width ? $result : $result . " ";
}

sub execute {
   my %params = @_;
   my $verbose = defined $params{'verbose'} ? $params{'verbose'} : 0;
   my $dry_run = defined $params{'dry_run'} ? $params{'dry_run'} : 0;
   my $repo_cfg_dir = defined $params{'repo_cfg_dir'} ? $params{'repo_cfg_dir'} : 0;
   die "Missing option 'repo_cfg_dir'!" unless $repo_cfg_dir;
   my $hooks = defined $params{'hooks'} ? $params{'hooks'} : [ ];
   my $hooks_cfg_filename = defined $params{'hooks_cfg_filename'}
         ? $params{'hooks_cfg_filename'} : '';
   my $userhooks_dirname = defined $params{'userhooks_dirname'} ? $params{'userhooks_dirname'} : [ ];
   my $action = defined $params{'action'} ? $params{'action'} : 0;
   die "Unknown action '$action'!" if ($action !~ /^(INSTALL|REMOVE)$/);
   my $local_hooks = defined $params{'local_hooks'} ? $params{'local_hooks'} : 0;
   print Dumper(\%params) if ($verbose);
   print "Dry-run activated!\n" if ($dry_run);
   
   my $title = "Setup this Git repository with Git::Hooks";
   print "*" x 79, "\n";
   print "*** " . centrify_text($title, 71) . " ***\n";
   print "*" x 79, "\n" if $verbose;

   if(! check_plenv() ) { exit 1; }
   install_prerequisites('verbose' => $verbose, 'dry_run' => $dry_run,
         'repo_cfg_dir' => $repo_cfg_dir,
         'perl_version' => $perl_version, 'perl_name' => $perl_name,
         'action' => $action, );
   my $hooks_cfg_linkname = 'config_hooks';
   my $already_set = fix_git_config('verbose' => $verbose, 'dry_run' => $dry_run,
         'repo_cfg_dir' => $repo_cfg_dir, 'hooks_cfg_linkname' => $hooks_cfg_linkname,
         'action' => $action, );
   if($already_set) {
      print "Git config is already modified. Let's check the links.\n" if $verbose;
   }
   link_file_to_other_config('verbose' => $verbose, 'dry_run' => $dry_run, 'action' => $action,
         'repo_cfg_dir' => $repo_cfg_dir,
         'hooks_cfg_linkname' => $hooks_cfg_linkname, # config_hooks, normally
         'hooks_cfg_filename' => $hooks_cfg_filename, # config_hooks.(central|local)
         );
   setup_git_hooks('verbose' => $verbose, 'dry_run' => $dry_run, 'action' => $action,
         'repo_cfg_dir' => $repo_cfg_dir,
          'hooks' => $hooks, 
          'userhooks_dirname' => $userhooks_dirname,
         );
   if($local_hooks) {
      handle_local_hooks_prerequisites('verbose' => $verbose, 'dry_run' => $dry_run,
            'action' => $action,
            );
   }
   else {
      handle_central_hooks_prerequisites('verbose' => $verbose, 'dry_run' => $dry_run,
            'action' => $action,
            );
   }

   my $end_title = "End of Setup";
   print "*" x 79, "\n" if $verbose;
   print "*** " . centrify_text($end_title, 71) . " ***\n";
   print "*" x 79, "\n";

   return 0;
}

1;

__END__

# End of Perl script


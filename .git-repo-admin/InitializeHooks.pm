package InitializeHooks;

###!/usr/bin/env perl
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

use strict;
use warnings 'all';
use English qw( -no_match_vars );
use File::Spec qw();
use Tie::File;
use File::Copy qw();
use Sys::Hostname qw();
use Data::Dumper qw(Dumper);

# Constants
###use constant GIT_HOOKS => qw(
   ###pre-receive
   ###pre-rebase
   ###pre-commit
   ###pre-auto-gc
   ###pre-applypatch
   ###post-update
   ###post-rewrite
   ###post-receive
   ###post-merge
   ###post-commit
   ###post-checkout
   ###post-applypatch
   ###commit-msg
   ###applypatch-msg
   ###update
   ###prepare-commit-msg
###);

# Some globals:
#my $verbose = $ENV{'GIT_HOOKS_DEBUG'};
#my $repo_admin_dirname = File::Spec->rel2abs(File::Spec->catfile(
      #File::Spec->curdir() ));
#my $repo_base_dirname = File::Spec->rel2abs(File::Spec->catfile(
      #$repo_admin_dirname, File::Spec->updir() ));
#my $git_hooks_filename = File::Spec->rel2abs(File::Spec->catfile(
      #$repo_admin_dirname, 'git-hooks.sh'));
#my $central_repo_config_filename = File::Spec->rel2abs(File::Spec->catfile(
      #$repo_admin_dirname, 'hooks_config.central'));
#my $local_repo_config_filename = File::Spec->rel2abs(File::Spec->catfile(
      #$repo_admin_dirname, 'hooks_config.local'));
#my $config_filename = File::Spec->catfile(
      #File::Spec->updir(), '.git', 'config');
#my $link_to_other_config_dirname = File::Spec->rel2abs(File::Spec->catfile(
      #File::Spec->updir(), '.git'));
#my $other_config_linkname = 'hooks_config';
my $timestamp = (localtime)[5]+1900 . '-'
      . qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec )[(localtime time)[4]]
      . '-' . (localtime time)[3];

# The Perl version to use with plenv in local directory (for Git::Hooks).
my $perl_version = '5.16.2';
my $perl_name = 'git-hooks-' . $perl_version;
my $RED = "\033[0;31m";
my $NO_COLOUR="\033[0m";


# params: [NONE]
# Check that we have plenv in the system. Otherwise complain!
sub check_plenv {
   if(system('command -v plenv >/dev/null') ) {
      print "*" x 50, "\n";
      print "*" x 50, "\n";
      print " *** You do not have 'plenv' in your system! ***\n";
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
   my $perl_version = defined $params{'perl_version'} ? $params{'perl_version'} : 0;
   my $perl_name = defined $params{'perl_name'} ? $params{'perl_name'} : 0;
   print "Checking (and installing missing) prerequisites...\n";
   print "Installing Perl v. $perl_version into 'plenv' as '$perl_name'.\n";
   system("plenv install $perl_version --as=$perl_name");
   system("plenv rehash");
   system("plenv install-cpanm");
   system("plenv rehash");
   print "Installing 'Carton'.\n";
   system("cpanm Carton");
   print "Installing Perl dependencies using 'Carton'.\n";
   system("carton install --deployment");
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
   my $verbose = defined $params{'verbose'} ? $params{'verbose'} : 0;
   my $dry_run = defined $params{'dry_run'} ? $params{'dry_run'} : 0;
   my $repo_cfg_dir = defined $params{'repo_cfg_dir'} ? $params{'repo_cfg_dir'} : 0;
   my $hooks_cfg_linkname = defined $params{'hooks_cfg_linkname'} ? $params{'hooks_cfg_linkname'} : 0;
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
   if( ! $already_set ) {
      print "Making a backup of the existing config and adding rows \n(to include the config file '$hooks_cfg_linkname').\n" if $verbose;
      File::Copy::copy($config_filename, $config_bak_filename) unless $dry_run;
      push @config_rows, "[include]\n" unless $dry_run;
      push @config_rows, "\tpath = $hooks_cfg_linkname\n" unless $dry_run;
   }
   return $already_set;
}

sub is_central_repo {
   my $hostname = Sys::Hostname->hostname();
   my $curdir = File::Spec->curdir();
   return ($hostname =~ /^subgit\.vpn\.$/gsx && $curdir =~ /^\/srv\/git\/.*$/gsx);
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
   #my $bare_repo_path = defined $params{'bare_repo_path'} ? $params{'bare_repo_path'} : 0;

   my $link_filepath = File::Spec->catdir($repo_cfg_dir, $hooks_cfg_linkname);
   my $link_to_filepath = File::Spec->catdir(File::Spec->curdir(), $hooks_cfg_filename);
   if( -e $link_filepath && ! -l $link_filepath ) {
      die "The file '$link_filepath' already exists and it not a link. Aborting...";
   }
   else {
      my @unlink_params = ($link_filepath);
      my @symlink_params = ($link_to_filepath, $link_filepath);
      print "Execute: unlink ", (join ",", @unlink_params), " symlink ", (join ",", @symlink_params), "\n" if($verbose);
      unlink $link_filepath if (! $dry_run);
      symlink $link_to_filepath, $link_filepath if ( ! $dry_run);
   }
   return 1;
}

#
sub setup_git_hooks {
   my %params = @_;
   my $verbose = defined $params{'verbose'} ? $params{'verbose'} : 0;
   my $dry_run = defined $params{'dry_run'} ? $params{'dry_run'} : 0;
   my $hooks = defined $params{'hooks'} ? $params{'hooks'} : [ ];
   #my $bare_repo_path = defined $params{'bare_repo_path'} ? $params{'bare_repo_path'} : 0;
   my $repo_cfg_dir = defined $params{'repo_cfg_dir'} ? $params{'repo_cfg_dir'} : 0;
   my $link_to_filename = 'git-hooks.sh';
   my $link_dirpath = File::Spec->rel2abs(File::Spec->catfile( $repo_cfg_dir, 'hooks'));
   my $link_to_filepath = File::Spec->rel2abs(File::Spec->catfile(
         File::Spec->curdir(), $link_to_filename));
   foreach my $hook_filename ( @{$hooks} ) {
      my $link_filepath = File::Spec->rel2abs(File::Spec->catfile(
            $repo_cfg_dir, $hook_filename));
      print "Creating symlink from '$link_filepath' "
            . "to connect to Git::Hooks ($link_to_filepath).\n" if $verbose;
      if( -e $link_filepath && ! -l $link_filepath ) {
         die "The file '$link_filepath' already exists and it not a link. Aborting...";
      }
      else {
         my @unlink_params = ($link_filepath);
         my @symlink_params = ($link_to_filepath, $link_filepath);
         print "Execute: unlink ", (join ",", @unlink_params), " symlink ", (join ",", @symlink_params), "\n" if($verbose);
         unlink $link_filepath unless $dry_run;
         symlink $link_to_filepath, $link_filepath unless $dry_run;
      }
   }
   $link_to_filepath = File::Spec->rel2abs(File::Spec->catfile(File::Spec->curdir(), 'hooks.d.local'));
   my $link_filepath = File::Spec->rel2abs(File::Spec->catfile($repo_cfg_dir, 'hooks.d'));

   print "Create link to directory 'hooks.d'. ";
   print "(used by Git::Hooks for user hooks).\n";
   if( -e $link_filepath && ! -l $link_filepath ) {
      die "The file '$link_filepath' already exists and it not a link. Aborting...";
   }
   else {
      my @unlink_params = ($link_filepath);
      my @symlink_params = ($link_to_filepath, $link_filepath);
      print "Execute: unlink ", (join ",", @unlink_params), " symlink ", (join ",", @symlink_params), "\n" if($verbose);
      unlink $link_filepath if (! $dry_run);
      symlink $link_to_filepath, $link_filepath if ( ! $dry_run);
   }
   return 1;
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
   print Dumper(\%params) if ($verbose);
   
   my $title = "Setup this Git repository";
   print "*" x ((length $title) + 8), "\n";
   print "*** $title ***\n";
   print "*" x ((length $title) + 8), "\n";

   if(! check_plenv() ) { exit 1; }
   install_prerequisites('verbose' => $verbose, 'dry_run' => $dry_run,
         'perl_version' => $perl_version, 'perl_name' => $perl_name );
   my $already_set = 1; #fix_git_config();
   #my $hooks_cfg_filename = 'config_hooks.central';
   my $hooks_cfg_linkname = 'config_hooks';
   fix_git_config('verbose' => $verbose, 'dry_run' => $dry_run,
         'repo_cfg_dir' => $repo_cfg_dir, 'hooks_cfg_linkname' => $hooks_cfg_linkname );
   if(! $already_set) {
      link_file_to_other_config('verbose' => $verbose, 'dry_run' => $dry_run,
            'repo_cfg_dir' => $repo_cfg_dir,
            'hooks_cfg_linkname' => $hooks_cfg_linkname, # config_hooks, normally
            'hooks_cfg_filename' => $hooks_cfg_filename, # config_hooks.(central|local)
            );
      setup_git_hooks('verbose' => $verbose, 'dry_run' => $dry_run,
           'hooks' => $hooks, );
   }
   else {
      print "Git config is already modified. Skipping reestablishing file links.\n";
   }
   return 0;
}

__END__

# End of Perl script


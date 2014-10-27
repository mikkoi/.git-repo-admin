#!/usr/bin/env perl
use strict; use warnings;
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

# Constants
use constant GIT_HOOKS => qw(
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

# Some globals:
my $verbose = $ENV{'GIT_HOOKS_DEBUG'};
my $repo_admin_dirname = File::Spec->rel2abs(File::Spec->catfile(
      File::Spec->curdir() ));
my $repo_base_dirname = File::Spec->rel2abs(File::Spec->catfile(
      $repo_admin_dirname, File::Spec->updir() ));
my $git_hooks_filename = File::Spec->rel2abs(File::Spec->catfile(
      $repo_admin_dirname, 'git-hooks.sh'));
my $central_repo_config_filename = File::Spec->rel2abs(File::Spec->catfile(
      $repo_admin_dirname, 'hooks_config.central'));
my $local_repo_config_filename = File::Spec->rel2abs(File::Spec->catfile(
      $repo_admin_dirname, 'hooks_config.local'));
my $config_filename = File::Spec->catfile(
      File::Spec->updir(), '.git', 'config');
my $link_to_other_config_dirname = File::Spec->rel2abs(File::Spec->catfile(
      File::Spec->updir(), '.git'));
my $other_config_linkname = 'hooks_config';
my $timestamp = (localtime)[5]+1900 . '-'
      . qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec )[(localtime time)[4]]
      . '-' . (localtime time)[3];

# The Perl version to use with plenv in local directory (for Git::Hooks).
my $perl_ver = '5.16.2';
my $RED = "\033[0;31m";
my $NO_COLOUR="\033[0m";

# params: [NONE]
sub install_prerequisites {
   print "Checking (and installing missing) prerequisites...\n";
   if(system('command -v anyenv >/dev/null') ) {
      print "Install 'anyenv'.\n";
      system("git clone https://github.com/riywo/anyenv ~/.anyenv");
      system("echo 'export PATH=\"\$HOME/.anyenv/bin:\$PATH\"' >> ~/.bash_profile");
      system("echo 'eval \"\$(anyenv init -)\"' >> ~/.bash_profile");
      print "\n\n\t", $RED, "Please run 'bash -l' to complete anyenv installation.", $NO_COLOUR, "\n";
      print "\tThen run this script again.\n";
      exit 0;
   }
   if(system('command -v plenv >/dev/null') ) {
      print "Install 'plenv'.\n";
      system('anyenv install plenv');
      print "\n\n\t", $RED, "Please run 'bash -l' to complete plenv installation.", $NO_COLOUR, "\n";
      print "\tThen run this script again.\n";
      exit 0;
   }
   print "Install Perl $perl_ver into 'plenv'.\n";
   system("plenv install $perl_ver");
   system("plenv rehash");
   system("plenv install-cpanm");
   system("plenv rehash");
   print "Installing 'Carton'.\n";
   system("cpanm Carton");
#   print "Install File::Slurp in advance because of problems in Git::Hooks.\n";
#   system("cpanm File::Slurp");
   print "Installing Perl dependencies using 'Carton'.\n";
   system("carton install");
   return 1;
}

# params: [NONE]
# Backup old and add to config only if the config didn't have it before.
sub fix_git_config {
   my @config_rows;
   my $config_bak_filename = $config_filename . '.bak_' . $timestamp;
   tie @config_rows, 'Tie::File', $config_filename || die;
   my $already_set = 0;
   foreach my $config_row (@config_rows) {
      print "Existing config:$config_row.\n" if($verbose);
      $already_set = 1 if($config_row =~ /$other_config_linkname/);
   }
   if( ! $already_set ) {
      print "Making a backup of the existing config and adding rows (to include another config file).\n";
      File::Copy::copy($config_filename, $config_bak_filename);
      push @config_rows, "[include]\n";
      push @config_rows, "\tpath = $other_config_linkname\n";
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
sub link_file_to_other_config {
   my $link_to_other_config_filepath = File::Spec->catdir($link_to_other_config_dirname, $other_config_linkname);
   if( is_central_repo() ) {
      print "Execute: unlink $link_to_other_config_filepath; symlink $central_repo_config_filename"
            . " $link_to_other_config_filepath\n" if($verbose);
      unlink $link_to_other_config_filepath; 
      symlink $central_repo_config_filename, $link_to_other_config_filepath;
   }
   else {
      print "Execute: unlink $link_to_other_config_filepath; symlink $local_repo_config_filename"
            . " $link_to_other_config_filepath\n" if($verbose);
      unlink $link_to_other_config_filepath; 
      symlink $local_repo_config_filename, $link_to_other_config_filepath;
   }
   return 1;
}

my $git_hooks_dirname = File::Spec->rel2abs(File::Spec->catfile(
      File::Spec->updir(), '.git', 'hooks'));
my $hooks_dirname = File::Spec->rel2abs(File::Spec->catfile(
      File::Spec->curdir(), 'hooks'));
#
sub setup_git_hooks {
   print "Creating symlinks in directory '.git/hooks' ";
   print "to connect to Git::Hooks ($git_hooks_filename).\n";
   foreach my $hook_filename (GIT_HOOKS) {
         my $git_hook_filepath = File::Spec->rel2abs(File::Spec->catfile(
                  $git_hooks_dirname, $hook_filename));
         print "unlink $git_hook_filepath; symlink $git_hooks_filename, $git_hook_filepath\n" if $verbose;
         unlink $git_hook_filepath;
         symlink $git_hooks_filename, $git_hook_filepath;
   }
   print "Create link to directory 'hooks.d'. ";
   print "(used by Git::Hooks to user-hooks).\n";
   symlink
      File::Spec->rel2abs(File::Spec->catfile($repo_admin_dirname, is_central_repo()
               ? 'hooks.central' : 'hooks.local')),
      File::Spec->rel2abs(File::Spec->catfile($repo_base_dirname, '.git', 'hooks.d'));
   return 1;
}

sub main {
   my $title = "Setup this Git repository";
   print "*" x ((length $title) + 8), "\n";
   print "*** $title ***\n";
   print "*" x ((length $title) + 8), "\n";

   install_prerequisites();
   my $already_set = fix_git_config();
   if(! $already_set) {
      link_file_to_other_config();
      setup_git_hooks();
   }
   else {
      print "Git config is already modified. Skipping reestablishing file links.\n";
   }
   return 0;
}

exit main(@ARGV);

__END__

# End of Perl script


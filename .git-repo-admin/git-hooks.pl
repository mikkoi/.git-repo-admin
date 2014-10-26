#!/usr/bin/env perl
use strict; use warnings;
my $central_repo_dir = shift @ARGV;
my $hook_name = shift @ARGV;
chdir $central_repo_dir;
print "git-hooks.pl now in dir '$central_repo_dir'.\n";
use Git::Hooks;
print "Executing: run_hook($hook_name, @ARGV)\n";
run_hook($hook_name, @ARGV);


#!/usr/bin/env perl
use strict; use warnings;
chdir $ARGV[0];
print "git-hooks.pl now in dir $ARGV[0].\n";
use Git::Hooks;
run_hook(-bash, @ARGV);

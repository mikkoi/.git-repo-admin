#!/usr/bin/env perl

use strict; use warnings;
my $central_repo_dir = shift @ARGV;
chdir $central_repo_dir;
print "Thank you for pushing to this repository.\n";
exit 0;


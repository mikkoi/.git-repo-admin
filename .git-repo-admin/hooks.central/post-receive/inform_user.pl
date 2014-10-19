#!/usr/bin/env perl
use strict; use warnings;
chdir $ARGV[0];
print "post-receive/inform_user.pl now in dir $ARGV[0].\n";
print "You have just cloned this repository.\n";
print "Please do not change the contents of directory '.git-repo-admin'.\n";
exit 0;

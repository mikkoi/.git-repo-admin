#!/usr/bin/env perl
use strict; use warnings;
chdir $ARGV[0];
use Git::Hooks;
run_hook(-bash, @ARGV);

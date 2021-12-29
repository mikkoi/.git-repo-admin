#!/usr/bin/env perl
use strict;
use warnings;
use 5.016; # Git::Hooks requirement
use English qw( -no_match_vars ) ;
use FindBin 1.51 qw( $RealBin );
use File::Spec;
my $lib_path;
my ($log_level, $log_file);
BEGIN {
    $lib_path = File::Spec->catdir(($RealBin =~ /(.+)/msx)[0], 'local', 'lib', 'perl5');
    my $log_path = File::Spec->catdir(($RealBin =~ /(.+)/msx)[0], 'githooks.log');
    $log_level = $ENV{GITHOOKS_LOG_LEVEL} // 'warning';
    $log_file = $ENV{GITHOOKS_LOG_FILE} // $log_path;
}
use lib "$lib_path";
# Git::Hooks uses Log::Any so we set it up.
use Log::Any::Adapter (File => $log_file, log_level => $log_level);
use Log::Any '$log';
use Git::Hooks;
# PROGRAM_NAME, the name of the hook file with path that was called
$PROGRAM_NAME =~ m/ (?: .*) [\/]{1} (?<hook_name> .+) $ /msx;
$log->debug("PROGRAM_NAME: '$PROGRAM_NAME'; hook_name: '" . $+{hook_name} . "'");
run_hook($+{hook_name}, @ARGV);

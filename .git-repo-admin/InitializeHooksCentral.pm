package InitializeHooksCentral;

use strict;
use warnings;

# Place here required bits for central hooks,
# Except CPAN Perl modules. Place those in cpanfile.
sub execute {
   my %params = @_;
   my $verbose = defined $params{'verbose'} ? $params{'verbose'} : 0;
   my $dry_run = defined $params{'dry_run'} ? $params{'dry_run'} : 0;
   my $action = defined $params{'action'} ? $params{'action'} : 0;
   print "Checking (and installing missing) prerequisites for central hooks...\n";
   return 1;
}

1;


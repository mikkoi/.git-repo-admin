#!/usr/bin/env bash
CURDIR=$( pwd )
echo "dir is:$CURDIR"
echo "I am:$0"
echo "Execute:exec carton exec perl -x $0"
exec carton exec "perl -x $0"
# End of Bash script.

# *** Begin Perl ***
#!/bin/perl
use Git::Hooks;
my $me = $0;
print "me:$me\n";
print "lib path:";
print join "\n", @INC;
exit 1;

__END__


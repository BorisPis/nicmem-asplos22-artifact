#!/usr/bin/perl -w
#-------------------------------------------------------------------------------
# The first line in the CSVs is preceded by a '#' character.
# Read the CSV from stdin, remove this character, and print without
#-------------------------------------------------------------------------------
use strict;
my $first = 1;
while(<>) {
    if( $first ) {
	print("$1\n") if( m/^\s*\#\s*(.*)$/ );
	$first = 0;
    } else {
	print
    }
}

#!/usr/bin/perl -w
#-------------------------------------------------------------------------------
# Percent of scatter plot points found at bottom left of subfigures
#-------------------------------------------------------------------------------
use strict;
use Text::CSV;
use Text::CSV::Hashify;
use Data::Dumper;

#-------------------------------------------------------------------------------
# config
#-------------------------------------------------------------------------------
my @cpus = qw(lowc highc);
my @mems = qw(lowm highm);
my @locs = qw(nic nic-inline host base);
#my @locs = qw(nic base);
my %metrics = 
    ('loss'    => {'field'=>'trex_rx_bps'  , 'yhi'=>  8.5 },
     'latency' => {'field'=>'trex_lat_avg2', 'yhi'=>128.0 },
);
my @metrics = keys (%metrics);
my $tmpcsv = '1.csv';
sub rx2loss($) {my $rx=shift; return 197.9 - (($rx)/1000000000.0);}

#-------------------------------------------------------------------------------
# convert specified csv file to ref2arr of ref2hashs, each holding a csv line
#-------------------------------------------------------------------------------
sub csv2arr($$$) {
    my ($loc, $mem, $cpu) = @_;
    my $fnam = "Results/result.$cpu.$mem.$loc.csv";
    system("./fix-csv.pl $fnam > $tmpcsv")==0 or die;
    my $csvh = Text::CSV::Hashify->new(
	{
	    file        => $tmpcsv,
	    format      => 'aoh', # "array of hash-s"
	} );
    unlink($tmpcsv);
    return $csvh->all; # ref2arr of ref2hashs, each holds csv line
}

#-------------------------------------------------------------------------------
# 
#-------------------------------------------------------------------------------
sub get_labels($) {
    
    my $loc = shift;
    my %ret = ('loss' => {'all'=>0, 'limited'=>0}, 
	       'latency' => {'all'=>0, 'limited'=>0} );
    
    foreach my $mem (@mems) {
	foreach my $cpu (@cpus) {
	    my $arr = csv2arr($loc,$mem,$cpu);
	    foreach my $h (@$arr) {
		foreach my $m (@metrics) {
		    my $val = $h->{$metrics{$m}{field}};
		    $val = rx2loss($val) if $m eq 'loss';
		    $ret{$m}{all}++;
		    $ret{$m}{limited}++	if($val < $metrics{$m}{yhi});
		}
	    }
	}
    }

    return \%ret;
}

#-------------------------------------------------------------------------------
# main
#-------------------------------------------------------------------------------
foreach my $loc (@locs) {
    my $labels = get_labels($loc);
    print "# $loc configs with ",
	"loss<$metrics{loss}{yhi}Gb/s & ",
	"latency<$metrics{latency}{yhi}us\n";
    foreach my $m (@metrics) {
	printf("%s,%s,%f,%f,%d,%d,%.0f%%\n", 
	       $loc, 
	       $m, 
	       1, 
	       $metrics{$m}{yhi},
	       $labels->{$m}{all}, 
	       $labels->{$m}{limited},
	       (100.0 - 100.0 * $labels->{$m}{limited} / $labels->{$m}{all}));
    }
}




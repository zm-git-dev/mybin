#!/usr/bin/perl -w
use strict;
use Getopt::Long;

=pod

USAGE: count_number.pl

-s --sep        ["\t"]

-c --column     [ 1 ]

-h --help

=cut

my %opts=(
	's' => "\t",
	'c' => 1,
);
GetOptions(\%opts,
	"s|sep=s",
	"c|column=i",
	"h|help",
);

die `pod2text $0` if($opts{h} or !@ARGV);
my $n=$opts{c}-1;
my $total=0;
my $count=0;
while(<>){
	chomp;
	my @F=split /$opts{s}/;
	next unless(defined $F[$n]);
#	print "$F[$n]\n";
	if($F[$n]=~/([\d\.]+)/){
		$total+=$1;
		$count++;
	}
}

print "total:$total\ncount:$count\naverage:".($total/$count)."\n";

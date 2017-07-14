#!/usr/bin/perl -w
use strict;

=pod

USAGE:  extract_GO.pl  Trinotate_report.xls  > Trinotate.txt

=cut

die `pod2text $0` unless @ARGV;
open IN,"<$ARGV[0]" or die $!;
while(<IN>){
	chomp;
	next if $.==1;
	my @F= split /\t/;
	my @go= /(GO:\d+)/g;
	if(@go){
		my $str= join "\t",$F[0],@go;
		print "$str\n";
	}
}
close IN;


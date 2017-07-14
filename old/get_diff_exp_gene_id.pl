#!/usr/bin/perl -w
use strict;

=pod

USAGE: get_diff_gene_id.pl gene_exp.diff >diff_id.txt

=cut

die `pod2text $0` unless @ARGV==1;
my %hash;
while(<>){
	chomp;
	next if $.==1;
	my @F=split /\t/;
	next if $F[2] eq '-';
	next if $F[-1] ne 'yes';
	$F[2]=~s/\,.*$//;
	$hash{$F[2]}++;
}
for (keys %hash){
	print "$_\n";
}

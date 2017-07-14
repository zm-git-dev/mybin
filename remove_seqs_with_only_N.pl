#!/usr/bin/perl -w
use strict;

=pod

USAGE: remove_seqs_with_only_N.pl original.fa >reference.fa

=cut

die `pod2text $0` unless @ARGV;
local $/="\n>";
#open OUT,">test.txt" or die $!;
while(<>){
	chomp;
	s/^>//;
	my @F=split /\n/,$_,2;
	$F[1]=~s/\n//g;
	if($F[1]=~/[ATCG]/){
		print ">$_\n";
	}
}

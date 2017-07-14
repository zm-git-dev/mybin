#!/usr/bin/perl -w
use strict;

=pod

USAGE: get_unigene.pl  Trinity.fasta  >Trinity.unigene.fa

=cut

die `pod2text $0` unless @ARGV;

open IN,"<$ARGV[0]" or die $!;
my %hash;
while(<IN>){
	chomp;
	next unless /^>/;
	my ($g,$i,$l)=  />(\S+\d+\_g\d+)\_i(\d+) len=(\d+)/;
	if(!$hash{$g} or $hash{$g}{len} < $l){
		$hash{$g}{i}=$i;
		$hash{$g}{len}=$l;
	}
}
close IN;

open IN,"$ARGV[0]" or die $!;
local $/="\n>";
while(<IN>){
	chomp;
	s/^>//;
	my @F=split /\n/,$_,2;
	if($F[0]=~/(\S+\d+\_g\d+)\_i(\d+)/){
		my ($g,$i)=($1,$2);
		if($hash{$g}{i} == $i){
#			print ">$_\n";
			print ">$g\n$F[1]\n";
		}
	}
}
close IN;

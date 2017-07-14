#!/usr/bin/perl -w 
use strict;

=pod

USAGE: get_diff_exp_gene_blastout.pl gene_exp.diff blastout6.txt 

OUTPUT: sample1_sample2.blastout.txt

=cut
 
my %hash;
die `pod2text $0` unless @ARGV==2;
open IN,"<$ARGV[0]" or die $!;
while(<IN>){
	chomp;
	next if /^test_id/;
	my @F=split /\t/;
	next if $F[-1] ne 'yes';
	$F[2]=~s/\,.*$//;
	$hash{$F[4]}{$F[5]}{$F[2]}++;
}
close IN;

my %blastout;
open IN,"<$ARGV[1]" or die $!;
while(<IN>){
	chomp;
	my @F=split /\t/,$_,2;
	$blastout{$F[0]}=$_;
}
close IN;

mkdir "kobas" or die $! unless -e "kobas";
for my $s1 (keys %hash){
	for my $s2(keys %{$hash{$s1}}){
		open OUT,">kobas/$s1\_$s2.blastout.txt" or die $!;
		for my $g(keys %{$hash{$s1}{$s2}}){
			print OUT "$blastout{$g}\n" if (exists $blastout{$g});
		}
		close OUT;
	}
}


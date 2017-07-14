#!/usr/bin/perl -w
use strict;

=pod

USAGE: get_diff_gene_ensembl_id.pl gene_exp.diff diff_ensembl_ids.txt


diff_ensembl_ids.txt file is the output of DAVID ID convert

OUTPUT: ./sample1_vs_sample2.txt

=cut

die `pod2text $0` unless @ARGV==2;

my %id;
open IN,"<$ARGV[1]" or die $!;
while(<IN>){
	chomp;
	next if /^From\tTo/;
	next unless $_;
	my @F=split /\t/;
	$id{$F[0]}{$F[1]}++;
}
close IN;

open IN,"<$ARGV[0]" or die $!;
my %hash;
while(<IN>){
	chomp;
	my @F=split /\t/;
	next unless $F[-1] eq 'yes';
	next if $F[2] eq '-';
	$F[2] =~s/\,.*$//;
	$hash{$F[4]}{$F[5]}{$F[2]}++;
}
close IN;

for my $s1 (keys %hash){
	for my $s2 (keys %{$hash{$s1}} ){
		open OUT,">$s1\_vs_$s2.txt" or die $!;
		for my $g (keys %{$hash{$s1}{$s2}}){
			next unless(exists $id{$g});
			for my $name(keys %{$id{$g}}){
				print OUT "$name\n";
			}
		}
		close OUT;
	}
	
}



#!/usr/bin/perl -w
use strict;

=pod 

USAGE: otu_stats.pl otu_table.txt  output_dir

=cut

die `pod2text $0` unless @ARGV==2;
open IN,"<$ARGV[0]" or die $!;
my @name;
my %hash;
my %taxonomy;
while(<IN>){
	chomp;
	my @F=split /\t/;
	next if /^# Constructed from biom file/;
	if(/^#/){
		@name=@F;
		next;
	}
	$taxonomy{$F[0]}=$F[-1];
	for my $i(1 .. $#F-1){
		my $s=$name[$i];
		$hash{$s}{$F[0]}=$F[$i];
	}
}
close IN;

$ARGV[1]=~s/\/$//;
system "mkdir -p $ARGV[1]" ;
for my $s(keys %hash){
	open OUT,">$ARGV[1]/$s.txt" or die $!;
	print OUT "OTU\tAbundance\tTaxonomy\n";
	for my $otu(sort { $hash{$s}{$b} <=> $hash{$s}{$a} }keys %{$hash{$s}}){
		last if $hash{$s}{$otu}==0;
		print OUT "$otu\t$hash{$s}{$otu}\t$taxonomy{$otu}\n";
	}
	close OUT;
}

system "txt_to_excel.pl -r 1 -s tab -W 8 -o $ARGV[1]/otu_stats.xlsx $ARGV[1]/*.txt ";

#!/usr/bin/perl -w 
use strict;

=pod

USAGE:

get_diff_gene_fpkm.pl gene_exp.diff genes.fpkm_tracking

OUTOUT:

diff_gene_fpkm.txt

=cut

die `pod2text $0` unless(@ARGV==2);
my $diff_gene_file=shift @ARGV;
open IN,"<$diff_gene_file" or die $!;
my %diff_gene;
while(<IN>){
	chomp;
	next if $.==1;
	my @F=split /\t/;
	$diff_gene{$F[1]}=$F[2] if $F[-1] eq 'yes';
}
close IN;

my $file=shift @ARGV;
open IN,"<$file" or die $!;
$file=~s![^/]+$!diff_gene_fpkm\.txt!;
my %have;
open OUT,">$file" or die $!;
while(<IN>){
	chomp;
	my @F=split /\t/;
	next if $F[4] eq '-';
	for my $g(split /\,/,$F[4]){
		if(exists $diff_gene{$F[0]} or $.==1){
			next if exists $have{$g};
			$have{$g}++;
			print OUT "$g";
			for (my $i=9;$i<$#F;$i+=4){
				$F[$i]=~s/\_FPKM// if($.==1);
				print OUT "\t$F[$i]";
			}
			print OUT "\n";
			last;
		}
	}
}
close IN;
close OUT;

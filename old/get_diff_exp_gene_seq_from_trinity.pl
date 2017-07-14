#!/usr/bin/perl -w
use strict;

=pod

USAGE: get_diff_exp_gene_seq_from_trinity.pl  output_dir Trinity.fasta  DE.subset ...

OUTPUT: outputdir/*.fa

EXAMPLE: get_diff_exp_gene_seq_from_trinity.pl  output_dir Trinity.fasta  DE_gene/*.subset

=cut

die `pod2text $0` unless @ARGV >=2;

my $output_dir=shift @ARGV;
$output_dir =~s/\/$//;
my $fa=shift @ARGV;
open IN,"<$fa" or die $!;
local $/="\n>";
my %seq;
while(<IN>){
	chomp;
	s/^>//;
	my @F=split /\n/,$_,2;
	$F[0]=~/^(c\d+\_g\d+)\_i\d+ len=(\d+)/;
	my ($g,$l)=($1,$2);
	$seq{$g}{$l}=$F[1];
}
close IN;

my %hash;
local $/="\n";
for my $file(@ARGV){
	open IN,"<$file" or die $!;
	$file=~/genes?\.counts\.matrix\.(\S+)\.edgeR/;
	my $name=$1;
	while(<IN>){
		chomp;
		next if /^id/;
		my @F=split /\t/,$_,2;
		$hash{$name}{$F[0]}++;
	}
	close IN;
}

mkdir $output_dir or die $! unless -e $output_dir;
for my $name(keys %hash){
	open OUT,">$output_dir/$name.fa" or die $!;
	for my $g(sort keys %{$hash{$name}}){
		for my $l(sort{$b<=>$a} keys %{$seq{$g}}){
			print OUT ">$g\n$seq{$g}{$l}\n";
			last;
		}
	}
	close OUT;
}

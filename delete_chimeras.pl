#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

=pod

USAGE:

delete_chimeras.pl   [opt]  seqs.fna

-l         [AGTCAGTCAGCC]

-n	   [ 10 ] 

-s	   [ 100000 ]

-h

=cut

my %opts=(
	n => 10,
	s => 100000,
	l => 'AGTCAGTCAGCC',
);
getopts('s:l:n:h',\%opts);
die `pod2text $0` if($opts{h} or !@ARGV);
local $/="\n>";
my $count=0;
my $num=1;
mkdir "splited_seqs" or die $! unless (-e "splited_seqs/");
open OUT,">splited_seqs/seq_$num.fna" or die $!;
my $infile=shift @ARGV ;
open IN,"<$infile" or die $!;
my @th;
while(<IN>){
	chomp;
	s/\r//g;
	s/^>//;
	my @array=split /\n/,$_,2;
	if($opts{l}){
		next unless($array[1]=~ /^$opts{l}/);
		$array[1]=~ s/^$opts{l}// ;
	}
	print OUT">$array[0]\n$array[1]\n";
	$count++;
	if($count % $opts{s} ==0){
		close OUT;
	#	system ("usearch -uchime splited_seqs/seq_$num.fna -db /MGCN/Databases/16S/gold.fa  -nonchimeras splited_seqs/seq_$num.good  ");
		$num++;
		open OUT,">splited_seqs/seq_$num.fna" or die $!;
	}
}
close IN;
close OUT;

#system ("usearch -uchime splited_seqs/seq_$num.fna -db /MGCN/Databases/16S/gold.fa  -nonchimeras splited_seqs/seq_$num.good");

open OUT,">__$$.pl" or die $!;
my $db="/MGCN/Databases/16S/gold.fa";
#my $db="/MGCN/Tools/anaconda2/lib/python2.7/site-packages/qiime_default_reference/gg_13_8_otus/rep_set/97_otus.fasta";

print OUT <<EOF;
my \$file=shift \@ARGV;
system ("usearch -uchime \$file -db $db  -nonchimeras \$file.good");
EOF


system "my_threads.pl -n $opts{n}  'perl __$$.pl' splited_seqs/*.fna"; 

system "rm __$$.pl";
system "cat splited_seqs/*.good >good.fna";






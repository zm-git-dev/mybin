#!/usr/bin/perl -w
use strict;
use Getopt::Long;
#use threads;
#use Bio::Seq;
#use Bio::SeqIO;

=pod

USAGE: rm_chimeric_seqs.pl 

opts:

-n --seq_per_file		[ default : 200000 ]

-m --max_thread			[ default : 10 ]

-f --fasta_file			[ required ]

-o --output			[ required ]

-p --pad		rm pad squence

-h --help

=cut

my %opts=(
	n => 200000,
	m => 10,
);
GetOptions(\%opts,
	"h|help",
	"n|seq_per_file=i",
	"m|max_thread=i",
	"f|fasta_file=s",
	"o|output=s",
	"p|pad",
);
die `pod2text $0` if($opts{h} or !$opts{f} or !$opts{o});
local $/="\n>";
my $count=0;
my $n=1;
system "mkdir -p split_seqs/";
open OUT,">split_seqs/seq$n.fna" or die $!;
open IN,"<$opts{f}" or die $!;
while(<IN>){
	chomp;
	s/^>//;
	my @F=split /\n/,$_,2;
	$F[1]=~s/\n//g;
	if($opts{p}){
		$F[1]=~s/^.{12}(.+).{12}$/$1/;
	}
	print OUT ">$F[0]\n$F[1]\n";
	$count++;
	if($count ==$opts{n}){
		#system "usearch7  -uchime_ref  split_seqs/seq$n.fna -db /MGCN/Databases/16S/gold.fa  -nonchimeras split_seqs/seq$n.fna.out  --strand plus";
		close OUT;
		$count=0;
		$n++;
		open OUT,">split_seqs/seq$n.fna" or die $!;
	}
}
close IN;
close OUT;

for my $i(1 .. $n){
	system "usearch7  -uchime_ref  split_seqs/seq$i.fna -db /MGCN/Databases/16S/gold.fa  -nonchimeras split_seqs/seq$i.fna.out  --strand plus";
}

#system "identify_chimeric_seqs.py -m usearch61 -r /MGCN/Databases/16S/gold.fa --suppress_usearch61_ref -i split_seqs/seq\$n.fna -o split_seqs/usearch61_chimeras\$n ";


system "cat split_seqs/*.out > $opts{o}";

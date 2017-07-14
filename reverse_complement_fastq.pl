#!/usr/bin/perl -w
use strict;
use Getopt::Std;

=pod

USAGE: reverse_complement_fastq.pl [opt] 

OPTION:

-i	input fastq file

-o	output reverse complement fastq file

-h	print this 

=cut

my %opts;
getopts('i:o:h',\%opts);
die `pod2text $0` if($opts{h} or !$opts{i} or !$opts{o});
open IN,"<$opts{i}" or die $!;
open OUT,">$opts{o}" or die $!;
while(<IN>){
	chomp;
        if($.%2==0){
               $_=reverse $_;
        }
        if($.%4==2){
               $_=~tr/AGCT/TCGA/;
        }
        print OUT"$_\n";
}
close IN;
close OUT;


#!/usr/bin/perl -w
use strict;
use Thread;

=pod

USAGE: run_cutadapter inputdir outputdir

=cut

die `pod2text $0` unless @ARGV==2;
opendir DIR,"$ARGV[0]" or die $!;
my $indir=$ARGV[0];
my $outdir=$ARGV[1];
$indir=~s/\/$//;
$outdir=~s/\/$//;
mkdir $outdir or die $! unless -e $outdir;
my @th;
my $i=0;
for my $name(readdir DIR){
	next if $name=~/^\./;
	next unless $name=~ /^(.*)_1.fastq.gz/;
	my $file=$1;
	$th[$i++]=Thread->new(sub{system "cutadapt -a GATCGGAAGAGCACACGTCTGAACTCCAGTCAC -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTAGATCTCGGTGGTCGCCGTATCATT -o $outdir/${file}_1.trim.fastq -p $outdir/${file}_2.trim.fastq -m 20 $indir/${file}_1.fastq.gz $indir/${file}_2.fastq.gz >$outdir/$file.log";});
}
close DIR;
for (@th){
	$_->join();
}

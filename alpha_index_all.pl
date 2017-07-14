#!/usr/bin/perl -w
use strict;
use File::Basename;

=pod

USAGE: alpha_index_all.pl   input.biom     out_prefix    < 16S|ITS >

=cut


die `pod2text $0 ` unless (@ARGV==2 or @ARGV==3);
die "$ARGV[2] must be one of : 16S , ITS \n" unless (!$ARGV[2] or $ARGV[2]=~/^(16S|ITS)$/i);
my $ITS=0;
$ITS= 1 if $ARGV[2];

my $dir=dirname $ARGV[0];

open IN,"<$dir/otu_summary.txt" or die $!;
my $flag=0;
my %count;
while(<IN>){
	chomp;
	if($flag){
		/(\S+): (\d+)/;
		$count{$1}=$2;
	}
	$flag=1 if /Counts\/sample detail:/;
}
close IN;

my $metrix= $ITS ? '-m observed_species,chao1,goods_coverage,shannon,simpson' : "-m  observed_species,ace,chao1,goods_coverage,PD_whole_tree,shannon,simpson  -t $dir/rep_set.tre";
system "alpha_diversity.py -i $ARGV[0] -o $ARGV[1].tmp  $metrix ";

open IN,"<$ARGV[1].tmp" or die $!;
open OUT,">$ARGV[1].txt" or die $!;
while(<IN>){
	chomp;
	my @F=split /\t/;
	my $s;
	if($.==1){
		$s=join "\t",'Sample','Reads','OTU',@F[2..$#F];
	}else{
		$s=join "\t",$F[0],$count{$F[0]},@F[1..$#F];
	}
	print OUT"$s\n";
}
close IN;
close OUT;

#system "txt_to_excel.pl -s tab -r  1 -f   -o $ARGV[1].xlsx  $ARGV[1].txt ";

system "rm  $ARGV[1].tmp";

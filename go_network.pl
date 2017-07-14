#!/usr/bin/perl -w
use strict;

=pod 

USAGE:
	go_network.pl  fg.txt  bg.txt   out_prefix

=cut

die `pod2text $0` unless @ARGV==3;
open IN,"<$ARGV[0]" or die $!;
my %fg;
while(<IN>){
	chomp;
	my @F=split /\t/;
	$fg{$F[0]}++;
}
close IN;
open IN,"<$ARGV[1]" or die $!;
my %bg;
my %go;
while(<IN>){
	chomp;
	my @F=split /\t/;
	$go{$F[0]}++ if $fg{$F[1]};
}
close IN;

my $str= join " -id " ,sort keys %go;
print "$str\n";
#system "go-filter-subset  -id $str -use_cache  -partial   /MGCN/Databases/GO/GO_June2016/go.obo >$ARGV[2].txt";

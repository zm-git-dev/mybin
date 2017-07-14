#!/usr/bin/perl 
use strict;
use warnings;

=pod

USAGE: order_otu_table.pl  ordered_map.txt   otu_table.txt > ordered_otu_table.txt

=cut

die `pod2text $0` unless(@ARGV==2);
my @order;
open IN,"<$ARGV[0]" or die $!;
while(<IN>){
	chomp;
	s/\r//g;
	next if /^#/;
	next if /^\s+$/;
	next unless $_;
	my @F=split /\t/;
	push @order,$F[0];
}
close IN;

open IN,"<$ARGV[1]" or die $!;
my @index;
while(<IN>){
	chomp;
	s/\r//g;
	next if /# Constructed from biom file/;
	next unless $_;
	my @array=split /\t/;
	if(/^#OTU ID/){
		for my $order(@order){
			for my $index(0.. $#array){
				if($order eq $array[$index]){
					push @index ,$index;
					last;
				}
			}
		}
	}
	print "$array[0]";
	for my $index(@index){
		print "\t$array[$index]";
	}
	print  "\t$array[-1]\n";
	
}
close IN;


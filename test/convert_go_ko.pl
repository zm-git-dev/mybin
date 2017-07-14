#!/usr/bin/perl -w
use strict;
use FileHandle;

=pod

USAGE: convert_go.pl go   prefix

=cut

die `pod2text $0` unless @ARGV==2;

my %fh;
for my $t(qw /C F P/){
	open $fh{$t},">$ARGV[1].$t" or die $!;
}

open IN,"<$ARGV[0]" or die $!;
while(<IN>){
	chomp;
	my @F=split /\t/;
	$fh{$F[2]}->print("$F[1]\t$F[0]\t$F[3]\n");
}
close IN;

for my $fh(keys %fh){
	close $fh;
}



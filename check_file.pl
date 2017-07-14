#!/usr/bin/perl -w
use strict;

=pod

USAGE: check_file.pl

=cut

die `pod2text $0` unless @ARGV;
my ($f1,$f2)=@ARGV;

open IN1,"$f1" or die $!;
open IN2,"$f2" or die $!;
while(<IN1>){
	chomp;
	my $l2=<IN2>;
	chomp $l2;
	next if $l2 eq $_;
	print "$.\t$_\t$l2\n";
}
close IN1;
close IN2;

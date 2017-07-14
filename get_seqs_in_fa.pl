#!/usr/bin/perl -w
use Data::Dumper;
use strict;

=head1 USAGE

get_seqs_in_fa.pl  seqs.fna  map.txt  min_length [column]   > out.fna

[column] such as: 1  or 1,4

=cut

die `pod2text $0` unless @ARGV;

my %hash;
my %have;
if(@ARGV==4){
	open IN,"cut -f $ARGV[3] $ARGV[1]|" or die $!;
	while(<IN>){
		chomp;
		next if /^#/;
		my @F=split /\s+/;
		$hash{$F[0]}=$F[1] if @F==2;
		$have{$F[0]}++ if @F==1;
	}
	close IN;
}
local $/="\n>";
open IN,"<$ARGV[0]" or die $!;
while(<IN>){
	chomp;
	s/^>//;
	/^(\S+)\_\d+/;
	my $name=$1;
	my @F=split /\n/,$_,2;
	$F[1]=~s/\n//g;
	next if ( length ($F[1]) < $ARGV[2]);
	if($hash{$name}){
		s/^$name/$hash{$name}/;
		print ">$_\n";
	}elsif($have{$name}){
		print ">$_\n";
	}else{
	}
}
close IN;

#!/usr/bin/perl

=head1 Description

	this script is used to merge several reports and give a comprehensive report contain the infomation of all the samples

=head1 Author and Version

	Yang chao: yangchao@macrogencn.com
	Version: 1.0

=head1 Usage

	 merge_seq.pl  sample_1 sample_2 ... sample_n 
	
=head1 Example

	merge_seq.pl  split?/seqs.fna  >seqs.fna
=cut

use warnings;
use strict;

die `pod2text $0` unless @ARGV;
local $/="\n>";
my $count=0;
#open OUT,">seqs.fna" or die $!;
while(<>){
	chomp;
	s/\r//g;
	s/^>//;
	my @array1=split /\n/,$_,2;
	my @array2=split / /,$array1[0],2;
	$array2[0]=~ s/\d+$/$count/;
	$array1[1]=~ s/\n//g;
	my $str=substr($array1[1],12);
	print  ">$array2[0] $array2[1]\n$str\n";
	$count++;
}

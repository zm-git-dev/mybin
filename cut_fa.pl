#!/usr/bin/perl -w
use strict;
use Getopt::Long;

=pod

USAGE: cut_fa.pl [opt]  input.fa

-n --num 	[ 10 ]

-h --help 

=cut

my %opts=( n => 10 );
GetOptions(\%opts,
	"n|num=i",
	"h|help",
);
die `pod2text $0` if($opts{h} or !@ARGV);
my $total= `grep -c ">" $ARGV[0]`;
my $count=int($total/$opts{n})+1;

open IN,"<$ARGV[0]" or die $!;
local $/="\n>";
my $c=1;
my $file=1;
open OUT,">$ARGV[0].$file" or die $!;
while(<IN>){
	chomp;
	s/^>//;
	print OUT ">$_\n";
	if($c >= $count){
		$c=1;
		close  OUT;
		$file++;
		open OUT,">$ARGV[0].$file" or die $! if($file <= $opts{n});
	}else{
		$c++;
	}
	
}
close IN;

#!/usr/bin/perl
use Getopt::Std;

=pod

USAGE:
	split_fasta_to_samples.pl -f <file.txt>  seqs.fasta

	-f txt file

	-h print this


	the txt file should be tab separated each line like this:
outfile_name1	sample_1	sample_2	
outfile_name2	sample_3	sample_4	sample5

=cut

my %opt;
getopts('f:h',\%opt);
die `pod2text $0` if($opt{h} or !@ARGV);
open IN,"<$opt{f}" or die $!;
my %hash;
while(<IN>){
	chomp;
	my @F=split /\t/;
	my $name=shift @F;
	for my $s(@F){
		$hash{$s}=$name;
	}
}
close IN;

local $/="\n>";
while(<>){
	chomp;
	s/^>//;
	my @F=split /\n/,$_,2;
	$F[0]=~ s/\_\d+ .*$//;
	if(exists $hash{$F[0]}){
		my $tmp=$hash{$F[0]};
		open OUT,">>$tmp" or die $!;
		print OUT ">$_\n";
	}
	close OUT;
	
}

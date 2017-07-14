#!/usr/bin/perl
use strict;
use warnings;

=pod

USAGE: alpha_index.pl   index_files   > alpha_index.txt

=cut

die `pod2text $0` unless @ARGV;
my @order;
my %hash;
my @alpha;
my %count;
for my $file(@ARGV){
	open IN,"<$file" or die $!;
	(my $alpha=$file)=~s/\.txt$//;
	$alpha =~s/.*\///;
	push @alpha,$alpha;
	while(<IN>){
		chomp;
		my @F=split /\t/;
		if ($.==1){
			@order=@F;
			next;
		}
		for my $i(3..$#F){
			next if $F[$i] eq 'n/a';
			$hash{ $order[$i] }{$F[1]}{$alpha}+=$F[$i];
			$count{$F[1]}++;
		}
	}
	close IN;
}

my $str=join "\t",@alpha;
print "Sample\tseq number\t$str\n";
for my $i(3 .. $#order){
	for my $c(sort {$a<=>$b}keys %{$hash{$order[$i]}}){
		print "$order[$i]\t$c";
		for my $alpha(sort keys %{$hash{$order[$i]}{$c}}){
			my $v=$hash{$order[$i]}{$c}{$alpha}/$count{$c};
			print "\t$v";
		}
		print "\n";
	}
}




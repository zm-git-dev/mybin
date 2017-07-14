#!/usr/bin/perl -w
use strict;

=pod

USAGE: collate_alpha.pl  alpha_div   collated/

=cut 

die `pod2text $0` unless @ARGV;

my @metrics;
$ARGV[0]=~s/\/$//;
opendir DIR,"$ARGV[0]" or die $!;
my %hash;
my @samples;
for my $f(readdir DIR){
	next if $f=~/^\./;
	open IN,"<$ARGV[0]/$f" or die $!;
	my ($seq_per_sam,$iteration)= $f=~/(\d+)\_(\d+)\.txt/;
	my @tmp_sam;
	while(<IN>){
		chomp;
		my @F=split /\t/;
		if(/^\t/){
			@metrics=@F unless @metrics;
			next;
		}
		push @tmp_sam,$F[0] if($iteration==0);
		for my $i(1..$#F){
			$hash{$metrics[$i]}{$seq_per_sam}{$iteration}{$F[0]}=$F[$i];
		}
	}
	close IN;
	@samples=@tmp_sam if scalar @samples < scalar @tmp_sam;
}


system "mkdir -p collated ";
for my $m(keys %hash){
	open OUT,">collated/$m.txt" or die $!;
	my $str=join "\t",@samples;
	print OUT "\tsequences per sample\titeration\t$str\n";
	for my $seq_per_sam(sort {$a<=>$b}keys %{$hash{$m}}){
		for my $iteration(sort {$a<=>$b}keys %{$hash{$m}{$seq_per_sam}}){
			$str="alpha_rarefaction_$seq_per_sam\_$iteration.txt\t$seq_per_sam\t$iteration";
			for my $s(@samples){
				my $value= $hash{$m}{$seq_per_sam}{$iteration}{$s} || 'n/a';
				$str.="\t$value";
			}
			print OUT "$str\n";
		}
	}
	close OUT;
}


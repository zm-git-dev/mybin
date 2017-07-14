#!/usr/bin/perl -w
use strict;

=pod

USAGE:
 
qc_stat.pl [seq.fa] seq_1.fastq seq_2.fastq  >stats.txt

=cut

die `pod2text $0` unless @ARGV;
my $num=@ARGV;
my $fa=  ($num %2==0) ? 0 : shift @ARGV;
my %hash;
if($fa){
	open IN,"<$fa" or die $!;
	local $/="\n>";
	while(<IN>){
		chomp;
		s/^>//;
		my @F=split /\s+/,$_,3;
		$F[0]=~s/\_\d+//;
		$hash{$F[1]}=$F[0] unless exists $hash{$F[1]};
	}
	close IN;
}
my (%q20,%q30,%gc,%at,%reads,%bases);
for my $f(@ARGV){
open IN, $f=~/\.gz/ ? "gzip -dc $f|" : "<$f"   or die $!;
my $s= $f=~s/^.*\/?(\S+)\_[\.A-Za-z\d]+$/$1/;
local $/="\n";
while(<IN>){
	chomp;
	my $l2=<IN>;
	my $l3=<IN>;
	my $l4=<IN>;
	chomp $l2;
	s/^\@//;
	s/\s.*$//;
	chomp $l4;
	next if($fa and !$hash{$_});
	my $sample= $fa ? $hash{$_} : $s ;
	$bases{$sample}+=length $l2;
	$reads{$sample}++;
	for my $i(0 .. (length $l2)-1  ){
		my $c=substr($l2,$i,1);
		if($c eq 'A' or $c eq 'T'){
			$at{$sample}++;
		}elsif($c eq 'G' or $c eq 'C'){
			$gc{$sample}++;
		}
		my $q=substr($l4,$i,1);
		my $asscii=ord($q);
		if($asscii-33>=20){
			$q20{$sample}++;
		}
		if($asscii-33>=30){
			$q30{$sample}++;
		}
	}
}
close IN;
}

print "SampleID\tTotal read bases(bp)\tTotal reads\tGC(%)\tAT(%)\tQ20(%)\tQ30(%)\n";
for my $s(sort {if($a=~/^\d+$/ and $b=~/^\d+$/){
		$a <=> $b;
	}else{
		$a cmp $b;
	}
} keys %reads){
	printf("%s\t%.0f\t%.0f\t%.3f\t%.3f\t%.3f\t%.3f\n",$s,$bases{$s},$reads{$s},100*$gc{$s}/$bases{$s},100*$at{$s}/$bases{$s},100*$q20{$s}/$bases{$s},100*$q30{$s}/$bases{$s});
}


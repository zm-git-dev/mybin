#!/usr/bin/perl -w
use strict;
use File::Basename qw /basename/;

=pod

USAGE:

filter_stat.pl   samples.stat  

OUTPUT: Filter_Info.xls  Data_Info.xls

=cut 

die `pod2text $0` unless @ARGV;
open OUT1,">Filter_Info.xls" or die $!;
open OUT2,">Data_Info.xls" or die $!;
print OUT1"Sample\tQ20\tQ30\tGC\tN\tQ20\tQ30\tGC\tN\n";
print OUT2"Sample\tBases\tReads\tLength(Max/Mean/Min)\tBase(%)\tReads(%)\tLength(Max/Mean/Min)\n";

for my $f(@ARGV){
	my $s=basename($f,".stat");
	open IN,"<$f" or die $!;
	my $str=$s;
	my %hash;
	my ($read_raw,$read_filter,$base_raw,$base_filter,$max_raw,$mean_raw,$min_raw,$max_filter,$mean_filter,$min_filter,$read_percent,$base_percent);
	while(<IN>){
		chomp;
		my @F=split /\t/;
		$str.="\t$F[1]"  if $.=~/^(9|11|13|15|25|27|29|31)$/  ;
		if($.==4){
			$read_raw=$F[1];
		}elsif($.==5){
			$base_raw=$F[1];
		}elsif($.==6){
			($max_raw,$min_raw)= $F[1]=~/^(\d+)\/(\d+)$/;
		}elsif($.==7){
			$mean_raw=$F[1];
		}elsif($.==20){
			$read_filter=$F[1];
		}elsif($.==21){
			$base_filter=$F[1];
		}elsif($.==22){
			($max_filter,$min_filter)=$F[1]=~/^(\d+)\/(\d+)$/;
		}elsif($.==23){
			$mean_filter=$F[1];
		}elsif(/clean reads/){
			($read_percent)= /([\.\d]+\%)/;
		}elsif(/clean data/){
			($base_percent)= /([\.\d]+\%)/;
		}
	}
	close IN;
	print OUT1"$str\n";
	print OUT2"$s\t$base_raw\t$read_raw\t$max_raw/$mean_raw/$min_raw\t$base_filter($base_percent)\t$read_filter($read_percent)\t$max_filter/$mean_filter/$min_filter\n";
}
close OUT1;
close OUT2;

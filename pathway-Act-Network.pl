#!/usr/bin/perl -w
use strict;

=pod 

pathway-Act-Network.pl  path.txt  fg.txt >path.network.txt

=cut

die `pod2text $0` unless @ARGV==2;


open IN,"<$ARGV[1]" or die $!;
my %gene;
while(<IN>){
	chomp;
	my @F=split /\t/;
	$gene{$F[0]}=  $F[1]>0 ? 'Up' : 'Down';
}
close IN;

open IN,"<$ARGV[0]" or die $!;
<IN>;
my %ko;
while(<IN>){
	my @F=split /\t/;
	next if $F[6] >0.05;
	$ko{$F[8]}++;
	my %tmp;
	for my $g(split /; /,$F[9]){
		$tmp{ $gene{$g} }++;
	}
	if(keys %tmp ==2){
		$ko{$F[8]}="UpDown";
	}elsif($tmp{Down}){
		$ko{$F[8]}="Down";
	}else{
		$ko{$F[8]}="Up";
	}
}
close IN;


open IN,"</MGCN/Databases/KEGG/pathway-Act-Network.txt" or die $!;
print "Source\tTarget\tSource-Pathway-Style\tTarget-Pathway-Style\n";
while(<IN>){
	chomp;
	my @F=split /\t/;
	if($ko{ "ko$F[0]"} and $ko{ "ko$F[2]" } ){
		print "$F[1]\t$F[3]\t".$ko{"ko$F[0]"}."\t".$ko{"ko$F[2]"}."\n";
	}
}
close IN;

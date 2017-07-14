#!/usr/bin/perl -w
use strict;

=pod

USAGE: config_tree.pl   < otu_table.txt >  < group.txt > < output_dir >  < first_num >

order :
range -> strip -> clade

=cut

die `pod2text $0` unless @ARGV==4;


open IN,"<$ARGV[1]" or die $!;
chomp($_=<IN>);
my @head= split /\t/;
my $Treatment;
my (@samples,@groups,%sample2group);
for my $i(0 .. $#head){
	$Treatment= $i if $head[$i] eq 'Treatment';
}
while(<IN>){
	chomp;
	my @F=split /\t/;
	push @samples,$F[0];
	push @groups,$F[$Treatment];
	$sample2group{$F[0]}=$F[$Treatment];
}
close IN;

my %hash;
my %map;
open IN,"$ARGV[0]" or die $!;
<IN>;
chomp($_=<IN>);
@head= split /\t/;
my (%count_sample,%count_group,%samples,%groups);
my (%count,%phylum);
while(<IN>){
	chomp;
	my @F=split /\t/;
	my ($phylum)=$F[-1]=~/; p__(\S+);/;
	next unless $phylum;
	for my $i(1 .. $#head -1 ){
		my $s=$head[$i];
		$count_sample{$F[0]}{$s}+= $F[$i];
		$count_group{$F[0]}{ $sample2group{$s} }+=$F[$i];
		$count{$phylum}+=$F[$i];
	}
	$phylum{$phylum}{$F[0]}++;
}
close IN;

my $step_sample= 16777215 /( @samples +1 );
my $color=0;
for my $i(@samples){
	$color+=$step_sample;
	$samples{$i}= sprintf "%x",$color; 
	my $len= 6-length $samples{$i} ;
	$samples{$i}= "#"."0"x $len ."$samples{$i}";
}

my $step_group= 16777215 /( @groups +1 );
$color=0;
for my $i(@groups){
	$color+=$step_group;
	$groups{$i}= sprintf "%x",$color; 
	my $len= 6-length $groups{$i} ;
	$groups{$i}= "#"."0"x $len ."$groups{$i}";
}


$ARGV[2]=~s/\/$//g;
system "mkdir -p $ARGV[2]";
open OUT,">$ARGV[2]/range.txt" or die $!;
print OUT "TREE_COLORS\nSEPARATOR TAB\nDATA\n";
open OUT2,">$ARGV[2]/clade.txt" or die $!;
print OUT2 "TREE_COLORS\nSEPARATOR TAB\nDATA\n";
open OUT3,">$ARGV[2]/strip.txt" or die $!;
print OUT3 "DATASET_COLORSTRIP\nSEPARATOR SPACE\nDATASET_LABEL color_strip1\nCOLOR #ff0000\nSHOW_INTERNAL 0\nCOLOR_BRANCHES 1\nSTRIP_WIDTH 25\nMARGIN 0\nBORDER_WIDTH 1\nBORDER_COLOR #000\nDATA\n";
my $n=0;
$color=0;
my $step= 16777215 /($ARGV[3]+1);
for my $p(sort {$count{$b} <=> $count{$a} }keys %count){
	last if $n++  >= $ARGV[3];
	$color+=$step;
	my $col= sprintf "%x",$color;
	my $len=6-length $col;
	$col= "#"."0"x $len . "$col";
	for my $otu(sort keys %{$phylum{$p}}){
		print OUT"$otu\trange\t$col\t$p\n";
		print OUT2 "$otu\tclade\t$col\tnormal\t1\n$otu\tlabel\t$col\tbold\t1\n";
		print OUT3"$otu $col COL$col\n";
	}
}
close OUT;
close OUT2;
close OUT3;


open OUT,">$ARGV[2]/sample_bar.txt" or die $!;
print OUT "DATASET_MULTIBAR\nSEPARATOR COMMA\nDATASET_LABEL,example multi bar chart,test2\nCOLOR,#ff0000\nWIDTH,1000\nMARGIN,0\nSHOW_INTERNAL,0\nHEIGHT_FACTOR,1\nBAR_SHIFT,0\nFIELD_LABELS,".(join ",",@samples) . "\nFIELD_COLORS,".(join ",",map{ $samples{$_} } @samples)."\nDATASET_SCALE,100,200,300,400\nDATA\n";
for my $otu(sort keys %count_sample){
	my $tmp=$otu;
	for my $s(@samples){
		$tmp.=$count_sample{$otu}{$s} ? ",$count_sample{$otu}{$s}" :",0" ;
	}
	print OUT "$tmp\n";
}
close OUT;

open OUT,">$ARGV[2]/group_bar.txt" or die $!;
print OUT "DATASET_MULTIBAR\nSEPARATOR COMMA\nDATASET_LABEL,example multi bar chart\nCOLOR,#ff0000\nWIDTH,1000\nMARGIN,0\nSHOW_INTERNAL,0\nHEIGHT_FACTOR,1\nBAR_SHIFT,0\nFIELD_LABELS,".(join ",",@groups) . "\nFIELD_COLORS,".(join ",",map{ $groups{$_} } @groups)."\nDATASET_SCALE,100,300,500,700\nDATA\n";
for my $otu(sort keys %count_group){
	my $tmp=$otu;
	for my $s(@groups){
		$tmp.= $count_group{$otu}{$s} ? ",$count_group{$otu}{$s}" : ",0" ;
	}
	print OUT "$tmp\n";
}
close OUT;

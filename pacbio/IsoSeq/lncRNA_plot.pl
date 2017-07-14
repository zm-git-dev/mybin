#!/usr/bin/perl -w
use strict;

=pod

USAGE: lncRNA_plot.pl  lncRNA_ref.fa  lncRNA_Isoseq.fa   splice_type_file  bed_file  output_prefix

=cut

die `pod2text $0` unless @ARGV;


open IN,"<$ARGV[0]" or die $!;
local $/="\n>";
my %ref_len;
my $min=100000;
my $max=0;
while(<IN>){
	chomp;
	s/^>//;
	my @F=split /\n/,$_,2;
	$F[1]=~s/\n//g;
	my $l=length $F[1];
	$min=$l if $l < $min;
	$max=$l if $l > $max;
	$ref_len{$l}++;
}
close IN;

my %isoseq_len;
my %isoseq;
open IN,"<$ARGV[1]" or die $!;
while(<IN>){
	chomp;
	s/^>//;
	my @F=split /\n/,$_,2;
	$F[1]=~s/\n//g;
	my $l=length $F[1];
	$isoseq_len{$l}++;
	$isoseq{$F[0]}++;
	$min=$l if $l < $min;
	$max=$l if $l > $max;
}
close IN;

open OUT,">$ARGV[4].violin.txt" or die $!;
print OUT "Type\tLength\n";
$min = 200 if $min <200;
for my $l($min .. $max){
	my $ref_n= $ref_len{$l} // 0;
	my $isoseq_n = $isoseq_len{$l} // 0;
	print OUT "Ref\t$l\n"x $ref_n ;
	print OUT "Isoseq\t$l\n"x $isoseq_n ;
}
close OUT;

open OUT,">__$$.R" or die $!;
print OUT <<R;
library("ggplot2")
dat <- read.csv("$ARGV[4].violin.txt",sep="\\t")

dat\$Type=factor(dat\$Type,level=c("Ref","Isoseq") )
ggplot(dat,aes() )+
	geom_violin(  aes(x=factor(Type),y=Length,fill=factor(Type)   ) )+
	theme_bw()+
	labs(x='',y='lncRNA Length',fill="" )+
	theme(plot.margin=unit(c(1.5,1.5,1.5,1.5),"cm"),legend.position=c(0.2,0.8) )+
	scale_x_discrete( labels=c("Known lncRNA","Novel lncRNA") )+
	scale_fill_hue(  labels=c("Known","Novel") )

ggsave("$ARGV[4].violin.pdf")
ggsave("$ARGV[4].violin.png")

R

system "Rscript __$$.R";

system "rm __$$.R ";


open IN,"<$ARGV[2]" or die $!;
local $/="\n";
<IN>;
my %classify;
while(<IN>){
	chomp;
	next if /^\s*$/;
	my @F=split /\t/;
	next unless $isoseq{$F[0]};
	if($F[3] eq 'Novel_Gene' ){
		$classify{Intergenic}++;
	}elsif($F[3] eq 'Exclusive' ){
		$classify{Exclusive}++;
	}elsif($F[3] eq 'Pac_Exon_In_Ref_Intron' or $F[3] eq 'Ref_Exon_In_Pac_Intron'){
		$classify{Intronic}++;
	}elsif($F[4] eq '-'){
		$classify{Antisense}++;
	}elsif($F[4] eq '+'){
		$classify{Sense}++;
	}else{
		print "$F[0]\n";
	}
}
close IN;

open OUT,">$ARGV[4].classify.txt" or die $!;
print OUT "Type\tCount\tPercent\n";
my $total=scalar keys %isoseq;
for my $t(sort keys %classify){
	my $c=$classify{$t};
	printf OUT "%s\t%d\t%.2f%%\n",$t,$c,100*$c/$total;
}
close OUT;

open OUT,">__$$.R" or die $!;
print OUT <<R;
dat <- read.csv("$ARGV[4].classify.txt",sep="\\t")

labs= paste(dat\$Type,dat\$Percent,sep="\n" )
pdf("$ARGV[4].classify.pdf")
pie(dat\$Count,labels=labs )
dev.off()

png("$ARGV[4].classify.png")
pie(dat\$Count,labels=labs )
dev.off()
R
system "Rscript __$$.R" ;
system "rm __$$.R";

open IN,"<$ARGV[3]" or die $!;
my %exon_num;
while(<IN>){
	chomp;
	my @F=split /\t/;
	my $n=  split /,/,$F[-1];
	if( $isoseq{$F[3]} ){
		$exon_num{LncRNA}{$F[3]}+=$n;
	}else{
		$exon_num{'Non_LncRNA'}{$F[3]}+=$n;
	}
}
close IN;

my %exon_count;
my %count;
for my $t(keys %exon_num){
	for my $s(keys %{$exon_num{$t}}){
		my $c= $exon_num{$t}{$s};
		$exon_count{$c}{$t}++;
		$count{$t}++;
	}
}

open OUT,">$ARGV[4].exon_num.txt" or die $!;
print OUT "Exon_Num\tLncRNA\tLncRNA_Density\tNon_LncRNA\tNon_LncRNA_Density\n";
my %accum=(
	LncRNA => 0,
	Non_LncRNA =>0,
);
for my $c(sort {$a<=>$b}keys %exon_count){
	last if $c>10;
	print OUT "$c";
	for my $t(qw /LncRNA Non_LncRNA/){
		my $n=$exon_count{$c}{$t}  // 0;
		$accum{$t}+=$n;
		my $num=$exon_count{$c}{$t} // 0;
		printf OUT  "\t%d\t%.4f",$num,$num/$count{$t};
	}
	print OUT "\n";
}
printf OUT ">10\t%d\t%.4f\t%d\t%.4f\n",$count{LncRNA}-$accum{LncRNA},($count{LncRNA}-$accum{LncRNA})/$count{LncRNA} ,$count{Non_LncRNA}-$accum{Non_LncRNA},($count{Non_LncRNA}-$accum{Non_LncRNA})/$count{Non_LncRNA}  ;
close OUT;

open OUT,">__$$.R" or die $!;
print OUT <<R;
library(ggplot2)
library(reshape2)
dat <- read.csv("$ARGV[4].exon_num.txt",sep="\\t")

dat <- melt(dat,id.vars=c("Exon_Num"), measure.vars=c("LncRNA_Density","Non_LncRNA_Density") )
dat\$Exon_Num <- factor(dat\$Exon_Num,level=dat\$Exon_Num  )
ggplot(dat,aes(x=Exon_Num,y=value))+
	geom_bar(stat="identity",aes(fill=variable),position="dodge")+
	labs(x="Number of Exons",y="Density",fill="")+
	theme_bw()+
	theme(plot.margin=unit(c(1.5,1.5,1.5,1.5),"cm"),legend.position=c(0.5,0.8) )+
	scale_fill_hue( labels=c( "LncRNA","Non-LncRNA") )
ggsave("$ARGV[4].exon_num.pdf")
ggsave("$ARGV[4].exon_num.png")
R

system "Rscript __$$.R";
unlink "__$$.R";	





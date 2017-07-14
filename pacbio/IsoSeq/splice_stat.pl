#!/usr/bin/perl -w
use strict;

=pod

USAGE: splice_stats.pl  < ref_lst >  < file_lst > < output_prefix >

=cut

die `pod2text $0` unless (@ARGV==2 or @ARGV==3);
my $prefix= @ARGV==2 ? "Alternative_Splicing" : $ARGV[2];


system "splicegraph_statistics.py  $ARGV[0]  -o $ARGV[0].stat";
system "splicegraph_statistics.py  $ARGV[1]  -o $ARGV[1].stat";
my (%splice,$total_ref,$total_pac);
open IN,"<$ARGV[0].stat" or die $!;
while(<IN>){
	if($.==3){
		my @F= /([\d,]+) \(([\d\.\%]+)\)/g;
		@F = map{ s/,//g;$_ } @F;
		my @tmp1=@F[0,2,4,6];
		my @tmp2=@F[1,3,5,7];
		($total_ref)= /([\d,]+)$/;
		$total_ref=~s/,//g;
		$splice{Annotation}= \@tmp1,
		$splice{Annotation_percent}= \@tmp2,
	}
}
close IN;

open IN,"<$ARGV[1].stat" or die $!;
while(<IN>){
	if($.==3){
		my @F= /([\d,]+) \(([\d\.\%]+)\)/g;
		@F = map{ s/,//g;$_ } @F;
		my @tmp1=@F[0,2,4,6];
		my @tmp2=@F[1,3,5,7];
		($total_pac)= /([\d,]+)$/;
		$total_pac=~s/,//g;
		$splice{Isoseq}= \@tmp1,
		$splice{Isoseq_percent}= \@tmp2,
	}
}
close IN;

my @type=('Intron Retention' , 'Skipped Exon' , 'Alt. 5' , 'Alt. 3' );
open OUT,">$prefix.event.txt" or die $!;
print OUT "Type\tAnnotation\tAnnotation_Percent\tIsoseq\tIsoseq_Percent\n";
for my $i(0..3){
	print OUT "$type[$i]\t$splice{Annotation}[$i]\t$splice{Annotation_percent}[$i]\t$splice{Isoseq}[$i]\t$splice{Isoseq_percent}[$i]\n";
}
print OUT "Total\t$total_ref\t100%\t$total_pac\t100%\n";
close OUT;

open OUT,">__$$.R" or die $!;
print OUT <<R;
library(ggplot2)
library(reshape2)
dat <- read.csv("$prefix.event.txt",sep="\\t")
lev= dat\$Type
dat <- melt(dat,id.vars=c("Type"),measure.vars=c("Annotation","Isoseq"), )
dat\$Type <- factor(dat\$Type,level=lev)
ggplot(dat ,aes(x=Type,y=value) )+
	geom_bar(stat="identity",aes(fill=variable),position="dodge")+
	labs(x='Alternative splicing events',y='Number of events',fill="" )+
	theme_bw()+
	theme(plot.margin=unit(c(1.5,1.5,1.5,1.5),"cm") ,legend.position=c(0.2,0.8)  )
	
ggsave("$prefix.event.pdf")
ggsave("$prefix.event.png")

R
system "Rscript __$$.R";
system "rm __$$.R  $ARGV[0].stat $ARGV[1].stat";


my %hash;
open IN,"<$ARGV[1]" or die $!;
while(<IN>){
	chomp;
	my $n= `grep -c 'parent' $_`;
	chomp $n;
	$hash{$n}++;
}
close IN;

open OUT,">$prefix.Isoform_number.txt" or die $!;
print OUT "Isoform_Number\tGene_Count\n";
my $larger_than_5=0;
for my $n(sort {$a<=>$b}keys %hash){
	if($n<=5){
	print OUT "$n\t$hash{$n}\n";
	}else{
		$larger_than_5++;
	}
}
print OUT ">5\t$larger_than_5\n";
close OUT;

open OUT ,">__$$.R" or die $!;
print OUT <<R;
library(ggplot2)
dat <- read.csv("$prefix.Isoform_number.txt",sep="\\t")
dat\$Isoform_Number <- factor(dat\$Isoform_Number,level=dat\$Isoform_Number)
m <- max(dat\$Gene_Count)
ggplot(dat,aes(x=Isoform_Number,y=Gene_Count,label=Gene_Count) )+
	theme_bw()+
	labs(x="Isoform Number",y="Number of genes")+
	theme(legend.position="None",plot.margin=unit(c(1,1,1,1),"cm" )+
	geom_bar(stat="identity",fill="pink")+
	geom_text(nudge_y=0.05*m,size=4)

ggsave("$prefix.Isoform_number.pdf")
ggsave("$prefix.Isoform_number.png")

R

system "Rscript  __$$.R";

system "rm __$$.R  ";

#!/usr/bin/perl -w
use strict;

=pod

USAGE: Trinity_length_distrubution.pl  Trinity.fasta  [Trinity.fasta.transdecoder.pep]

OUTPUT:  contig.txt unigene.txt [ORF.txt] length_distrbution.pdf

=cut

die `pod2text $0` unless (@ARGV);
local $/="\n>";
my %contig;
my %unigene2len;
open IN,"<$ARGV[0]" or die $!;
while(<IN>){
	chomp;
	s/^>//;
	my @F=split /\n/,$_,2;
	$F[1]=~s/\n//g;
	my $l=length $F[1];
	my $len= $l >2000 ? 2000 : int(($l-1)/100)*100;
	$F[0]=~/^(\w*c\d+\_g\d+)/;
	$contig{$len}++;
	$unigene2len{$1}=$l if(!$unigene2len{$1} or $unigene2len{$1} < $l);
}
close IN;

my %unigene;
for my $g(keys %unigene2len){
	my $l=$unigene2len{$g};
	my $len= $l >2000 ? 2000 : int(($l-1)/100)*100;
	$unigene{$len}++;
}

open OUT,">contig.txt" or die $!;
print OUT "Length\tCount\n";
for (my $i=0;$i<2000;$i+=100){
	$contig{$i}=0 unless $contig{$i};
	print OUT "$i-".($i+100)."\t$contig{$i}\n";
}
print OUT ">2000\t$contig{2000}\n";
close OUT;

open OUT,">unigene.txt" or die $!;
print OUT "Length\tCount\n";
for (my $i=0;$i<2000;$i+=100){
	$unigene{$i}=0 unless $unigene{$i};
	print OUT "$i-".($i+100)."\t$unigene{$i}\n";
}
print OUT ">2000\t$unigene{2000}\n";
close OUT;

my %orf;
if(-e $ARGV[1]){
	open IN,"<$ARGV[1]" or die $!;
	while(<IN>){
		chomp;
		s/^>//;
		my @F=split /\n/,$_,2;
		$F[1]=~s/\n//g;
		my $l=length $F[1];
		my $len= $l >1000 ?1000: int(($l-1)/50)*50;
		$orf{$len}++;
	}
	close IN;
	open OUT,">ORF.txt" or die $!;
	print OUT "Length\tCount\n";
	for (my $i=0;$i<1000;$i+=50){
		$orf{$i}=0 unless $orf{$i};
		print OUT "$i-".($i+50)."\t$orf{$i}\n";
	}
	print OUT ">1000\t$orf{1000}\n";
	close OUT;
}

my $n= scalar keys %orf ? 3 : 2;
open OUT,">__$$.R" or die $!;
print OUT <<EOF;
library("ggplot2")
library("scales")
par(mar=c(4,4,8,4))
pdf("length_distribution.pdf")
file=c("contig.txt","unigene.txt","ORF.txt")
name=c("Contig","Unigene","ORF")
myxlab=c("(nt)","(nt)","(aa)")
mycol=c("lightpink","lightblue","lightgreen")
for (i in 1:$n){
	dat<- read.table(file[i],header=T,sep="\t")
	dat\$Length <- factor(dat\$Length,levels=dat\$Length)
	dat\$Count=dat\$Count+1
	p <- ggplot(data=dat,aes(x=Length,y=Count))+
		geom_bar(stat="identity",fill=mycol[i],width=0.7)+
		scale_y_log10(breaks=c(0,10,100,1000,10000,100000,1000000) )+
		labs(x=paste("Length",myxlab[i],sep=" "),y="Count",fill="",title=paste(name[i],"Length Distribution",sep=" ") )+
		theme(axis.text.x=element_text(angle=45) ,plot.title=element_text(size=rel(2),hjust=0.5 ),plot.margin=unit(c(1,1,1,1),"cm") ) 
	plot(p)
}
dev.off()

EOF

system "/usr/bin/Rscript __$$.R";
unlink "__$$.R";

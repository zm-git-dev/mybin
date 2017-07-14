#!/usr/bin/perl -w
use strict;
use Getopt::Long;

=pod 

USAGE: reads_stat.pl   seqs.fna

-a --angle	 default : 0

-m --map  

-h --help

=cut 

my %opts=(
	a => 0,
);
GetOptions(\%opts,
	"a|angle=i",
	"m|map=s",
	"h|help",
);
die `pod2text $0` if( $opts{h} or @ARGV !=1);

local $/="\n>";
my %len;
my %num;
while(<>){
	chomp;
	s/^>//;
	my @F=split /\n/,$_,2;
	(my $s)=$F[0]=~/(\S+)\_\d+/;
	$F[1]=~s/\n//g;
	my $l=length $F[1];
	$len{$l}++;
	$num{$s}++;
}

my @order;
if($opts{m}){
	local $/="\n";
	open IN,"<$opts{m}" or die $!;
	while(<IN>){
		chomp;
		next if /^#/;
		my @F=split /\t/;
		next unless $F[0]=~/\w/;
		push @order , $F[0];
	}
	close IN;
}

open OUT,">seq_number.txt" or die $!;
print OUT "Sample\tCount\n";
@order=sort keys %num unless @order;
for my $s(@order){
	my $c= $num{$s} || 0;
	print OUT "$s\t$c\n";
}
close OUT;

open OUT,">length_distribution.txt" or die $!;
print OUT "Length\tCount\n";
for my $l(sort{$a<=>$b}keys %len){
	print OUT "$l\t$len{$l}\n";
}
close OUT;
my $script= "__$$.R";
open OUT,">$script" or die $!;
print OUT <<R;
library('ggplot2')
dat=read.csv("seq_number.txt",sep="\t")
dat\$Sample=factor(dat\$Sample,levels=dat\$Sample)
p=ggplot(dat,aes(Sample,Count))+
	geom_bar(stat="identity",fill="lightpink")+
	theme_bw()+
	theme(legend.position="none",axis.text.x=element_text(angle=$opts{a}),plot.margin=unit(c(0.5,0.5,0.5,0.5),"cm" ) )
ggsave("seq_number.png",p)
dat=read.csv("length_distribution.txt",sep="\t")
q=ggplot(dat,aes(Length,Count))+
	theme_bw()+
	geom_line(stat="identity",color='red')
ggsave("length_distribution.png",q)

R

system "/usr/bin/Rscript __$$.R";
#unlink "__$$.R";
unlink "$script";
system "txt_to_excel.pl -s tab -f -r 1 -o 1.sequence_stat.xlsx seq_number.txt length_distribution.txt";


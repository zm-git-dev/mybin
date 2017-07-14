#!/usr/bin/perl -w
use strict;
use Getopt::Long;

=pod

USAGE:
	plot_transcription_factor_barplot.pl  [opts] TF.list

-f --fasta     Trinity.fasta

-h --help
	
OUTPUT:  TF_count.txt , TF.pdf

=cut

my %opts;
GetOptions(\%opts,
	"f|fasta=s",
	"h|help",
);

die `pod2text $0` unless @ARGV;

my %unigene;
if($opts{f}){
	open IN,"<$opts{f}" or die $!;
	local $/="\n>";
	while(<IN>){
		chomp;
		s/^>//;
		my @F=split /\n/,$_,2;
		$F[0]=~/((c\d+\_g\d+)\_i\d+) len=(\d+)/;
		if(!$unigene{$2}  or  $unigene{$2}{length} < $3){
			$unigene{$2}{unigene}=$1;
			$unigene{$2}{length}=$3;	
		}
	}
	close IN;
}

open IN,"<$ARGV[0]" or die $!;
open OUT,">TF_count.txt" or die $!;
my %hash;
while(<IN>){
	chomp;
	my @F=split /\t/;
	$F[0]=~/((c\d+\_g\d+)\_i\d+)/;
	next if ($opts{f}  and $unigene{$2}{unigene} ne $1);
	$hash{$F[1]}{$F[0]}++;
}
close IN;

my %tmp;
for my $tf(keys %hash){
	my $n=keys %{$hash{$tf}};
	$tmp{$n}{$tf}++;
}

print OUT"TF\tCount\n";
for my $n(sort {$b<=>$a}keys %tmp){
	for my $tf(sort keys %{$tmp{$n}}){
		print OUT"$tf\t$n\n";
	}
}
close OUT;

open OUT,">__$$.R" or die $!;
print OUT <<EOF;
library("ggplot2")
dat=read.csv("TF_count.txt",sep="\\t",header=T)
dat\$TF= factor(dat\$TF,levels=rev(dat\$TF)) 
m=max(dat\$Count)
pdf("TF.pdf")
ggplot(data=dat,aes(x=TF,y=Count,label=Count))+
	geom_bar(stat="identity",aes(fill=TF))+
	coord_flip()+
	geom_text(nudge_y=0.05*m,size=2)+
	labs(x="Transcription Factor",y="Count",fill="")+
	theme(legend.position="none")

dev.off()
EOF

system "Rscript __$$.R";
unlink "__$$.R";



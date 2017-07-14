#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Data::Dumper;

=pod

USAGE: kegg.pl   sample.blastout

-s --species         [required]

-t --type            [default : blastout:tab]

-h --help

=cut

my %opts=(
	t => "blastout:tab",
);
GetOptions(\%opts,
	"s|species=s",
	"t|type=s",
	"h|help",
);

die `pod2text $0` if($opts{h} or !@ARGV or !$opts{s});
my %ko_to_c2;
my %c2_to_c1;
open IN,"</MGCN/Databases/KEGG/map_title.tab" or die $!;
while(<IN>){
	chomp;
	my @F=split /\t/;
	$ko_to_c2{$F[0]}=$F[2];
	$c2_to_c1{$F[2]}=$F[1];
}
close IN;

(my $prefix=$ARGV[0])=~s/\.\w+$//;
#system "annotate.py -i $ARGV[0] -o $prefix.anno -t $opts{t} -s $opts{s} "; 
#system "identify.py -b $opts{s} -f $prefix.anno -d K -o $prefix.anno.iden";

open IN,"$prefix.anno.iden" or die $!;
my %kegg;
while(<IN>){
	chomp;
	next if /^#/;
	next unless $_;
	if(/KEGG PATHWAY/){
		my @F=split /\t/;
		$F[2]=~s/[a-z]+//;
		my $c2=$ko_to_c2{$F[2]};
		my $c1=$c2_to_c1{$c2};
		$kegg{$c1}{$c2}+=$F[3];
	}elsif(/^\('[^']+', 'K', '[a-z]+(\d+)'\) (\d+)/){
		my $c2=$ko_to_c2{ $1};
		my $c1=$c2_to_c1{$c2};
		$kegg{$c1}{$c2}+=$2
	}
}
close IN;

open OUT,">$prefix.anno.iden.tab" or die $!;
print OUT "c1\tc2\tInputNumber\n";
for my $c1(sort keys %kegg){
	for my $c2(sort keys %{$kegg{$c1}}){
		my $n=$kegg{$c1}{$c2};
		print OUT "$c1\t$c2\t$n\n";
	}
}
close OUT;

open OUT,">__$$.R" or die $!;
print OUT <<EOF;
library("ggplot2")
pdf(paste("$prefix",".KEGG.pdf",sep=""))
dat <- read.csv(paste("$prefix",".anno.iden.tab",sep=""),sep="\t")
dat\$c2 <- factor(dat\$c2,levels=dat\$c2)
dat\$c1 <- factor(dat\$c1,levels=rev(unique(dat\$c1)))
m <- max(dat\$InputNumber)

ggplot(dat,aes(x=c2,y=InputNumber,label=InputNumber))+
	geom_bar(stat="identity",aes(fill=c1))+
	coord_flip()+
	geom_text(nudge_y=0.05*m,size=2)+
	labs(x="",y="Numbers of Genes",fill="",title="$prefix")+
	theme(legend.key.width=unit(0.1,"cm"),legend.key.height=unit(3,"cm"),legend.text=element_text(angle=270,size=5),legend.text.align=0.5 )

dev.off()
EOF

system "Rscript __$$.R";
unlink "__$$.R";

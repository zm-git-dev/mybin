#!/usr/bin/perl -w
use strict;

=pod

USAGE: plot_pie3D.pl  < input.txt > < output.pdf >

=cut

die `pod2text $0` unless @ARGV==2;
open OUT,">__$$.R" or die $!;
print OUT <<R;
library("plotrix")
dat <- read.csv("$ARGV[0]",sep="\\t")
pdf("$ARGV[1]")
n <- nrow(dat)
mycol <- rainbow(n)
pie3D(dat\$Count,radius=1.5,height=0.2,theta=pi/6,start=0,border=par('fg'), col=mycol,labels= paste(dat\$Percent,"%",sep=""),labelpos=NULL,labelcol=par("fg"),labelcex=1.5,  sector.order=NULL,explode=0.2,shade=0.8,mar=c(4,4,10,4),pty="s" )
legend('topright',legend=dat\$Type,xpd=T,col=mycol,fill=mycol,inset=-0.2,box.col="white" )

dev.off()
R

system "Rscript  __$$.R";
unlink "__$$.R";

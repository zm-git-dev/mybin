#!/usr/bin/perl -w
use strict;

=pod

USAGE: go_barplot.pl output.pdf  *.enriched

=cut

die `pod2text $0` unless @ARGV;
my $output=shift @ARGV;

open OUT,">__$$.R" or die $!;
print OUT <<EOF;

ARGV=commandArgs()
pdf("$output")

par(mar=c(4,18,4,2),las=1 )
files=ARGV[6:length(ARGV)]
for (i in 1:length(files) ){
	dat=read.csv(files[i],header=T,sep="\\t" )
	prefix=sub("\\\\.txt\\\\.GOseq\\\\.enriched","",files[i])
	dat=dat[1:40,c(2,7,6)]
	mydat=rbind(dat[dat[,2]=='BP',],dat[dat[,2]=='MF',],dat[dat[,2]=='CC',])
	mydat[,1]= -log10(mydat[,1])
	mydat[,4]=ifelse(mydat[,2]=='BP','green',ifelse(mydat[,2]=='MF','blue','red') )
	height=as.matrix( mydat[,1] )
	rownames(height)=mydat[,3]

	barplot(rev(height),width=1,space=1,axes=F,xlim=c(0,1.5*max(mydat[,1])),border=rev(mydat[,4]),ylim=c(0,80), beside=T, horiz=T, col=rev(mydat[,4])  )
	axis(3)
	par(cex=0.5)
	axis(2,at=seq(1.5,79.5,2),label=rev(rownames(height) ),tick=F,  )
	par(cex=1)
	mtext( expression("- Log"[10] ^ "   Pvalue of GO enriched" ),side=3,line=2,cex=0.8,adj=0 )
	legend("topright",fill=c("green","blue","red"),legend=c("GOBP","GOMF","GOCC") ,bty='n' )
	mtext( prefix,side=1,line=1,adj=0)
}


dev.off()
EOF

system "Rscript __$$.R @ARGV";
unlink "__$$.R";

#!/usr/bin/perl -w
use strict;

=pod

USAGE:  evaluate.pl  stat.txt output_prefix

=cut

die `pod2text $0` unless @ARGV==2;

open OUT,">__$$.R" or die $!;
print OUT<<R;
library(ggplot2)

dat <- read.csv("$ARGV[0]",sep="\\t",header=F)
dat <- dat[c(2,4,5),]
colnames(dat) <- c("Type","Count")
labs=paste(dat\$Type,dat\$Count,sep="\n")
pdf("$ARGV[1].pdf")
pie(dat\$Count,labels=labs)
dev.off()
png("$ARGV[1].png")
pie(dat\$Count,labels=labs)
dev.off()
R

system "Rscript __$$.R";
system "rm __$$.R";

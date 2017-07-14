#!/usr/bin/perl -w
use strict;

=pod

USAGE:  plot_UPGMA_tree.pl  weighted.txt  [weighted.pdf]



=cut

die `pod2text $0` if(!@ARGV);
(my $prefix=$ARGV[0]) =~s/\..*$//;

my $out= $ARGV[1] ? $ARGV[1] : "$prefix.pdf";
open OUT,">$$.R" or die $!;
print OUT <<EOF;
library("vegan")
pdf("$out")
dat <- read.csv("$ARGV[0]",sep="\t")
rownames(dat) <- dat[,1]
dat <- dat[,-1]
dat <- as.matrix(dat)
dat <- as.dist(dat)
clusa <- hclust(dat,"average")
den <- as.dendrogram(clusa)
op <- par(mar=c(2,2,2,4)+.1)
plot(den,horiz=TRUE)

dev.off()
EOF

system "/usr/bin/Rscript $$.R";
unlink "$$.R";

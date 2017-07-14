#!/usr/bin/perl -w
use strict;
use Data::Dumper;

=pod

USAGE: plot_NMDS_3d_plot.pl  otu_table.txt output.pdf  map.txt

=cut

die `pod2text $0` unless @ARGV==3;
my @fill=('red','orange','blue','purple','yellow');
my @pch=(21..25);
my $index=0;

open IN,"<$ARGV[0]" or die $!;
open OUT,">__$$.txt" or die $!;
my @samples;
my @group;
while(<IN>){
	my @F=split /\t/;
	if(/^#OTU ID/){
		s/^#//;
		for my $i(1 .. ($#F-1)){
			push @samples,$F[$i];
		}
	}elsif(/^#/){
		next;
	}
	my $s=join "\t",@F[0..($#F-1)];
	print OUT "$s\n";
}
close IN;
close OUT;

open IN,"<$ARGV[2]" or die $!;
my $treatment;
my %hash;
my %have;
while(<IN>){
	chomp;
	my @F=split /\t/;
	if(/^#SampleID/){
		for my $i(0.. $#F){
			$treatment=$i if $F[$i] eq 'Treatment';	
		}
		next;
	}
	my $t=$F[$treatment];
	
	if(!$have{$t}{fill}){
		$have{$t}{fill}= $fill[$index];
		$have{$t}{pch} = $pch[$index];
		$index++;
		push @group,$t;
	}
	$hash{$F[0]}{fill}= $have{$t}{fill};
	$hash{$F[0]}{pch} = $have{$t}{pch};
}
my $fill= join ",", map{ "\"$hash{$_}{fill}\"" } @samples;
my $pch= join ",", map{ "$hash{$_}{pch}" } @samples;
my $group= join ",", map{ "\"$_\"" } @group;
my $legend_fill= join ",", map{ "\"$_\"" } @fill;
my $legend_pch = join ",", @pch;

open OUT,">__$$.R" or die $!;
print OUT <<R;
library("vegan")
library("vegan3d")
pdf("$ARGV[1]")
dat<-read.csv("__$$.txt",sep="\t",row.names=1)
dat = dat[1:20,]
dat = t(dat)
ord = metaMDS(dat,distance="bray",k=3,trymax=100)
pc= eigenvals(ord)[1:3]/ord\$tot.chi
ordiplot3d(ord,type="p",bg=c($fill),pch=c($pch),xlab=sprintf("PC1 (%.1f%%)",100*pc[1]),ylab=sprintf("PC2 (%.1f%%)",100*pc[2]),zlab=sprintf("PC3 (%.1f%%)",100*pc[3])  )
legend('topright',legend=c($group),pt.bg=c($legend_fill),pch=c($legend_pch),xpd=T,box.col='white',inset=0 )

dev.off()
R
system "/usr/bin/Rscript __$$.R";
#unlink "__$$.R", "__$$.txt";

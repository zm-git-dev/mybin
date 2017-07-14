#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Basename qw /basename/;

=pod

USAGE: plot_bam_describe.pl   sample.bam

-s --suffix		sample suffix [default : .bam]

-t --target		target region file

=cut

my %opts=(
	s => '.bam',
);
GetOptions(\%opts,
	"s|suffix=s",
	"t|target=s",
);
die `pod2text $0` if($opts{h} or @ARGV !=1);
my $file=shift @ARGV;
my $base=basename($file,$opts{s});

if($opts{t}){
	system "samtools depth -b $opts{t} -a $file>$base.depth" ;
	open IN,"<$base.depth" or die $!;
	my %depth;
	my $total;
	while(<IN>){
		chomp;
		my @F=split /\t/;
		$depth{$F[2]}++;
		$total++;
	}
	close IN;
	open OUT1,">$base.depth.hist" or die $!;
	print OUT1 "Depth\tProportion\n";
	open OUT2,">$base.depth.cumulate.hist" or die $!;
	print OUT2 "Depth\tPercent\n";
	my $cumulate=100;
	for my $d(sort{$a<=>$b}keys %depth){
		print OUT1 "$d\t".$depth{$d}/$total."\n";
		print OUT2 "$d\t$cumulate\n";
		$cumulate-= 100*$depth{$d}/$total;
	}
	close OUT1;
	close OUT2;

	open OUT,">__$$.R" or die $!;
	print OUT <<R;

dat1=read.csv("$base.depth.hist",sep="\t")
dat2=read.csv("$base.depth.cumulate.hist",sep="\t")
png("$base.depth.png",width=480,height=480)
#barplot2(dat1,col="blue",xlab="Sequence depth",ylab="Proportion of target region")
plot(x=dat1[,1],y=dat2[,2],type="h",col="blue")
dev.off()
png("$base.depth.cumulate.png",width=480,height=480)
plot(x=dat2[,1],y=dat2[,2],type="l",col="red")
dev.off()
R
	system "/usr/bin/Rscript __$$.R";
}





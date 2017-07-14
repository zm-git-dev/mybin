#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Getopt::Long;

=pod

USAGE: plot_3d_plot.pl  -m  map.txt   otu_table.txt

-m --map

-o --output 		output dir  [ default "./" ]

-s --suffix		output name suffix [ default "" ]

-i --inset		[ default : -0.05 ]

-h --help

=cut
my %opts=(
	o => '.',
	s => '',
	i => -0.05,
);
GetOptions(\%opts,
	"m|map=s",
	"h|help",
	"o|output=s",
	"s|suffix=s",
	"i|inset=f",
);
die `pod2text $0` if ($opts{h} or @ARGV==0  ) ;
$opts{o}=~s/\/$//;
my @fill=('red','orange','blue','purple','yellow','pink','black','navy');
my @pch=(21..25,21..25);
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

open IN,"<$opts{m}" or die $!;
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
	next unless $F[0] ~~ @samples;
	if(!$have{$t}{fill}){
		$have{$t}{fill}= $fill[$index];
		$have{$t}{pch} = $pch[$index];
		$index++;
		push @group,$t ;
	}
	$hash{$F[0]}{fill}= $have{$t}{fill};
	$hash{$F[0]}{pch} = $have{$t}{pch};
}
close IN;
my $fill= join ",", map{ "\"$hash{$_}{fill}\"" } @samples;
my $pch= join ",", map{ "$hash{$_}{pch}" } @samples;
my $group= join ",", map{ "\"$_\"" } @group;
my $legend_fill= join ",", map{ "\"$_\"" } @fill;
my $legend_pch = join ",", @pch;

open OUT,">__$$.R" or die $!;
print OUT <<R;
library("vegan")
library("vegan3d")
dat<-read.csv("__$$.txt",sep="\t",row.names=1)
dat = t(dat)
test=decorana(dat)
m=max(test\$rproj)
if(m >4){
	ord = cca(dat)
	str = 'CA'
	name= 'CA'
}else{
	ord = rda(dat)
	str = 'PC'
	name= 'PCA'
}


out=paste("$opts{o}/",'3d_',name,'_plot','$opts{s}','.pdf',sep="")
pdf(out)

pc= eigenvals(ord)[1:3]/ord\$tot.chi
ordiplot3d(ord,type="p",bg=c($fill),pch=c($pch),xlab=sprintf("%s1 (%.2f%%)",str,100*pc[1]),ylab=sprintf("%s2 (%.2f%%)",str,100*pc[2]),zlab=sprintf("%s3 (%.2f%%)",str,100*pc[3])  )
legend('topright',legend=c($group),pt.bg=c($legend_fill),pch=c($legend_pch),xpd=T,box.col='white',inset=$opts{i} )

dev.off()
R
system "/usr/bin/Rscript __$$.R";
unlink "__$$.R", "__$$.txt";

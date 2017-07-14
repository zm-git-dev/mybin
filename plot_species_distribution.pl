#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Data::Dumper;

=pod

USAGE:  plot_species_distribution.pl  -d database.fa  nr.blastout *

-d --database         database fasta sequence [default : /MGCN/Databases/nr/plant.fa ]

-m --min_number       min_number as other [default : 1 ]

-h --help

=cut

my %opts=(
	d => "/MGCN/Databases/nr/plant.fa",
	m => 1,
);
GetOptions(\%opts,
	"d|database=s",
	"m|min_number=i",
	"h|help",
);

die `pod2text $0` if($opts{h} or !@ARGV);

open IN,"<$opts{d}" or die $!;
local $/="\n>";
my %gi2sp;
while(<IN>){
	chomp;
	s/^>//;
	my @F=split /\n/,$_,2;
	$F[0]=~/^(\S+).+\[(.+)\]$/;
	$gi2sp{$1}=$2;
}
close IN;

local $/="\n";
for my $f(@ARGV){
	my %have;
	my %count;
	open IN,"<$f" or die $!;
	(my $prefix=$f)=~s/\.[^\.]+$//;
	while(<IN>){
		chomp;
		my @F=split /\t/;
		next if $have{$F[0]};
		$have{$F[0]}++;
		next unless $gi2sp{$F[1]};
		my $s=$gi2sp{$F[1]};
		$count{ $s}++;
	}
	close IN;
	my %hash;
	for (keys %count){
		$hash{ $count{$_}}{$_}++;
	}
	
	open OUT,">$prefix.stat" or die $!;
	print OUT "Species\tCount\n";
	my $other=0;
	for my $c(sort{$b<=>$a}keys %hash){
		for my $n(keys %{$hash{$c}}){
			if($c<=$opts{m}){
				$other+=$c;
				next;
			}
			print OUT"$n\t$c\n";
		}
	}
	print OUT "others\t$other\n";
	close OUT;
	&myplot("$prefix.stat");
}


sub myplot{
	my $in=shift @_;
	(my $out=$in)=~s/stat$/pdf/;
	open OUT,">__$$.R" or die $!;
	print OUT <<EOF;
library("ggplot2")
dat=read.csv("$in",sep="\\t")
dat\$Species=factor(dat\$Species,levels=rev(dat\$Species) )
m=max(dat\$Count)
pdf("$out")
ggplot(data=dat,aes(x=Species,y=Count,label=Count))+
	geom_bar(stat="identity",aes(fill=Species))+
	coord_flip()+
	geom_text(nudge_y=0.05*m,size=2)+
	labs(x="Species",y="Count",fill="",title="Species Distribution")+
	theme(legend.position="none",plot.title=element_text(size=rel(2) ) )

n=nrow(dat)
tmp=dat
if(n>21){
	tmp=dat[c(1:20,n),]
	tmp[21,2]=sum(dat[21:n,2])
}
tmp\$Species=factor(tmp\$Species,levels=tmp\$Species)

mycol=c("grey","lemonchiffon","orange","black","firebrick","green","purple","lightblue","navy","khaki","pink","deeppink","forestgreen","blanchedalmond","mediumorchid","gold","lightgreen","seashell","red","yellow","blue")
total=sum(dat[1:n,2])
percent=ifelse(100*tmp[,2]/total>1, sprintf("%2.2f%s",100*tmp[,2]/total,"%"), NA)
par(mar=c(2,2,2,14))

pie(tmp\$Count,labels=percent,col=rev(mycol),border="white",init.angle=90,cex=0.5)
legend("right",xpd=T,inset=-0.65,legend=tmp\$Species,col=rev(mycol),bty="n",pch=15,pt.cex=2,cex=0.8  )

dev.off()
EOF
	
	system "/usr/bin/Rscript __$$.R";
	unlink "__$$.R";
}




#!/usr/bin/perl -w
use strict;
use Getopt::Long;

=pod

USAGE: plot_COG.pl [opt]   prefix Trinity.fasta   trinotate_report.xls  

opt:

-f --func     default : /MGCN/Databases/COG/COG2014/fun2003-2014.tab

-c --cog  default : /MGCN/Databases/COG/COG/cog

-g --cog2014  

-k --kog  default : /MGCN/DAtabases/COG/KOG/kog

-h --help   

OUTPUT: COG.txt KOG.txt prefix_COG_KOG.pdf

=cut

my %opts=(
	f => '/MGCN/Databases/COG/COG2014/fun2003-2014.tab',
	c => '/MGCN/Databases/COG/COG/whog',
	k => '/MGCN/Databases/COG/KOG/kog',
);
GetOptions(\%opts,
	"f|func=s",
	"c|cog=s",
	"k|kog=s",
	"g|cog2014=s",
	"h|help",
);

die `pod2text $0` unless @ARGV==3;
my $prefix=shift @ARGV;
my $fa=shift @ARGV;

open IN,"<$opts{f}" or die $!;
my %func;
while(<IN>){
	chomp;
	next if /^#/;
	my @F=split /\t/;
	$func{$F[0]}=$F[1];
}
close IN;

my %cog;
if($opts{g}){
	open IN,"<$opts{g}" or die $!;
	while(<IN>){
		chomp;
		next if /^#/;
		my @F=split /\t/;
		my $l=(length $F[1])-1;
		for my $i(0 .. $l){
			my $s=substr($F[1],$i,1);
			$cog{$F[0]}{$s}++;
		}
	}
	close IN;
}elsif($opts{c}){
	open IN,"<$opts{c}" or die $!;
	while(<IN>){
		chomp;
		next unless /^\[(\w+)\] (\w+)/;
		my ($str,$k)=($1,$2);
		my $l=(length $str)-1;
		for my $i(0 .. $l){
			my $s=substr($str,$i,1);
			$cog{$k}{$s}++;
		}
	}
	close IN;
}else{
	die "one of option 'c' or 'g' must be specified!\n";
}

open IN,"<$opts{k}" or die $!;
my %kog;
while(<IN>){
	chomp;
	next unless /^\[(\w+)\] (\w+)/;
	my ($str,$k)=($1,$2);
	my $l=(length $str)-1;
	for my $i(0 .. $l){
		my $s=substr($str,$i,1);
		$kog{$k}{$s}++;
	}
}
close IN;

open IN,"<$fa" or die $!;
local $/="\n>";
my %unigene;
while(<IN>){
	chomp;
	s/^>//;
	my @F=split /\n/,$_,2;
	$F[0]=~/((c\d+\_g\d+)\_i\d+) len=(\d+)/;
	if(!$unigene{$2} or $unigene{$2}{length} < $3){
		$unigene{$2}{unigene}=$1;
		$unigene{$2}{length}=$3;
	}
}
close IN;

local $/="\n";
my %count_cog;
my %count_kog;
my (%have_cog,%have_kog);
while(<>){
	chomp;
	my @F=split  /\t/;
	next if /^#/;
	next unless $unigene{$F[0]}{unigene} eq  $F[1];
	if(!$have_cog{$F[0]} and $F[10]=~/COG\d+/){
		$have_cog{$F[0]}++;
		for my $s(keys %{$cog{$&}}){
			$count_cog{$s}++;
		}	
	}elsif(!$have_kog{$F[0]} and $F[10]=~/KOG\d+/){
		$have_kog{$F[0]}++;
		for my $s(keys %{$kog{$&}}){
			$count_kog{$s}++;
		}
	}
	
}

open OUT,">COG.txt" or die $!;
print OUT "Term\tCount\tDescription\n";
for my $s( 'A' .. 'Z'){
	$count_cog{$s}=0 unless $count_cog{$s};
	print OUT "$s\t$count_cog{$s}\t$func{$s}\n";
}
close OUT;

open OUT,">KOG.txt" or die $!;
print OUT "Term\tCount\tDescription\n";
for my $s('A' .. 'Z'){
	$count_kog{$s}=0 unless $count_kog{$s};
	print OUT "$s\t$count_kog{$s}\t$func{$s}\n";
}
close OUT;

open OUT,">__$$.R" or die $!;
print OUT <<EOF;

cog=read.csv("COG.txt",sep="\t")
kog=read.csv("KOG.txt",sep="\t")
max_cog=1.2*max(cog\$Count)
max_kog=1.2*max(kog\$Count)
pdf(paste("$prefix","_COG_KOG.pdf",sep="") )
par(mar=c(4,4,4,14),mgp=c(2,0.5,0) )
mycol=c("grey","lemonchiffon","orange","red","blue","green","purple","lightblue","navy","khaki","pink","deeppink","forestgreen","blanchedalmond","mediumorchid","gold","lightgreen","seashell","firebrick","yellow","black","maroon","dodgerblue","turquoise","salmon","chocolate")

barplot(cog\$Count,col=mycol,width=1,space=0.5,border=T,xlab="Function class",ylab="Number of Unigenes",ylim=c(0,max_cog),names.arg=cog\$Term,cex.names=0.3 ,main="COG",axisname=F  )
axis(1,at=seq(1,38.5,1.5),labels=cog\$Term,font.axis=2,tck=-0.01,cex.axis=0.3)
box(lwd=2)
legend("right",legend=paste(cog\$Term,cog\$Description,sep=" : "),xpd=T,inset=-0.8,cex=0.5,box.col="white")

barplot(kog\$Count,col=mycol,width=1,space=0.5,border=T,xlab="Function class",ylab="Number of Unigenes",ylim=c(0,max_kog),names.arg=cog\$Term,cex.names=0.3 ,main="KOG",axisname=F  )
axis(1,at=seq(1,38.5,1.5),labels=cog\$Term,font.axis=2,tck=-0.01,cex.axis=0.3)
box(lwd=2)
legend("right",legend=paste(cog\$Term,cog\$Description,sep=" : "),xpd=T,inset=-0.8,cex=0.5,box.col="white")

dev.off()
EOF

system "Rscript __$$.R";
unlink "__$$.R";



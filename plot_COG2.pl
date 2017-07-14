#!/usr/bin/perl -w
use strict;
use Getopt::Long;

=pod

USAGE: plot_COG.pl   < -c cog >  < -i input > < -o out_prefix >

-c --cog <str>    	KOG|COG|COG2014 

-i --input <file>	input blast file

-o --out_prefix <str>

-h --help   

EXAMPLE:

plot_COG.pl  -i blastx.txt -o sample -c COG 


=cut

my %par=(
	fun => '/MGCN/Databases/COG/COG2014/fun2003-2014.tab',
	COG => '/MGCN/Databases/COG/COG/whog',
	KOG =>  '/MGCN/Databases/COG/KOG/kog',
	COG2014 => '/MGCN/Databases/COG/COG2014/cognames2003-2014.tab',
	gi2cog => '/MGCN/Databases/COG/COG2014/cog2003-2014.csv',
	gi2name => '/MGCN/Databases/COG/COG2014/name.txt',
);
my %opts;
GetOptions(\%opts,
	"c|cog=s",
	"o|out_prefix=s",
	"i|input=s",
	"h|help",
);

die `pod2text $0` if($opts{c}!~/^(COG|KOG|COG2014)$/ or !$opts{o} or !$opts{i} or $opts{h});

open IN,"<$par{fun}" or die $!;
my %fun;
while(<IN>){
	chomp;
	next if /^#/;
	my @F=split /\t/;
	$fun{$F[0]}=$F[1];
}
close IN;

my (%cog,$func);
if($opts{c} eq 'KOG' or $opts{c} eq 'COG'){
	
	open IN,"<$par{ $opts{c}  }" or die $!;
	while(<IN>){
		chomp;
		if(/^\[([A-Z]+)\]/){
			$func=$1;
		}elsif(/(\w+):\s+(\S+)/){
			$cog{$2}=$func;
		}
	}
	close IN;
}elsif($opts{c} eq 'COG2014'){
	open IN,"<$par{COG2014}" or die $!;
	my (%cog2func);
	while(<IN>){
		chomp;
		next if /^#/;
		my @F=split /\t/;
		$cog2func{$F[0]}=$F[1];
	}
	close IN;

	open IN,"<$par{gi2cog}" or die $!;
	my %gi2cog;
	while(<IN>){
		chomp;
		my @F=split /,/;
		$gi2cog{$F[0]}{$F[6]}++;
	}
	close IN;
	open IN,"<$par{gi2name}" or die $!;
	while(<IN>){
		chomp;
		s/^>//;
		my @F=split /\s+/,$_,2;
		my @arr=split /\|/,$F[0];
		my %tmp;
		for my $c(keys %{$gi2cog{$arr[1]}}){
			next unless $cog2func{$c};
			for my $f (split //,$cog2func{$c}){
				$tmp{$f}++;
			}
		}
		$cog{ $F[0] }=  join "",sort keys %tmp;
	}
	close IN;
}

my %count;
open IN,"<$opts{i}" or die $!;
while(<IN>){
	chomp;
	my @F=split /\t/;
	next unless $cog{$F[1]};
	for my $f(split //,$cog{$F[1]}){
		$count{$f}++;
	}
}
close IN;

my $suffix= $opts{c} eq 'KOG' ? 'KOG' : 'COG';
open OUT,">$opts{o}.$suffix.txt" or die $!;
print OUT "ShortName\tFullName\tCount\n";

for my $f( 'A'..'Z'){
	print OUT "$f\t".($fun{$f} // 0)."\t".($count{$f} // 0)."\n";
}
close OUT;
system "txt_to_excel.pl -s tab -r 1 -f -n Sheet1 $opts{o}.$suffix.txt";

open OUT,">__$$.R" or die $!;
print OUT <<EOF;

cog=read.csv("$opts{o}.$suffix.txt",sep="\t",header=T)
max_cog=1.2*max(cog\$Count)
pdf("$opts{o}.$suffix.pdf" )
par(mar=c(4,4,4,14),mgp=c(2,0.5,0) )
mycol=c("grey","lemonchiffon","orange","red","blue","green","purple","lightblue","navy","khaki","pink","deeppink","forestgreen","blanchedalmond","mediumorchid","gold","lightgreen","seashell","firebrick","yellow","black","maroon","dodgerblue","turquoise","salmon","chocolate")

barplot(cog\$Count,col=mycol,width=1,space=0.5,border=T,xlab="Function class",ylab="Number of Unigenes",ylim=c(0,max_cog),names.arg=cog\$ShortName,cex.names=0.3 ,main="$suffix",axisname=F  )
axis(1,at=seq(1,38.5,1.5),labels=cog\$ShortName,font.axis=2,tck=-0.01,cex.axis=0.3)
box(lwd=2)
legend("right",legend=paste(cog\$ShortName,cog\$FullName,sep=" : "),xpd=T,inset=-0.8,cex=0.5,box.col="white")


dev.off()
EOF

system "Rscript __$$.R";
unlink "__$$.R";



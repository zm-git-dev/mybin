#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Basename qw /basename/;

=pod

USAGE: plot_venn.pl  [opt]  class1.txt ... class5.txt  

-o --output		default : output.png;

-s --suffix		default :  txt

-m --mode 		can be 0:raw , 1:percent, 2: raw+percent  default : 0

-t --type		default : png

-d --dist		default : 0.07

-h --help 

=cut

my %opts=(
	o => 'output.png',
	s => 'txt',
	t => 'png',
	d => 0.07,
	m => 0,
);
GetOptions(\%opts,
	"o|output=s",
	"s|suffix=s",
	"t|type=s",
	"d|dist=f",
	"m|mode=i",
	"h|help",
);
die `pod2text $0` if(@ARGV<2 or @ARGV>5 or $opts{h} );
my $count=@ARGV;
my @name;
my $name_str;
my $dat_str;
my $mode = $opts{m}==0 ? "'raw'" : $opts{m}==1 ? "'percent'" : $opts{m}==2 ? "c('raw','percent')" : '';
die `pod2text $0` unless $mode;


open OUT,">__$$.R" or die $!;
print OUT <<EOF;
library("gplots")
library("VennDiagram")
par(mar=c(4,4,4,4))
#pdf("$opts{o}")
EOF

for my $i(1 .. $count){
	my $tmp=$ARGV[$i-1];
	my $base=basename($tmp,".$opts{s}");
        print OUT "da$i=read.csv(\"$tmp\",sep=\"\\t\",header=F)\n";
        $dat_str.= $dat_str ? ",da$i\[,1]" : "da$i\[,1]";
	push @name,$base;
}
$name_str =join ",",map{"\"$_\""}@name;

print OUT <<EOF;
mylist <- list($dat_str)
names(mylist) <- c($name_str)
mycol=rainbow($count)
T=venn.diagram(
	mylist,filename="$opts{o}",
	lty=1,lwd=1,
	col='transparent',fill=mycol,cat.col="black",
	cat.dist=$opts{d},
	rotation.degree=0,
	imagetype='$opts{t}',
	print.mode= $mode,
	direct.area=F,
)
#grid.draw(T)
#dev.off()
EOF

system "Rscript __$$.R";

unlink "__$$.R";

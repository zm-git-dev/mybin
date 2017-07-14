#!/usr/bin/perl -w
use strict;
use List::Util qw(max min);
use Getopt::Long;

=pod

USAGE:

alpha_curves.pl    alpha_collated/

-c --cex	[default: 1]

-i --inset	[default: -0.26]

-n --ncol	[default: 1]

-o --output	such as:  1.pdf:2.pdf;...   [required]

-g --group	such as:  10,10:12,14;...   [required]

-s --substitute		substitute "."  in legend  [default: "-"]

-x --xlim_rate		[ default: 1 ]

-m --mar	[default: 9,4,9,7]

-t --type       type 1 : gradient color ;  type 2 : gradient linetype ; default : 1 

-h --help	

EXAMPLE:
 alpha_curves.pl -g 8,8,8:8,8,3:3:8,8,4:8,3  -o test1:test2:test3:test4:test5 alpha_collated/

=cut

#inset -0.23
my %opts=(
	'cex' =>  1 ,
	'inset' => -0.26 ,
	'ncol' => 1 ,
	'substitute' => '-',
	'mar' => '9,4,9,7',
	'type' => 1,
	'x' => 1.0,
);
GetOptions(\%opts,
	"cex=f" ,
	"inset=f",
	"ncol=i" ,
	"help",
	"output=s",
	"group=s" ,
	"substitute=s" ,
	"xlim_rate=f" ,
	"mar=s" ,
	"type=i" ,
);

die `pod2text $0` if(@ARGV !=1 or $opts{h} or !$opts{output} or !$opts{group});

my %ymax;
my $xmax;
my $simpsonmin=1;
my $index=0;
$ARGV[0]=~s/\/$//;
opendir DIR,$ARGV[0] or die $!;
for my $file(readdir DIR){
	next if $file=~ /^\./;
	open IN,"<$ARGV[0]/$file" or die $!;
	$file=~s/\.txt$//;
	while(<IN>){
		chomp;
		next unless $_;
		next if $.==1;
		my $line1=$_;
		s/n\/a/0/g;
		my @F=split /\t/;
		my $M=max(@F[3..$#F]);
		$ymax{$file}=$M if(!$ymax{$file} or $ymax{$file}<$M);
		$xmax=$F[1] if(!$xmax or $xmax <$F[1]);
		if($file eq 'simpson'){
			$line1=~s/n\/a/1/g;
			my @F1=split /\t/,$line1;
			my $m=min(@F1[3..$#F1]);
			$simpsonmin= $m if $simpsonmin >$m;
		}
	}
	close IN;
}
closedir DIR;

$simpsonmin= $simpsonmin>0.9 ? 0.9 : $simpsonmin-0.05;
my $curves;
my $ymax;
for (sort keys %ymax){
	$curves.= $curves ? ",\"$_\"" : "\"$_\"" ;
	$ymax.= $ymax ? ",$ymax{$_}"  : "$ymax{$_}";
}

my @group=split /:/,$opts{group};
my @output=split /:/,$opts{output};
my $size=0;
for my $i(0 .. $#group ){
	my $size0=$size+1;
	for my $j(split /,/,$group[$i]){
		$size+=$j;
	}
	if($opts{type}==1){ 
		&print_R_script1($group[$i],$output[$i],$size0,$size);
	}elsif($opts{type}==2){
		&print_R_script2($group[$i],$output[$i],$size0,$size);
	}else{
		die "unknown type : $opts{type} !\n";
	}
	system "/usr/bin/Rscript __$$.R";
	unlink "__$$.R";
}


sub print_R_script1 {

my ($list,$output,$size0,$size)=@_;
open OUT,">__$$.R" or die $!;
print OUT <<EOF;

pdf('$output.pdf')
par(mar=c($opts{mar}))
curves=c($curves)
ymax=c($ymax)
count=c($list)
legendlty=rep(1,count[1])
legendcol=rainbow(count[1])
if(length(count)>=2){
	for (i in 2:length(count)){
		legendlty=c(legendlty,rep(i,count[i]))
		legendcol=c(legendcol,rainbow(count[i]))
	}
}
for(k in 1:length(curves)){
	ymin=ifelse(curves[k]== "simpson",$simpsonmin,0)
	dat=read.csv(paste('$ARGV[0]/',curves[k],".txt",sep=""),header=T,na.strings='n/a',sep="\t",check.names=F)
	dat=dat[,c(-1,-3)]
	dat=dat[,c(1,($size0+1):($size+1) )]
	head1=colnames(dat)
	head2=head1[-1]
	par(col="black")
	plot(x=dat[,1],y=dat[,2],type="n",main=paste(curves[k],"Curves",sep=" "),xlim=c(0,$xmax*$opts{x}),ylim=c(ymin,ymax[k]*1),xlab="Number of Reads Sampled",ylab=paste(curves[k],"value",sep=" "),cex.main=2 )
	
	for (i in 1:length(count)){
		mycol=rainbow(count[i])
		for (j in 1:count[i]){
			
			par(lty=i,col=mycol[j],lwd=1)
			m=sum(count[1:i])-count[i]+j+1
			myy=dat[,m]
			tmp=predict(loess(myy~dat[,1]),span=100 )
			len=length(tmp)
			myx=dat[,1][1:len]
			lines(myx,tmp)
			#text(x=myx[len],y=tmp[len],labels=head1[m] )
			if(curves[k] != 'simpson' && curves[k] !='goods_coverage'){
				lines(c(0,myx[1]),c(0,tmp[1]),type="l")
			}
		}
	}
	legend("right",gsub("\\\\.","$opts{substitute}",head2,perl=T),lty=legendlty,box.lty=1,text.col=legendcol,col=legendcol,box.col="white",cex=$opts{cex},xpd=T,inset=$opts{inset},ncol=$opts{ncol} )
}
dev.off()

EOF

}



sub print_R_script2 {

my ($list,$output,$size0,$size)=@_;
open OUT,">__$$.R" or die $!;
print OUT <<EOF;

pdf('$output.pdf')
par(mar=c($opts{mar}))
curves=c($curves)
ymax=c($ymax)
count=c($list)
rb=rainbow( length(count) )
legendlty=seq(1,count[1])
legendcol=rep(rb[1], count[1] )
if(length(count)>=2){
	for (i in 2:length(count)){
		legendlty=c(legendlty,seq(1,count[i]) )
		legendcol=c(legendcol,rep(rb[i],count[i]))
	}
}
for(k in 1:length(curves)){
	ymin=ifelse(curves[k]== "simpson",$simpsonmin,0)
	dat=read.csv(paste('$ARGV[0]/',curves[k],".txt",sep=""),header=T,na.strings='n/a',sep="\t",check.names=F)
	dat=dat[,c(-1,-3)]
	dat=dat[,c(1,($size0+1):($size+1) )]
	head1=colnames(dat)
	head2=head1[-1]
	par(col="black")
	plot(x=dat[,1],y=dat[,2],type="n",main=paste(curves[k],"Curves",sep=" "),xlim=c(0,$xmax*$opts{x}),ylim=c(ymin,ymax[k]*1),xlab="Number of Reads Sampled",ylab=paste(curves[k],"value",sep=" "),cex.main=2 )
	
	for (i in 1:length(count)){
		for (j in 1:count[i]){
			
			par(lty=j,col=rb[i],lwd=1)
			m=sum(count[1:i])-count[i]+j+1
			myy=dat[,m]
			tmp=predict(loess(myy~dat[,1]),span=100 )
			len=length(tmp)
			myx=dat[,1][1:len]
			lines(myx,tmp)
			#text(x=myx[len],y=tmp[len],labels=head1[m] )
			if(curves[k] != 'simpson' && curves[k] !='goods_coverage'){
				lines(c(0,myx[1]),c(0,tmp[1]),type="l")
			}
		}
	}
	legend("right",gsub("\\\\.","$opts{substitute}",head2,perl=T),lty=legendlty,box.lty=1,text.col=legendcol,col=legendcol,box.col="white",cex=$opts{cex},xpd=T,inset=$opts{inset},ncol=$opts{ncol} )
}
dev.off()

EOF

}




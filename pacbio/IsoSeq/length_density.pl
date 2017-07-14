#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Basename;
use Data::Dumper;

=pod

	USAGE:
 length_density.pl  [opt]   <fasta_files>

-n --names  <str> 		separate by comma

-p --prefix <str>		default: output

-m --max <int>			default: 15000

-x --xlable <str>		default: Transcript Length

-y --ylable <str>		default: Density

-h --help <boolean>

=cut

my %opts=(
	 p => 'output',
	 m => 15000,
	 x => "Transcript Length",
	 y => "Density",
);
GetOptions(\%opts,
	"h|help",
	"n|names=s",
	"m|max=i",
	"p|prefix=s",
	"x|xlable=s",
	"y|ylable=s",
);

my @split= split /,/,$opts{n} if $opts{n};
die `pod2text $0` if($opts{h} or !@ARGV or $opts{n} && scalar @split != scalar @ARGV );

my @names= $opts{n} ? @split  :  map{my $file=basename $_;$file=~s/\.\w+$//;$file} @ARGV ;

my %hash;
for my $i(0..$#ARGV){
	open IN,"<$ARGV[$i]" or die "no file $ARGV[$i]\n";
	my $fa=0;
	$fa=1 if $ARGV[$i]=~/\.(fa|fasta|fna|fsa)$/;
	local $/="\n>" if $fa;
	while(<IN>){
		my $len;
		if($fa){
			chomp;
			s/^>//;
			my @F=split /\n/,$_,2;
			$F[1]=~s/\n//g;
			$len=length $F[1];
		}else{
			my $line=<IN>;
			chomp $line;
			<IN>;<IN>;
			$len=length $line;
		}
		#$len= int($len/100)*100;
		#$len=$opts{m} if $len >$opts{m};
		$hash{$names[$i]}{$len}++;
	}
	close IN;
}	

open OUT,">$opts{p}.txt" or die $!;
print OUT "Sample\tLength\tValue\n";
for my $s(sort keys %hash){
	for my $l(sort {$a<=>$b}keys %{$hash{$s}}){
		print OUT "$s\t$l\t$hash{$s}{$l}\n";
	}
}
close OUT;

open OUT,">__$$.R" or die $!;
print OUT <<R;
library("ggplot2")
dat <- read.csv("$opts{p}.txt",sep="\t")
p <- ggplot(dat,aes(x=Length,fill=Sample))+
	theme_bw()+
	geom_density(alpha=0.4)+
	theme(legend.position=c(0.8,0.8) )+
	labs(x="$opts{x}",y="$opts{y}",legend="")
	

ggsave("$opts{p}.png")
ggsave("$opts{p}.pdf")

R

system "Rscript __$$.R";
system "rm __$$.R  ";


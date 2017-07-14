#!/usr/bin/perl 
use strict;
use warnings;
use Math::BigFloat;
use Getopt::Long;
#use vars qw($opt_f);

=pod

=head1 USAGE

plot_16S_heatmap.pl [opt]  taxa_summary_plots/

-f --filter		[ default: 0.01 ]

-r --row_cex		[ default: 0.5 ]

-c --col_cex		[ default: 1 ]

-h --help

=over

=back

=cut
my %opts=(
	f => 0.01,
	r => 0.5,
	c => 1,
);
GetOptions(\%opts,
	"f|filter=f",
	"r|row_cex=f",
	"c|col_cex=f",
	"h|help",
);
die `pod2text $0` if($opts{h} or !@ARGV);
my $sample_num;
my $filter_percent=$opts{f};

for my $dir(@ARGV){
$dir=~s/\/$//;
opendir DIR,"$dir/raw_data/" or die $!;
for my $file(readdir DIR ){
	next if($file =~/^\./);
	open IN,"<$dir/raw_data/$file" or die $!;
	$file=~ s/\.txt$/\.csv/;
	open OUT,">$file" or die $!;
	my %hash;
	while(<IN>){
		chomp;
		s/\r//g;
		next if /^# Constructed from biom file/;
		if(/^Taxon/ or /^#OTU/){
			my @arr=split /\t/;
			$sample_num=@arr -1;
			print OUT "$_\n";
			next;
		}else{
			my @array=split /\t/,$_;
			my $class;
			my @arr=split /;/,shift @array;
			while(my $n=pop @arr){
				next if ($n=~ /Other/i);
				next if ($n=~ /unassigned/i);
				next if ($n=~ /\_$/);
				next if ($n=~ /unclassified/i);
				$class=$n;
				last;
			}
			$class="Other" unless($class);
			if(exists $hash{$class}){
				for my $i(0..$sample_num-1){
					my $bf1=Math::BigFloat->new("$hash{$class}->[$i]");
					my $bf2=Math::BigFloat->new("$array[$i]");
					$bf1->badd($bf2);
					$hash{$class}->[$i] = $bf1->bsstr();
				}
			}else{
				$hash{$class}=\@array;
			}
			
		}
	}
	close IN;
	for my $class (sort keys %hash){
		my $flag;
		my $filter=Math::BigFloat->new("$filter_percent");
		for my $n(0..$sample_num-1){
			my $bf=Math::BigFloat->new("$hash{$class}->[$n]");
			$flag=1 if($bf->bcmp($filter) >=0);
		}
		next unless $flag;
		print OUT "$class";
		for my $n(0..$sample_num-1){
			print OUT "\t$hash{$class}[$n]";
		}
		print OUT "\n";
	}
	close OUT;
}
closedir DIR;

}

open OUT,">__$$.R" or die $!;
print OUT <<R;
library(gplots)
ARGV = commandArgs()

name=c("Phylum","Class","Order","Family","Genus","Species")
pdf("heatmap.pdf")

for(i in 6:length(ARGV)){
	da =read.csv(ARGV[i],header=T,sep="\t",check.names=F)
	rownames(da)=da[,1]
	da=da[,-1]
	da=as.matrix(da)
	da_raw=da
	da_log=log2(da+0.00001)
	da = t( scale(t(da),scale=F))
	da_log= t(scale(t(da_log),scale=F))
	heatmap.2(da_raw,Rowv=T,Colv=T,dendrogram='both',col=greenred(75),scale='none',key=T,density.info="none",keysize=1,trace="none",cexRow=$opts{r},cexCol=$opts{c},margins=c(4,7),main=name[i-5] )
	heatmap.2(da_log,Rowv=T,Colv=T,dendrogram='both',col=greenred(75),scale='column',key=T,density.info="none",keysize=1,trace="none",cexRow=$opts{r},cexCol=$opts{c},margins=c(4,7),main=paste(name[i-5],"(scaled)",sep="") )
}

dev.off()
R

system "Rscript __$$.R *.csv";
system "rm __$$.R *.csv ";




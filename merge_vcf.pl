#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw /basename/;
use Getopt::Std;
use Getopt::Long qw /:config no_ignore_case/;
use Data::Dumper;

=pod

=head1 USAGE:

merge_vcf.pl <-p index> <-c index> <-t index>  [OPTION]   <file1.vcf> ... <fileN.vcf>

-l str		: B<List> column index of vcf_file of '-r' row

-r str		:row index [default :1 ]

-p str		:column number of chromosome positon column,containing: "chr,start,[end,]ref,alt"      	[required]

-c str		:column number of changeable column  [required]

-t str		:column number of shared annotation column [required]

-a 		:merge files only if all vcf files have info at that  position

-e		:add Variation_Sample_Count and Variation_Samples to the end of every line

-m		:output multiple files splited by chr  

-o str		:prefix of output files. if -m option is specified, output files are prefix_chrN.txt ,else output file is prefix.txt  [default : merge ]

-s str		:suffix of file name  [default : "_SNP_Indel_ANNO.txt"]

-u		:remove all comma

-v 		:print version info

-M 		:MGCN control

-h		:print this help doc

EXAMPLE:

merge_vcf.pl -l  file1.vcf

merge_vcf.pl   -p 1:4  -c 5:10  -t 11:40  -e   -o merge    file1.vcf file2.vcf file3.vcf  

=cut

my %opts=(
	o => 'merge',
	r => 1,
	s => "_SNP_Indel_ANNO.txt",
);
GetOptions(
	\%opts,
	"p=s",
	"c=s",
	"t=s",
	"r=i",
	"o=s",
	"s=s",
	"l=s",
	"u",
	"v",
	"a",
	"e",
	"h",
	"m",
	"M",
);
if($opts{v}){
	print "\nmerge_vcf.pl  version: 2016-12-05\nmodified at :2016-12-17\n\n";
	exit(0);
}
if($opts{l}){
	open IN,"<$opts{l}" or die $!;
	while(<IN>){
		chomp;
		next unless $. == $opts{r};
		my @F=split /\t/;
		for my $i(0 .. $#F){
			print "",($i+1),"\t$F[$i]\n";
		}
		exit(0);
	}
}
die `pod2text $0` if(!@ARGV or !$opts{p} or !$opts{c} or !$opts{t} or $opts{h});
my %index;

my $MGCN_Control= "/MGCN/Databases/Control/MGCN_Control.vcf2";
my %contrl;
if($opts{M}){
	open IN,"<$MGCN_Control" or die $!;
	while(<IN>){
		chomp;
		next if /^#/;
		next if /^\s*$/;
		my @F=split /\t/;
		$F[-1]=~/MGCN_Control=([\d\.]+)/;
		$contrl{"$F[0],$F[1],$F[3],$F[4]"}=$1;
	}
	close IN;
}

for my $i(keys %opts){
	next unless $i=~/[pct]/;
	for my $n(split /,/,$opts{$i}){
		if($n=~/^\d+$/){
			push @{$index{$i}},$n-1;
		}elsif($n=~/^(\d+)\:(\d+)/){
			for my $k($1 .. $2){
				push @{$index{$i}},$k-1;
			}
		}else{
			print STDERR "index error!\n";
			die `pod2text $0`;
		}
	}
}

my $head;
my $head1;
my %change;
my %unchange;
my @samples;
my $sum_annotation;

for my $file(@ARGV){
	open IN,"<$file" or die $!;
	my $name=basename($file,$opts{s});
	push @samples,$name;
	print STDERR "reading file: $file\n";
	while(<IN>){
		chomp;
		s/\r//g;
		s/,//g if $opts{u};
		#s/\\x2c//g;
		next if /^[\s\.]*$/;
		my @F=split /\t/;
		my (@arr1,@arr2,@arr3,$str1);
		for my $i(0 .. @{$index{p}}-1){
			push @arr1,$F[$index{p}->[$i]] // ".";
		}
		for my $i(0 .. @{$index{c}}-1){
			push @arr2,$F[$index{c}->[$i]] // ".";
		}
		for my $i(0 .. @{$index{t}}-1){
			push @arr3,$F[$index{t}->[$i]] // ".";
		}
		if(/^#/ or $.==1 ){
			if(!$head){
				$head=join "\t",@arr1,(@arr2)x @ARGV,@arr3;
				$head="#$head" unless ($head=~/^#/);
				$head.="\tVariation_Sample_Count\tVariation_Samples" if $opts{e};
				$head.="\tMGCN_Control_AF" if $opts{M};
			}
			$head1="#Position"."\t"x @arr1 unless $head1;
			$head1.="$name"."\t"x @arr2 if($.==1);
			if(!$sum_annotation){
				$sum_annotation=@arr3-1;
				$sum_annotation+=2 if $opts{e};
				$sum_annotation++  if $opts{M};
			}
			next;
		}
		$str1=join "\t",@arr1;
		$change{$str1}{$name}=\@arr2;
		$unchange{$str1}= \@arr3 unless $unchange{$str1};
	}
	close IN;
}

print STDERR "starting merge!\n";
#print "${head1}Annotation\n";
#print "$head\n";
my $CHR;
for my $pos_ref(sort{	
			if($$a[0]=~/\d+/ and $$b[0]=~/\d+/){
				my $n=$&;
				$$a[0]=~/\d+/;
				my $m=$&;
				$m <=> $n or 
				$$a[1] <=> $$b[1] or 
				$$a[-2] cmp $$b[-2] or 
				$$a[-1] cmp $$b[-1];
			}else{
				$$a[0] cmp $$b[0] or
				$$a[1] <=> $$b[1] or
				$$a[-2] cmp $$b[-2] or
				$$a[-1] cmp $$b[-1]; 
			}
	 } map{my @tmp=split /\t/;\@tmp;} keys %change){
	my $pos= join "\t",@{$pos_ref};
	my $chr= $pos_ref->[0];
	if($opts{m}){
		if(!$CHR or $CHR ne $chr){
			my $output= "$opts{o}\_$chr";
			$CHR=$chr;
			open OUT, ">$output.txt" or die $!;
			print OUT "${head1}Annotation"."\t"x$sum_annotation ."\n$head\n";
		}
	}else{
		if(!$CHR){
			open OUT,">$opts{o}.txt" or die $!;
			$CHR=$chr;
			print OUT "${head1}Annotation"."\t"x$sum_annotation ."\n$head\n";
		}
	}
	my (@tmp1);
	my $all_have_flag=1;
	my @variation_sample;
	for my $file(@samples){
		if(exists $change{$pos}{$file}){
			push @variation_sample,$file;
			push @tmp1,@{ $change{$pos}{$file} };
		}else{
			push @tmp1,(".")x scalar @{$index{c}};
			$all_have_flag=0;
		}
	}
	my $s=join "\t",@tmp1,@{$unchange{$pos}};
	$s.= "\t". scalar @variation_sample."\t".(join ",",@variation_sample)  if $opts{e};
	if($opts{M}){
		$s.="\t";
		$s.=  $contrl{"$pos_ref->[0],$pos_ref->[1],$pos_ref->[-2],$pos_ref->[-1]"} // ".";
	}
	print OUT "$pos\t$s\n" if(!$opts{a} or $opts{a} && $all_have_flag);
}

print STDERR "completed!\n";

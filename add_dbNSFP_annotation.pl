#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Basename;
use Data::Dumper;

=pod

USAGE: add_dbNSFP_annotation.pl

-d --db	STR		hg19 or hg38 , default [hg19]

-m --memory INT		default [4] G

-u --multi

=cut

my %opts=(
	d => 'hg19',
	m => 4,
);
GetOptions(\%opts,
	"h|help",
	"d|db=s",
	"m|memory=i",
	"u|multi",
);

die `pod2text $0` if($opts{h} or !@ARGV or $opts{d} !~ /^(hg19|hg38)$/ );
for (@ARGV){
	die `pod2text $0` unless /\.vcf$/ ;
}

my $sample_num = @ARGV;
my $Snpsift = "/MGCN/Tools/snpEff_v4.3g/SnpSift.jar";

my @fields = $opts{d} eq "hg19" ? qw /rs_dbSNP147 1000Gp1_AF 1000Gp1_AFR_AF 1000Gp1_EUR_AF 1000Gp1_AMR_AF 1000Gp1_ASN_AF ESP6500_AA_AF ESP6500_EA_AF SIFT_score SIFT_pred Polyphen2_HDIV_score Polyphen2_HDIV_pred Polyphen2_HVAR_score Polyphen2_HVAR_pred ExAC_AF ExAC_Adj_AF ExAC_AFR_AF ExAC_AMR_AF ExAC_EAS_AF ExAC_FIN_AF ExAC_NFE_AF ExAC_SAS_AF clinvar_rs clinvar_clnsig clinvar_trait clinvar_golden_stars COSMIC_ID COSMIC_CNT/ : qw /./;
my $fields1 = join ",",@fields;
my $fields2 = join " ",@fields;
my $db = $opts{d} eq 'hg19' ? "/MGCN/Databases/dbNSFP2.9.2/dbNSFP2.9.2.vcf.gz" : "/MGCN/Databases/dbNSFP3.2a/build-database/dbNSFP3.2a.chr.txt.gz";

## add dbNSFP annotation and extract fields  ## 

open OUT,">__$$.pl" or die $!;
print OUT <<PL;
use File::Basename;
my \$f = shift \@ARGV;
my \$dir = dirname(\$f);
my \$base = basename(\$f,".vcf");
system "java  -Xmx$opts{m}G  -jar $Snpsift dbNSFP -db $db  -f $fields1 \$f | extract_fields.pl -  > \$base.annot.txt ";

PL


system "my_threads.pl -n $sample_num  'perl __$$.pl ' @ARGV ";
system "rm __$$.pl";

## merge samples ##

my @annot_files = map{ s/vcf$/annot\.txt/;$_ } @ARGV;
my $multi = $opts{u} ? '-m' : '';
system "merge_vcf.pl -p 1:4 -c 5:8   -t 9:49 -e -s '.annot.txt' -$multi  -o merge  @annot_files ";

## add Omim annotation ##

system "my_threads.pl -n $sample_num 'add_OMIM_annotation.pl -p ESP6500_EA_AF ' merge_chr*.txt ";

## convert txt to xlsx ##

system "my_threads.pl -n $sample_num  'txt_to_excel.pl -s tab -r 2  '  merge_chr*.txt";


print STDERR "Complete at ".(localtime)."\n";







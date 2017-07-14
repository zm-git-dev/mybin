#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Data::Dumper;


=pod

USAGE: convert_blast_result.pl   


blast outfmt :  '6 qseqid qlen qstart qend  stitle sseqid  slen  sstart send  bitscore evalue length nident  mismatch  pident positive ppos gapopen gaps  qframe sframe"

-d --database <str>		[ uniprot | GO | KEGG | nr | pfam | eggnog | other ]

-i --input <file>		blast outfmt 6  result file

-o --output <str>		output prefix; suffix is .csv .xlsx

-q --query <file>		query seq fa

-n --no_nohit <boolean>	

-k --kog <boolean>		kog or cog

-h --help <boolean>


=cut

my %opts;
GetOptions(\%opts,
	"d|database=s",
	"h|help",
	"i|input=s",
	"q|query=s",
	"o|output=s",
	"n|no_nohit",
	"k|kog",
);

die `pod2text $0` if($opts{h}  or  !$opts{i} or  !$opts{o} or !$opts{d} );
die "Unknown database : $opts{d} \n" unless $opts{d}=~/^(uniprot|go|kegg|nr|pfam|eggnog|other)$/;
$opts{d}= "\L$opts{d}";

my %db=(
	'uniprot' => "",
	'kegg'    => "/MGCN/Databases/KEGG/annot/all.annot",
	'eggnog'  => "/MGCN/Databases/eggnog/eggnog_4.0beta/all_OG_annotations.tsv",
	'go'      => "",
	'pfam'    => "",
	'nr'      => "",
);

my %var;
my %hash;

open IN,"<$opts{q}" or die $!;
my @query;
my %len;
local $/="\n>";
while(<IN>){
	chomp;
	s/^>//;
	my @F=split /\n/,$_,2;
	my @arr=split /\s+/,$F[0];
	$F[1]=~s/\n//g;
	$len{$arr[0]}=length $F[1];
	push @query,$arr[0];
}
close IN;

local $/="\n";
my $kog_or_cog= $opts{k} ? 'euNOG' : 'NOG';
if( $db{ $opts{d} } ){
	open IN,"<$db{ $opts{d} }" or die $!;
	while(<IN>){
		chomp;
		my @F;
		if($opts{d} eq 'kegg'){
			@F=split /\s+/,$_,2;
			$hash{$F[0]}{description}=$F[1];
		}elsif($opts{d} eq 'eggnog'){
			@F=split /\t/;
			next unless $F[1] eq $kog_or_cog;
			for my $id(split /,/,$F[8]){
				$hash{$id}{source}= $F[0]=~/^(C|K)OG/ ? $F[0] : "ENOG41$F[0]";
				$hash{$id}{categories}= $F[4]=~/\[u'(\w+)'\]/ ? $1 : ''; 
				$hash{$id}{annotation}= $F[3];
			}
		}
	}
	close IN;
}


if($opts{d} eq 'uniprot' or $opts{d} eq 'kegg' or $opts{d} eq 'nr'){
	$var{head}="Query\t\t\t\t\tSubject\t\t\t\t\t\tScore\t\tIdentities\t\tPositives\t\tGaps\t\tFrame\nName\tLength\tStart\tEnd\tCoverage\tDescription\tAccession\tLength\tStart\tEnd\tCoverage\tBit\tE-value\tMatch/Total\tPct.(%)\tMatch/Total\tPct.(%)\tMatch/Total\tPct.(%)\tQuery";
}elsif($opts{d} eq 'eggnog'){
	$var{head}="Query\t\t\t\t\tSubject\t\t\t\t\t\t\t\tScore\t\tIdentities\t\tPositives\t\tGaps\t\tFrame\nName\tLength\tStart\tEnd\tCoverage\tDescription\tRep.Source_ID\tRep.Categories\tRep.Annotation\tLength\tStart\tEnd\tCoverage\tBit\tE-value\tMatch/Total\tPct.(%)\tMatch/Total\tPct.(%)\tMatch/Total\tPct.(%)\tQuery";
}else{
	$var{head}="Query\t\t\t\t\tSubject\t\t\t\t\tScore\t\tIdentities\t\tPositives\t\tGaps\t\tFrame\nName\tLength\tStart\tEnd\tCoverage\tDescription\tLength\tStart\tEnd\tCoverage\tBit\tE-value\tMatch/Total\tPct.(%)\tMatch/Total\tPct.(%)\tMatch/Total\tPct.(%)\tQuery";

}

if($opts{i}){
	open IN,"<$opts{i}" or die $!;
	open OUT,">$opts{o}.csv" or die $!;
	print OUT "$var{head}\n";
	my ($query,$str,$score,$evalue)=('');
	my $n=0;
	while(<IN>){
		chomp;
		next if /^\s*$/;
		my @F=split /\t/;
		$var{query_name}=$F[0];
		#my $len=$len{ $var{query_name} };
		LABEL:
		my $len=$len{ ($query[$n] // 0 )  } ;
		my $name=$query[$n] || '';		
#		print OUT "$n\t$name\t$var{query_name}\t$query\n";
		if( !$query && $name ne $var{query_name} or  $query &&  $name ne $var{query_name} && $query[$n-1] ne $var{query_name} ){
			print OUT "$name\t$len\t\t\t\tNo hit\n" unless $opts{n};
			$n++;
			goto LABEL;
		}

		$var{query_length}=$F[1];
		$var{query_start}=$F[2] ;
		$var{query_end}=$F[3];
		$var{identity_length}=$F[11];
		$var{query_coverage}= sprintf("%.2f",100*abs($var{query_end}-$var{query_start}+1)/$var{query_length});
		$var{subject_accession}=$F[5];
		$var{subject_description}=$F[4];
		$var{subject_start}=$F[7];
		$var{subject_end}=$F[8];
		$var{subject_length}=$F[6];
		$var{subject_coverage}=sprintf("%.2f",100*abs($var{subject_end}-$var{subject_start}+1)/$var{subject_length});
		$var{score_bit}=$F[9];
		next if ($query and $query eq $var{query_name} and $score > $var{score_bit} );
		$var{score_evalue}=$F[10];
		$var{match}=$F[12];
		$var{mismatch}=$F[13];
		$var{identity_match_total}=sprintf("%i/%i",$var{match},$var{identity_length});
		$var{identity_percent}=$F[14];
		$var{positive_match_total}=sprintf("%i/%i",$F[15],$var{identity_length});
		$var{positive_percent}=$F[16];
		$var{gaps}=$F[18];
		$var{gaps_match_total}=sprintf("%i/%i",$var{gaps},$var{identity_length});
		$var{gaps_percent}=sprintf("%.2f",100*$var{gaps}/$var{identity_length});
		$var{frame_query}=$F[19];
		my $tmp;
		if($opts{d} eq 'kegg' ){
			$var{subject_description}= $hash{$var{subject_accession}}{description};
			$tmp = "$var{query_name}\t$var{query_length}\t$var{query_start}\t$var{query_end}\t$var{query_coverage}\t$var{subject_description}\t$var{subject_accession}\t$var{subject_length}\t$var{subject_start}\t$var{subject_end}\t$var{subject_coverage}\t$var{score_bit}\t$var{score_evalue}\t$var{identity_match_total}\t$var{identity_percent}\t$var{positive_match_total}\t$var{positive_percent}\t$var{gaps_match_total}\t$var{gaps_percent}\t$var{frame_query}\n" ;
		}elsif($opts{d} eq 'eggnog'){
			$var{subject_description}= $var{subject_accession};
			$var{subject_source}     = $hash{$var{subject_accession}}{source} || '';
			$var{subject_categories} = $hash{$var{subject_accession}}{categories} || '';
			$var{subject_annotation} = $hash{$var{subject_accession}}{annotation} || '';
			$tmp = "$var{query_name}\t$var{query_length}\t$var{query_start}\t$var{query_end}\t$var{query_coverage}\t$var{subject_description}\t$var{subject_source}\t$var{subject_categories}\t$var{subject_annotation}\t$var{subject_length}\t$var{subject_start}\t$var{subject_end}\t$var{subject_coverage}\t$var{score_bit}\t$var{score_evalue}\t$var{identity_match_total}\t$var{identity_percent}\t$var{positive_match_total}\t$var{positive_percent}\t$var{gaps_match_total}\t$var{gaps_percent}\t$var{frame_query}\n" ;
		}elsif($opts{d} eq 'nr' or $opts{d} eq 'uniprot'){
			my @arr=split /\s+/,$F[4],2;
			$var{subject_description}=$arr[1];
			$var{subject_accession}=$arr[0];
			$tmp = "$var{query_name}\t$var{query_length}\t$var{query_start}\t$var{query_end}\t$var{query_coverage}\t$var{subject_description}\t$var{subject_accession}\t$var{subject_length}\t$var{subject_start}\t$var{subject_end}\t$var{subject_coverage}\t$var{score_bit}\t$var{score_evalue}\t$var{identity_match_total}\t$var{identity_percent}\t$var{positive_match_total}\t$var{positive_percent}\t$var{gaps_match_total}\t$var{gaps_percent}\t$var{frame_query}\n" ;
		}else{
			$tmp = "$var{query_name}\t$var{query_length}\t$var{query_start}\t$var{query_end}\t$var{query_coverage}\t$var{subject_description}\t$var{subject_length}\t$var{subject_start}\t$var{subject_end}\t$var{subject_coverage}\t$var{score_bit}\t$var{score_evalue}\t$var{identity_match_total}\t$var{identity_percent}\t$var{positive_match_total}\t$var{positive_percent}\t$var{gaps_match_total}\t$var{gaps_percent}\t$var{frame_query}\n" ;
	
		}
		
		if( $query and $query eq $var{query_name}){
			if($score < $var{score_bit}){
				$score=$var{score_bit};
				$str=$tmp;
			}else{
				next;
			}
		}else{
			$query = $var{query_name};
			$score = $var{score_bit};
			print OUT "$str" if $str;
			$n++;
			$str=$tmp;
		}
	}
	print OUT "$str";
	close IN;
	close OUT;
}

#system "txt_to_excel.pl -s tab -r 2 $opts{o}.csv -W 4  ";

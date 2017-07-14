#!/usr/bin/perl -w
use strict;
use List::Util qw /sum/;

=pod 

USAGE: classify_novel_gene.pl  < ref_gff > < bam_file > < seq_fa >  < output_prefix >

=cut

die `pod2text $0 ` unless @ARGV==4;


open IN,"<$ARGV[0]" or die $!;
my $gtf=  $ARGV[0]=~/gtf$/ ? 'gtf' : $ARGV[0]=~/gff\d?$/ ? 'gff' : 'unknown';
my (%ref_gff,$ref_gene,$ref_isoform,%gene);
my $exon=1;
while(<IN>){
	chomp;
	next if /^#/;
	my @F=split /\t/;
	my ($id ,$parent );
	if( $gtf eq 'gff' ){
		if($F[2] eq 'mRNA'){
			($ref_isoform) = $F[-1]=~/ID=([^;]+)/;
			($ref_gene)= $F[-1] =~/Parent=([^;]+)/;
			$exon=1;
			next;
		}elsif($F[2] eq 'exon'){
			$id=$ref_isoform;
			$parent=$ref_gene;
		}elsif($F[2] eq 'gene'){
			my ($g)= $F[-1]=~/ID=([^;]+)/;
			$gene{$F[0]}{$g}{start}=$F[3];
			$gene{$F[0]}{$g}{end}=$F[4];
			next;
		}else{
			next;
		}
	}elsif($gtf eq  'gtf' ){
		next unless $F[2] eq 'exon';
		($id)= $F[-1]=~/transcript_id \"([^"]+\")/;
		($parent)= $F[-1]=~/gene_id \"([^"]+)\"/;
	}else{
		die "can not recognise gtf or gff file : $ARGV[0] ! \n";
	}
	$ref_gff{ $F[0] }{ $parent }{ $id }{start}{ $F[3] }{ $exon }++;
	$ref_gff{ $F[0] }{ $parent }{ $id }{end}{ $F[4] }{ $exon }++;
	$ref_gff{ $F[0] }{ $parent }{ $id }{exon}{ $exon }++;
	$ref_gff{ $F[0] }{ $parent }{ $id }{strand}=$F[6];
	$exon++;
}
close IN;


my %flag=(
	0 => 'Cross_multi_gene',
	1 => 'Same',
	2 => 'Patial',
	3 => 'Novel_Isoforms',
	4 => 'Overlap',
	5 => 'Exon_In_Intron',
	7 => 'Overlap_Opposite',
	8 => 'Novel_Gene',
	9 => 'Exclusive',
);

my (%bed,%pos,%map,%annot);
system "bedtools  bamtobed  -split  -i $ARGV[1] >$ARGV[1].bed";
open IN,"<$ARGV[1].bed" or die $!;
while(<IN>){
	chomp;
	my @F=split /\t/;
	$pos{$F[0]}{$F[3]}{$F[1]+1}=$F[2];
	$bed{$F[0]}{$F[3]}{strand}=$F[5];
	$bed{$F[0]}{$F[3]}{min}=$F[1]+1 if (!$bed{$F[0]}{$F[3]}{min} or $bed{$F[0]}{$F[3]}{min} > $F[1]+1);
	$bed{$F[0]}{$F[3]}{max}=$F[2] if (!$bed{$F[0]}{$F[3]}{max} or $bed{$F[0]}{$F[3]}{max} < $F[2]) ;
}
close IN;

my $tmp=0;
for my $chr(sort keys %bed){
	my @genes= sort {   $gene{$chr}{$a}{start} <=> $gene{$chr}{$b}{start} } keys %{$gene{$chr}};
	for my $seq(keys %{$bed{$chr}}){
		my $min=$bed{$chr}{$seq}{min};
		my $max=$bed{$chr}{$seq}{max};
		my $strand=$bed{$chr}{$seq}{strand};
		my $exon_num= keys %{$pos{$chr}{$seq}};
		$map{$seq}={
			type => 8,
			gene => '.',
			transcript => '.',
			desc => $flag{8},
		};
		my %num;
		for my $gene( @genes){
			my $gene_min= $gene{$chr}{$gene}{start};
			my $gene_max= $gene{$chr}{$gene}{end};
			next if ($gene_max < $min);
			last if ($gene_min > $max);
			my $n=0;
			for my $start(sort {$a<=>$b}keys %{$pos{$chr}{$seq} }){
				$n++;
				my $end=$pos{$chr}{$seq}{$start};
				for my $t(keys %{$ref_gff{$chr}{$gene}} ){
					if( $ref_gff{$chr}{$gene}{$t}{start}{$start}  &&  $ref_gff{$chr}{$gene}{$t}{end}{$end} or $exon_num >1 && $n==1 && $ref_gff{$chr}{$gene}{$t}{end}{$end}  or  $exon_num>1 && $n==$exon_num && $ref_gff{$chr}{$gene}{$t}{start}{$start}  ){
							$num{$gene}{$t}++;
					}
				}
			}
		}
		if(0 ){

		}else{
			LABEL:
			for my $gene(keys %num){
				for my $t(keys %{$num{$gene}}){
					my $ref_num= keys %{$ref_gff{$chr}{$gene}{$t}{exon}};
					if( $exon_num == $num{$gene}{$t} and $strand eq $ref_gff{$chr}{$gene}{$t}{strand} ){
						if($exon_num == $ref_num){
							$map{$seq}={
								type => 1,
								gene => $gene,
								transcript => $t,
								desc => $flag{1},
							};
							last LABEL;
						}else{
							$map{$seq}={
								type => 2,
								gene => $gene,
								transcript => $t,
								desc => $flag{2},
							}
						}
					}elsif($num{$gene}{$t} >0 and $strand eq $ref_gff{$chr}{$gene}{$t}{strand} and $map{$seq}{type}>3 ){
						$map{$seq}={
							type => 3,
							gene => $gene,
							transcript => '.',
							desc => $flag{3},
						}
					}else{
						my @s1= sort {$a<=>$b}keys %{$pos{$chr}{$seq}};
						my @e1= sort {$a<=>$b} values %{$pos{$chr}{$seq}};
						my @s2= sort {$a<=>$b} keys %{$ref_gff{$chr}{$gene}{$t}{start}};
						my @e2= sort {$a<=>$b} keys %{$ref_gff{$chr}{$gene}{$t}{end}};
						my $overlap = &overlap(\@s1,\@e1,\@s2,\@e2,$strand,$ref_gff{$chr}{$gene}{$t}{strand});
						if($overlap < $map{$seq}{type}){
							$map{$seq}={
								type => $overlap ,
								gene => $gene,
								transcript => '.',
								desc => $flag{$overlap},
							};
						}
					}
				}
			}
		}
	}
}
close IN;

open IN,"<$ARGV[2]" or die $!;
local $/="\n>";
my %seq;
while(<IN>){
	chomp;
	s/^>//;
	my @F=split /\n/,$_,2;
	$seq{$F[0]}=$F[1];
}
close IN;
local $/="\n";

system "samtools view -f 4 $ARGV[1] | cut -f 1 >$ARGV[1].tmp";
open OUT1,">$ARGV[3].txt" or die $!;
print OUT1 "#SeqID\tRef_Gene\tRef_Transcript\tType\tSequence\n";
open OUT2,">$ARGV[3].stat" or die $!;
print OUT2"Type\tCount\tPercent(%)\n";

my %stat;
my $total=0;
for my $seq(keys %map){
	my $type=$map{$seq}{type};
	$stat{$type}++;
	$total++;
	print OUT1 "$seq\t$map{$seq}{gene}\t$map{$seq}{transcript}\t$map{$seq}{desc}\t$seq{$seq}\n";
}

open IN,"$ARGV[1].tmp" or die $!;
while(<IN>){
	chomp;
	print OUT1 "$_\t.\t.\tExclusive\t$seq{$_}\n";
	$total++;
	$stat{9}++;
}
close IN;
unlink "$ARGV[1].tmp";
close OUT1;

for my $type(sort {$a<=>$b}keys %flag){
	$stat{$type}=0 unless $stat{$type};
	printf OUT2 "%s\t%d\t%.2f\n",$flag{$type},$stat{$type},100*$stat{$type}/$total;
}
close OUT2;

system "perl /home/yangchao/mybin/pacbio/IsoSeq/plot_pie3D.pl $ARGV[3].stat  $ARGV[3].pdf ";


sub overlap{
	my ($s1,$e1,$s2,$e2,$strand1,$strand2)=@_;
	for my $i(0 .. $#$s1){
		for my $j(0 .. $#$s2){
			if($s1->[$i] < $e2->[$j]  and $e1->[$i] > $s2->[$j] ){
				return 4 if($strand1 eq $strand2);
				return 7 if($strand1 ne $strand2);
			}
		}
	}
	return 5;
}






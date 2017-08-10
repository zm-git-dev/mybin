#!/usr/bin/perl -w
use strict;

print "CHROM\tPOS\tREF\tALT\tHom/Het\tDP\tAD\tQUAL\tFILTER\tEffect\tEffect_Impact\tFunctional_Class\tCodon_Change\tAmino_Acid_Change\tAmino_Acid_length\tGene_Name\tTranscript_BioType\tGene_Coding\tTranscript_ID\tExon\tGenotypeNum\trs_dbSNP147\t1000Gp1_AF\t1000Gp1_AFR_AF\t1000Gp1_EUR_AF\t1000Gp1_AMR_AF\t1000Gp1_ASN_AF\tESP6500_AA_AF\tESP6500_EA_AF\tSIFT_score\tSIFT_pred\tPolyphen2_HDIV_score\tPolyphen2_HDIV_pred\tPolyphen2_HVAR_score\tPolyphen2_HVAR_pred\tExAC_AF\tExAC_Adj_AF\tExAC_AFR_AF\tExAC_AMR_AF\tExAC_EAS_AF\tExAC_FIN_AF\tExAC_NFE_AF\tExAC_SAS_AF\tclinvar_rs\tclinvar_clnsig\tclinvar_trait\tclinvar_golden_stars\tCOSMIC_ID\tCOSMIC_CNT\n";

my @dbNSFP = qw /rs_dbSNP147 1000Gp1_AF 1000Gp1_AFR_AF 1000Gp1_EUR_AF 1000Gp1_AMR_AF 1000Gp1_ASN_AF ESP6500_AA_AF ESP6500_EA_AF SIFT_score SIFT_pred Polyphen2_HDIV_score Polyphen2_HDIV_pred Polyphen2_HVAR_score Polyphen2_HVAR_pred ExAC_AF ExAC_Adj_AF ExAC_AFR_AF ExAC_AMR_AF ExAC_EAS_AF ExAC_FIN_AF ExAC_NFE_AF ExAC_SAS_AF clinvar_rs clinvar_clnsig clinvar_trait clinvar_golden_stars COSMIC_ID COSMIC_CNT/;

while(<>){
	next if /^#/;
	chomp;
	my @F=split /\t/;
	next if length $F[3] >1 ;
	next if length ( ( split /,/,$F[4])[0] ) > 1;
	my @dp = split /\:/,$F[9];
	$dp[0] = $dp[0] eq '0/1' ? 'Het' : 'Hom';
	my @ad = split /,/,$dp[-1];
	my $ad = $ad[0]+$ad[1];
	my @info = split /;/,$F[7];
	my %hash;
	my @eff= ('.') x 13;
	for my $info(@info){
		my ($key,$value)=split /\=/,$info;
		if($key eq 'EFF'){
			@eff = split /[\(\|\)]/,$value,13;
			@eff = map{ $_ || '.' } @eff;
		}else{
			$hash{$key} = $value;
		}
	}
	my @list = map{ $hash{"dbNSFP_$_"} || '.'} @dbNSFP;
	my $out = join "\t",$F[0],$F[1],@F[3..4],$dp[0],$ad,$dp[-1],@F[5..6],@eff[0..11],@list;
	print "$out\n";
}

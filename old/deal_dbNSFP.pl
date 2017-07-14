#!/usr/bin/perl
use strict;
use warnings;

=pod

 deal_dbNSFP.pl  dbNSFP_out.txt input_file >output.txt

=cut

die `pod2text $0` unless (@ARGV==2);
open IN,"<$ARGV[0]" or die $!;
my %hash;
my $head;
my $table_head="chr\tpos(1-coor)\tref\talt\taaref\taaalt\thg18_pos(1-coor)\tgenename\tUniprot_acc\tUniprot_id\tUniprot_aapos\tInterpro_domain\tcds_strand\trefcodon\tSLR_test_statistic\tcodonpos\tfold-degenerate\tAncestral_allele\tEnsembl_geneid\tEnsembl_transcriptid\taapos\tSIFT_score\tPolyphen2_HDIV_score\tPolyphen2_HDIV_pred\tPolyphen2_HVAR_score\tPolyphen2_HVAR_pred\tLRT_score\tLRT_pred\tMutationTaster_score\tMutationTaster_pred\tMutationAssessor_score\tMutationAssessor_pred\tFATHMM_score\tGERP++_NR\tGERP++_RS\tphyloP\t29way_pi\t29way_logOdds\tLRT_Omega\tUniSNP_ids\t1000Gp1_AC\t1000Gp1_AF\t1000Gp1_AFR_AC\t1000Gp1_AFR_AF\t1000Gp1_EUR_AC\t1000Gp1_EUR_AF\t1000Gp1_AMR_AC\t1000Gp1_AMR_AF\t1000Gp1_ASN_AC\t1000Gp1_ASN_AF\tESP6500_AA_AF\tESP6500_EA_AF\tGene_old_names\tGene_other_names\tUniprot_acc(HGNC/Uniprot)\tUniprot_id(HGNC/Uniprot)\tEntrez_gene_id\tCCDS_id\tRefseq_id\tucsc_id\tMIM_id\tGene_full_name\tPathway\tFunction_description\tDisease_description\tMIM_phenotype_id\tMIM_disease\tTrait_association(GWAS)\tExpression(egenetics)\tExpression(GNF/Atlas)\tInteractions(IntAct)\tInteractions(BioGRID)\tP(HI)\tP(rec)\tKnown_rec_info";
while(<IN>){
	chomp;
	s/\r//g;
	if(/^#/){
		s/^#//;
		s/\s+/\t/g;
		$head=$_;
		next;
	}
	my @F=split /\t/,$_,3;
	$hash{$F[0]}{$F[1]}=$_;
}
close IN;
open IN,"<$ARGV[1]" or die $!;
while(<IN>){
	chomp;
	s/\r//g;
	if(/^#/){
		print "$_\t$head\n";
		next;
	}
	my @F=split /\t/,$_,3;
	$F[0]=~s/^chr0?//;
	$F[1]=~s/\,//g;
	print "$_";
	if(exists $hash{$F[0]}{$F[1]}){
		print "\t$hash{$F[0]}{$F[1]}\n";
	}else{
		print "\t."x 121,"\n";
	}
}
close IN;

#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Thread;

=pod

USAGE:

analysis_rna_seq_by_trinity.pl -p prefix -s sample.txt -l <left_reads_1[,left_reads_2...]> -r <right_reads_1[,right_reads_2...]

-p --prefix string:	output_prefix used for align_and_estimate_abundance.pl , should be separated by commas and sorted by the order of reads,like: 0d,2d,4d,7d [required]

-s --samples string:	samples,tab-delimited text file indicating biological replicate relationships [required if contain replicate samples]

-l --left string arrays:	read 1 files [required]

-r --right string arrays:	read 2 files [required]

-k --kobas :  kobas species

-h --help:	print this doc

EXAMPLE:

analysis_rna_seq_by_trinity.pl -p 0d,2d,4d,7d  -s samples.txt -k pxb -l 0d_1.fastq 2d_1.fastq 4d_1.fastq 7d_1.fastq -r 0d_2.fastq 2d_2.fastq 4d_2.fastq 7d_2.fastq

=cut

my %opts;
my @left_reads;
my @right_reads;
my (@left,@right,@samples);
my @th;
my @prefix;

&examine_par;
#&qc;
&analysis;




sub examine_par{
	GetOptions(
		"p|prefix=s" => \$opts{p},
		"s|sample=s{0,}" => \@samples,
		"h|help=s" => \$opts{h},
		"l|left=s{1,}" => \@left_reads,
		"r|right=s{1,}" => \@right_reads,
		"k|kobas=s" => \$opts{k},
	);
#	getopts('p:s:h',\%opts);
	die `pod2text $0` if($opts{h}  or !$opts{p} or !@left_reads or !@right_reads);
	for my $file(@left_reads,@right_reads){
		unless(-e $file){
			die "cannot find \"$file\",please examine your input files!\n";
		}
	}
	die "left_reads number and right_reads number must be equal!\n" unless(@left_reads == @right_reads);
	@prefix=split /\,/,$opts{p};
	if(@prefix != @left_reads){
		die "prefix number must be equal to reads!\n";
	}
	@left=map{"IlluQC_Filtered_files/$_\_filtered"} @left_reads;
	@right=map{"IlluQC_Filtered_files/$_\_filtered"} @right_reads;
}

sub qc{
	for (0 .. $#left_reads){
		$th[$_]=Thread->new(sub{my $i=shift;system " IlluQC.pl -pe $left_reads[$i] $right_reads[$i] 2 5 -l 90 -p 4 -o IlluQC_Filtered_files"},$_);
	}
	for (@th){	
		$_->join();
	}
	
#	mkdir "fastqc_output" or die $! unless(-e "fastqc_output/") ;
#	system "fastqc -o fastqc_output --nogroup -t 20 @left_reads @right_reads @left @right";
}
sub analysis{
	system " Trinity --seqType fq --JM 100G --left @left --right @right --CPU 30 --output trinity_assem/";
	system "mv trinity_assem/Trinity.fasta trinity_assem/old.Trinity.fasta";
	system "cd-hit -T 30 -i trinity_assem/old.Trinity.fasta -o trinity_assem/Trinity.fasta -g 0 -M 0";
	my $t1=Thread->new(\&trinity);
	my $t2=Thread->new(\&trinotate);
	my $t3=Thread->new(sub{ system "blastx -query trinity_assem/Trinity.fasta -db /MGCN/Databases/Uniprot/uniprot_sprot.fasta -out fulllength_blastx.outfmt6 -evalue 1e-20 -num_threads 16 -max_target_seqs 1 -outfmt 6";
				system "perl /MGCN/Tools/trinityrnaseq_r20140717/util/analyze_blastPlus_topHit_coverage.pl fulllength_blastx.outfmt6 trinity_assem/Trinity.fasta /usr/local/share/databases/uniprot/uniprot_sprot.fasta";
	});
	$t1->join();
	$t2->join();
	system "cat RSEM/$prefix[0].genes.results | cut -f 1,3 > genes.lengths.txt";
	system "cat RSEM/$prefix[0].isoforms.results | cut -f 1,3 > isoforms.lengths.txt";
	system "extract_GO_assignments_from_Trinotate_xls.pl --Trinotate_xls trinotate_annotation_report.xls -G --include_ancestral_terms > go_annotations.txt";
	system "extract_GO_assignments_from_Trinotate_xls.pl --Trinotate_xls trinotate_annotation_report.xls -T --include_ancestral_terms > go_annotations_trans.txt";
	
	for my $sa(@samples){
		my $suffix='';
		if($sa=~/(_of.*)\.txt$/){
			$suffix=$1;
		}
		chdir "DE_gene$suffix";
		system "analyze_diff_expr.pl --matrix ../genes.TMM.fpkm.matrix -P 1e-3 -C 2 --examine_GO_enrichment --GO_annots ../go_annotations.txt --gene_lengths ../genes.lengths.txt --samples ../$sa ";
		chdir "../DE_isoform";
		system "analyze_diff_expr.pl --matrix ../isoforms.TMM.fpkm.matrix -P 1e-3 -C 2 --examine_GO_enrichment --GO_annots ../go_annotations_trans.txt --gene_lengths ../isoforms.lengths.txt --samples ../$sa";
		chdir "../";
	}
	unless(@samples){
		chdir "DE_gene";
		system "analyze_diff_expr.pl --matrix ../genes.TMM.fpkm.matrix -P 1e-3 -C 2 --examine_GO_enrichment --GO_annots ../go_annotations.txt --gene_lengths ../genes.lengths.txt  ";
		chdir "../DE_isoform";
		system "analyze_diff_expr.pl --matrix ../isoforms.TMM.fpkm.matrix -P 1e-3 -C 2 --examine_GO_enrichment --GO_annots ../go_annotations_trans.txt --gene_lengths ../isoforms.lengths.txt ";
		chdir "../";
	}

	$t3->join();
	mkdir "length_distribution" or die $! unless -e "length_distribution";
	chdir "length_distribution";
	system "Trinity_length_distribution.pl ../trinity_assem/Trinity.fasta ../Trinity.fasta.transdecoder.pep";
	system "Rscript /home/yangchao/mybin/Trinity_length_distribution.R ./ ";
	chdir "../";
	system "get_diff_exp_gene_seq_from_trinity.pl kobas_out trinity_assem/Trinity.fasta DE_gene*/*.subset ";
	system "kobas.pl -k $opts{k} -a trinotate_annotation_report.xls kobas_out/*.fa";
}


sub get_report{
	system "cp /usr/local/share/databases/Trinotate.sqlite .";
	#system "get_Trinity_gene_to_trans_map.pl trinity_assem/Trinity.fasta > Trinity.fasta.gene_trans_map";
	system "Trinotate Trinotate.sqlite init --gene_trans_map trinity_assem/Trinity.fasta.gene_trans_map --transcript_fasta trinity_assem/Trinity.fasta --transdecoder_pep Trinity.fasta.transdecoder.pep";
	system "Trinotate Trinotate.sqlite LOAD_blastp blastp.outfmt6";
	system "Trinotate Trinotate.sqlite LOAD_blastx blastx.outfmt6";
	system "Trinotate Trinotate.sqlite LOAD_pfam TrinotatePFAM.out";
	system "Trinotate Trinotate.sqlite LOAD_tmhmm tmhmm.out";
	system "Trinotate Trinotate.sqlite LOAD_signalp signalp.out";
	system "Trinotate Trinotate.sqlite LOAD_rnammer Trinotate.fasta.rnammer.gff";
	system "Trinotate Trinotate.sqlite report > trinotate_annotation_report.xls";
}

sub trinity{
	system "TrinityStats.pl trinity_assem/Trinity.fasta >contig.stat";
	system "align_and_estimate_abundance.pl --transcripts trinity_assem/Trinity.fasta --seqType fq --left $left[0] --right $right[0] --est_method RSEM --aln_method bowtie2 --thread_count 8 --output_dir RSEM --trinity_mode --output_prefix $prefix[0] --prep_reference";
	for my $i(1.. $#left){
		system "align_and_estimate_abundance.pl --transcripts trinity_assem/Trinity.fasta --seqType fq --left $left[$i] --right $right[$i] --est_method RSEM --aln_method bowtie2 --thread_count 8 --output_dir RSEM --trinity_mode --output_prefix $prefix[$i] ";
	}
	system "abundance_estimates_to_matrix.pl --est_method RSEM  --out_prefix genes RSEM/*.genes.results";
	system "abundance_estimates_to_matrix.pl --est_method RSEM  --out_prefix isoforms RSEM/*.isoforms.results";
	if(@samples){
		my @T;
		for my $i(0 .. $#samples){
			my $suffix='';
			if( $samples[$i]=~ /(_of_.*)\.txt$/ ){
				$suffix=$1;
			}
			$T[$i]= Thread->new(sub {
				system "run_DE_analysis.pl --matrix genes.counts.matrix --method edgeR --output DE_gene$suffix --samples $samples[$i]" ;
				system "run_DE_analysis.pl --matrix isoforms.counts.matrix --method edgeR --output DE_isoform$suffix --samples $samples[$i]" ;
			});
		}
		for (@T){
			$_->join();
		}
	}else{
		system "run_DE_analysis.pl --matrix genes.counts.matrix --method edgeR --output DE_gene";
		system "run_DE_analysis.pl --matrix isoforms.counts.matrix --method edgeR --output DE_isoform";
	}
}
sub trinotate{
	system "TransDecoder -t trinity_assem/Trinity.fasta --CPU 16";
	@th=();
	$th[0]=Thread->new(sub{system "blastx -query trinity_assem/Trinity.fasta -db /usr/local/share/databases/uniprot/uniprot_sprot.fasta -num_threads 16 -max_target_seqs 1 -outfmt 6 -out blastx.outfmt6"});
	$th[1]=Thread->new(sub{system "blastp -query Trinity.fasta.transdecoder.pep -db /usr/local/share/databases/uniprot/uniprot_sprot.fasta -num_threads 6 -max_target_seqs 1 -outfmt 6 -out blastp.outfmt6"});
	$th[2]=Thread->new(sub{system "hmmscan --cpu 8 --domtblout TrinotatePFAM.out /usr/local/share/databases/Pfam-A/Pfam-A.hmm Trinity.fasta.transdecoder.pep >pfam.log"});
	$th[3]=Thread->new(sub{system "signalp -f short -n signalp.out Trinity.fasta.transdecoder.pep"});
	$th[4]=Thread->new(sub{system "tmhmm --short Trinity.fasta.transdecoder.pep >tmhmm.out"});
	$th[5]=Thread->new(sub{system "RnammerTranscriptome.pl --transcriptome trinity_assem/Trinity.fasta"});
	for (@th){
		$_->join();
	}
	&get_report;
}




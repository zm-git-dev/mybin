#!/usr/bin/perl -w
use strict;
use Getopt::Long qw /:config no_ignore_case/;
use File::Basename qw/basename dirname/;

=pod 

USAGE: analyse_16S.pl

opts:

-e --extract

-o --otu_pick

-a --alpha

-b --beta

-v --venn

-u --upload

-m --map

-f --full_length

-t --type			gradient 1:color ; 2: linetype [ default : 2 ]

-x --max_mismatch_density		[ default: 0.1 ]

-O --jobs				[ deault: 20 ]

-l --library		paired end fastq file, separated by blank [ required if option -e is specified ]

-p --par_file

-g --angel				0 or 45  [ default : 0 ]

-d --display				[ required if option o,a,e is speciefied ]

-I --ITS	

-h --help

=cut

my %opts=(
	x => 0.1,
	O => 20,
	t => 2,
	g => 0,
);

my (@fq,@display);
GetOptions(\%opts,
	"a|alpha",
	"m|map=s",
	"e|extract",
	"b|beta",
	"v|venn",
	"u|upload",
	"f|full_length",
	"group=s",
	"g|angle=i",
	"alpha_out=s",
	"t|type=i{1,2}",
	"x|max_mismatch_density=f",
	"o|otu_pick",
	"O|jobs=i",
	"p|par_file=s",
	"l|library=s{2}" => \@fq ,
	"d|display=s{1,}" => \@display,
	"I|ITS",
	"h|help",
);
die `pod2text $0` if($opts{h} or (!@display and !$opts{e}) );
$opts{p} = $opts{I} ? "/home/yangchao/16S/qiime_ITS_par.txt" : "/home/yangchao/16S/qiime_16S_par.txt"  unless $opts{p};

&extract if $opts{e};

my @pid;
if(@display){
	for my $i( 0 .. $#display ){
		my $display=$display[$i];
		$pid[$i]=fork;
		if($pid[$i]==0){
			my $base=basename($display,".txt");
			open IN,"<$display" or die $!;
			<IN>;
			my ($group,%groups,@groups,@samples);
			while(<IN>){
				chomp;
				my @F=split /\t/;
				push @samples,$F[0];
				push @groups,$F[1] unless $groups{$F[1]};
				$groups{$F[1]}++;
			}
			close IN;
			for my $g(@groups){
				$group .= $group ? ",$groups{$g}" : $groups{$g};
			}
			system "mkdir -p $base";
			chdir "$base";
			my $map= $display=~/^\//? $display : "../$display";
			$opts{p}= $opts{p}=~/^\//? $opts{p} : "../$opts{p}";
			unless(-s "seqs.fna" ){
				system "get_seqs_in_fa.pl ../seqs.fna $map 250  1 >seqs.fna";
				system "reads_stat.pl -m $map -a $opts{g}  seqs.fna"; 
			}
			if($opts{o}){
				&otu($map);
			}
			if($opts{v}){
				&venn($map);
			}
			
			local $/;
			open IN,"<otus/otu_summary.txt" or die $!;
			my $line=<IN>;
			close IN;
			my( $sample_num,$min,$max,$mean)=$line=~/Num samples: (\d+).*Min: (\d+).*Max: (\d+).*Mean: (\d+)/ms;
			local $/="\n";

			if($opts{a}){
				my $n= int($mean/100000)+1;
				$max= $max < $n*100000 ? $max : $n*100000;
				my $step= $opts{f} ? 50  : $n*2000;
				&alpha($max,$step,$min,$group,\@samples,\@groups);
			}

			if($opts{b}){
				&beta($map,$min,scalar @samples);
			}
			if($opts{u}){
				&upload($min,scalar @samples);
			}
			exit(0);
		}
		$i++;
	}
}

for my $i(0 .. $#pid){
	waitpid($pid[$i],0);
}




sub extract {
	die "option -l is required!\n" unless @fq==2;
	system "flash -o out -t $opts{O}  -x  $opts{x} -M 220  @fq";
	system "reverse_complement_fastq.pl -i out.extendedFrags.fastq -o out.rev.fastq ";
	system "extract_barcodes.py -f out.extendedFrags.fastq -o barcodef -l 12";
	system "extract_barcodes.py -f out.rev.fastq -o barcoder -l 12 ";
	system "split_libraries_fastq.py -i barcodef/reads.fastq,barcoder/reads.fastq  -b barcodef/barcodes.fastq,barcoder/barcodes.fastq  -o split/ -m $opts{m} -q 19 --barcode_type 12 ";
	system "rm_chimeric_seqs.pl -f split/seqs.fna -o seqs.fna -m $opts{O} -p";
	system "reads_stats.pl -m $opts{m} seqs.fna ";
}

sub otu{
	my $map=shift @_;
	my $its= $opts{I} ? "--suppress_align_and_tree  -r /home/yangchao/16S/its_12_11_otus/rep_set/97_otus.fasta" : '';
	system "pick_open_reference_otus.py -i seqs.fna -o otus/ -a -O $opts{O} -p $opts{p} $its ";
	my $input= $opts{I} ? 'otus/otu_table_mc2_w_tax.biom' : 'otus/otu_table_mc2_w_tax_no_pynast_failures.biom';
	system "sort_otu_table.py -i  $input -o otus/otu_table.biom -l $map -s SampleID";
	system "biom summarize-table -i otus/otu_table.biom -o otus/otu_summary.txt";
	system "biom convert --header-key taxonomy --to-tsv -i otus/otu_table.biom -o otus/otu_table.txt ";
	system "txt_to_excel.pl -f  -s tab -r 2 -o 2.otu_table.xlsx otus/otu_table.txt";
	system "summarize_taxa_through_plots.py -i otus/otu_table.biom -o taxa_plots/  -p $opts{p} -m $map ";
	system "summarize_taxa_through_plots.py -i otus/otu_table.biom -o taxa_plots_Treatment  -p $opts{p} -m $map -c Treatment";
	system "txt_to_excel.pl -s tab -f -r 2 -o 3.taxonomy.xlsx -n 'Phylum,Class,Order,Family,Genus,Species' taxa_plots/*_L?.txt ";
	system "txt_to_excel.pl -s tab -f -r 2 -o 3.taxonomy_Group.xlsx -n 'Phylum,Class,Order,Family,Genus,Species' taxa_plots_Treatment/*_L?.txt ";
	system "plot_16S_heatmap.pl -f 0.01  taxa_plots/taxa_summary_plots/";
}

sub venn{
	my $map=shift @_;
	system "mkdir -p venn";
	open IN,"<$map" or die $!;
	my %venn;
	my %has;
	my $treatment=0;
	while(<IN>){
		chomp;
		my @F=split /\t/;
		if($.==1){
			for my $i(0.. $#F){
				$treatment=$i if $F[$i] eq 'Treatment';
			}
			next;
		}
		next if /^\s+$/;
		$venn{$F[0]}=$F[$treatment];
		$has{$F[$treatment]}++;
	}
	close IN;
	use FileHandle;
	my %fh;
	{
		for my $class(keys %has){
			open $fh{$class},">venn/$class.txt" or die $!;
		}
		open IN,"<otus/otu_table.txt" or die $!;
		my @class;
		while(<IN>){
			chomp;
			my @F=split /\t/;
			my %hash;
			if(/^#OTU ID/){
				@class=@F;
			}elsif(/^#/){
				next;
			}else{
				for my $i(1 .. ($#F-1) ){
					$hash{ $venn{ $class[$i] } }++ if $F[$i] ne '0.0';
				}
			}
			for my $c(keys %hash){
				$fh{$c}->print("$F[0]\n");
			}
		}
		close IN;
		for my $key(keys %fh){
			close $fh{$key};
		}
		system "plot_venn.pl -o venn/venn.png -t png venn/*.txt" if (scalar keys %has <6);
	}
}

sub alpha{
	my ($max,$step,$min,$group,$ref1,$ref2)=@_;
	my @samples=@{$ref1};
	my @groups=@{$ref2};
	if($opts{f}){
		system "parallel_multiple_rarefactions.py -i otus/otu_table.biom -m 50 -x $max -s 50 -n 3 -o rare  -O $opts{O}";
	}else{
		system "parallel_multiple_rarefactions.py -i otus/otu_table.biom -m 500 -x 1900 -s 100 -n 3 -o rare  -O $opts{O}";
		system "parallel_multiple_rarefactions.py -i otus/otu_table.biom -m 2000 -x $max -s $step  -n 3 -o rare  -O $opts{O} ";
	}
	
	my $metrics= $opts{I} ? 'chao1,goods_coverage,observed_species,shannon,simpson' : 'ace,PD_whole_tree,chao1,goods_coverage,observed_species,shannon,simpson';
	my $tree= $opts{I} ? '' : '-t otus/rep_set.tre';
	system "parallel_alpha_diversity.py -i rare -o alpha_diversity   -O $opts{O} -m $metrics   $tree";
	system "collate_alpha.pl  alpha_diversity  collated/";
	system "alpha_index_all.pl  otus/otu_table.biom  all_reads_diversity_index  ";
	system "txt_to_excel.pl -f  -s tab -r 1 -o 4.alpha_diversity.xlsx  all_reads_diversity_index.txt collated/*.txt ";

	system "mkdir -p alpha_curves";
	system "alpha_curves.pl --group $group  --output  alpha_curves/alpha_curves --type  $opts{t}  collated/ ";
	if(scalar @samples <=16){
		system "plot_rank_abundance_graph.py -i otus/otu_table.biom -s '*' -x  -o alpha_curves/rank_abundance.pdf ";
	}else{
		my @tmp=split /,/,$group;
		my $flag=0;
		for my $g(@tmp){
			$flag=1 if $g >16;
		}
		if($flag){
			my $divide= int( (scalar @samples -0.1)/16) +1  ;
			my $num= int( (scalar @samples-0.1) /$divide)+1;
			my $iter=0;
			for (my $i=0;$i<=$#samples;$i+=$num){
				$iter++;
				my $end= ($i+$num-1) < $#samples ? $i+$num-1 : $#samples; 
				my $rank_str= join ",",@samples[$i..$end];
				system "plot_rank_abundance_graph.py -i otus/otu_table.biom -s $rank_str -x  -o alpha_curves/rank_abundance_$iter.pdf ";
			}
		}else{
			my $sum=0;
			my @sam;
			my @gr;
			my $sum_all=0;
			my $i=0;
			my $rank_str;
			my $gr_str;
			for my $g(@tmp){
				if($sum+$g <=16  ){
					$sum+=$g;
					push @sam,@samples[$sum_all..($sum_all+$g-1)];
					push @gr,$groups[$i];
				}else{
					$rank_str=join ",",@sam;
					$gr_str= join "_",@gr;
					system "plot_rank_abundance_graph.py -i otus/otu_table.biom -s $rank_str -x  -o alpha_curves/rank_abundance_$gr_str.pdf ";
					$sum=$g;
					@sam=$samples[$sum_all..($sum_all+$g-1)];
					@gr=$groups[$i];
				}
				$sum_all+=$g;
				$i++;
			}
			$rank_str=join ",",@sam;
			$gr_str= join "_",@gr;
			system "plot_rank_abundance_graph.py -i otus/otu_table.biom -s $rank_str -x  -o alpha_curves/rank_abundance_$gr_str.pdf ";
		}
	}
}

sub beta{
	my ($map,$min,$sample_num)=@_;
	return if $sample_num <3;
	if($opts{I}){
		system "core_diversity_analyses.py -i otus/otu_table.biom -o cdout -m $map -e $min -a -O $opts{O} --suppress_taxa_summary --suppress_alpha_diversity -p $opts{p} -c Treatment  --nonphylogenetic_diversity "; 
		system "make_2d_plots.py -i cdout/bdiv_even$min/bray_curtis_pc.txt -m $map -o cdout/bdiv_even$min/bray_curtis_2d_pcoa_plots/ --colorby SampleID,Treatment ";
		system "plot_UPGMA_tree.pl cdout/bdiv_even$min/bray_curtis_dm.txt  cdout/bdiv_even$min/bray_curtis.pdf";
		system "txt_to_excel.pl -s tab -f -r 1 -o 5.beta_diversity.xlsx cdout/bdiv_even$min/bray_curtis_dm.txt";
		system "mkdir -p 3d_plot";
		system "plot_3d_plot.pl -m $map -o 3d_plot/ otus/otu_table.txt  " ;

	}else{
		system "core_diversity_analyses.py -i otus/otu_table.biom -o cdout -m $map -e $min -a -O $opts{O} -t otus/rep_set.tre --suppress_taxa_summary --suppress_alpha_diversity -p $opts{p} -c Treatment  "; 
		system "make_2d_plots.py -i cdout/bdiv_even$min/weighted_unifrac_pc.txt -m $map -o cdout/bdiv_even$min/weighted_unifrac_2d_pcoa_plots/ --colorby SampleID,Treatment " if $sample_num>3;
		system "make_2d_plots.py -i cdout/bdiv_even$min/unweighted_unifrac_pc.txt -m $map -o cdout/bdiv_even$min/unweighted_unifrac_2d_pcoa_plots/ --colorby SampleID,Treatment";
		system "plot_UPGMA_tree.pl cdout/bdiv_even$min/weighted_unifrac_dm.txt  cdout/bdiv_even$min/weighted_unifrac_UPGMA.pdf" if $sample_num>3;
		system "plot_UPGMA_tree.pl cdout/bdiv_even$min/unweighted_unifrac_dm.txt cdout/bdiv_even$min/unweighted_unifrac_UPGMA.pdf" ;
		system "txt_to_excel.pl -s tab -f  -r 1 -o 5.beta_diversity.xlsx cdout/bdiv_even$min/*_dm.txt";
		system "mkdir -p 3d_plot";
		system "plot_3d_plot.pl -m $map -o 3d_plot/ otus/otu_table.txt  " if $sample_num>3;
	}
}

sub upload{
	my ($min,$sample_num)= @_;
	system "rm -rf upload";
	system "mkdir -p upload/1.sequence_stat  upload/2.otu_table upload/3.taxonomy upload/4.alpha_diversity ";
	system "mkdir -p upload/5.beta_diversity " if $sample_num>2;
	system "ln -s -f -r 1.sequence_stat.xlsx upload/1.sequence_stat/";
	system "ln -s -f -r length_distribution.png upload/1.sequence_stat/";
	system "ln -s -f -r seq_number.png upload/1.sequence_stat/";
	system "ln -s -f -r 2.otu_table.xlsx  upload/2.otu_table/";
	system "ln -s -f -r otus/otu_summary.txt  upload/2.otu_table/";
	system "ln -s -f -r otus/rep_set.fna  upload/2.otu_table/";
	system "ln -s -f -r venn/*.png  upload/2.otu_table/";
	system "ln -s -f -r 3.taxonomy*xlsx upload/3.taxonomy/";
	system "ln -s -f -r taxa_plots/taxa_summary_plots/ upload/3.taxonomy/taxonomy_plots ";
	system "ln -s -f -r taxa_plots_Treatment/taxa_summary_plots upload/3.taxonomy/taxonomy_Group_plots ";
	system "ln -s -f -r heatmap.pdf upload/3.taxonomy/";
	system "ln -s -f -r 4.alpha_diversity.xlsx upload/4.alpha_diversity/";
	system "ln -s -f -r alpha_curves/*.pdf upload/4.alpha_diversity/ ";
	if($sample_num>2){
		system "ln -s -f -r 5.beta_diversity.xlsx  upload/5.beta_diversity/ ";
		system "ln -s -f -r cdout/bdiv_even$min/*.pdf  upload/5.beta_diversity/";
	}

	if($sample_num>3){

	system "ln -s -f -r cdout/bdiv_even$min/*plots  upload/5.beta_diversity/";
	if($opts{I}){
		system "ln -s -f -r cdout/bdiv_even$min/bray_curtis_emperor_pcoa_plot  upload/5.beta_diversity/bray_curtis_3d_pcoa_plot";
	}else{
		system "ln -s -f -r cdout/bdiv_even$min/unweighted_unifrac_emperor_pcoa_plot  upload/5.beta_diversity/unweighted_unifrac_3d_pcoa_plot";
		system "ln -s -f -r cdout/bdiv_even$min/weighted_unifrac_emperor_pcoa_plot  upload/5.beta_diversity/weighted_unifrac_3d_pcoa_plot";
	}
	system "ln -s -f -r /home/yangchao/16S/3d_pcoa_plot说明.txt  upload/5.beta_diversity/";
	system "ln -s -f -r 3d_plot/*.pdf upload/5.beta_diversity/";

	}
}

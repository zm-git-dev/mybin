#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Getopt::Long;

=pod

USAGE: add_omim_annotation.pl [opt]  files

-l --line         [default : 1 ]

-g --gene         [default : Gene_Name]

-p --position          [default : ESP6500_MAF_ALL ]

-m --map           [default : /MGCN/Databases/OMIM/genemap2.txt ]

-h --help


=cut

my %opts=(
	l => 1,
	g => 'Gene_Name',
	p => 'ESP6500_MAF_ALL',
	m => '/MGCN/Databases/OMIM/genemap2.txt',
);
GetOptions(\%opts,
	'l|line=i',
	'g|gene=s',
	'p|position=s',
	'm|map=s',
	'h|help',
);
die `pod2text $0` if($opts{h} or !@ARGV);

open IN,"<$opts{m}" or die $!;
my (%mim);
my $count=0;
while(<IN>){
	chomp;
	next if /^#/;
	my @F=split /\t/;
	$F[6]=~s/ //g;
	$F[12] |= '.';
	for my $g(split /,/,$F[6]){
		$mim{$g}{$F[5]}=$F[12];
	}
	
}
close IN;

for my $f(@ARGV){
	system "mv $f $f.tmp";
	open IN,"<$f.tmp" or die $!;
	open OUT,">$f" or die $!;
	my ($gene_index,$position_index);
	while(<IN>){
		chomp;
		s/,//g;
		my ($id,$disease);
		my @F=split /\t/;

		if($.< $opts{l}){
			print OUT "$_\n";
			next;
		}elsif($.== $opts{l}){
			for my $i(0 .. $#F){
				$gene_index=$i if $F[$i] eq $opts{g};
				$position_index=$i if $F[$i] eq $opts{p};
			}
			die "file $f has no field \"$opts{g}\" at line $opts{l}!\n" unless $gene_index;
			die "file $f has no field \"$opts{p}\" at line $opts{p}!\n" unless $position_index;
			$id='MIM_ID';
			$disease='Disease_info';
		}else{
			my $g=$F[$gene_index];
			if($mim{$g}){
				for my $mimid(keys %{$mim{$g}}){
					$id.= $id ? "|$mimid" : $mimid;
					$disease.= $disease ? "|$mim{$g}{$mimid}" : $mim{$g}{$mimid}; 
				}
			}else{
				$id='.';
				$disease='.';
			}
		}

		my $str= join "\t",@F[0.. $position_index],$id,$disease,@F[($position_index+1) .. 49];
		print OUT "$str\n";
	}
	close IN;
	close OUT;

}

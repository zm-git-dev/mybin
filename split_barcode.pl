#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use List::Util qw /max/;
use Getopt::Long;

=pod

	USAGE :  split_barcode.pl  [opt]  < -m MAP >  < -o OUT >

used for full-length 16S. 
	
yangchao@macrogencn.com


-s --score <INT> 		default :  40

-h --help <boolean>

-o --output <file>

-m --map <file>			barcode map file

-t --tail <boolean>             

=cut 

my %opts=(
	s => 40,
	linker => 12,	# linker seq length
	align => 30,   # align seq length
	linker_seq => 'TATGGTAATTGT',
	min_seq_len => 1000,
	max_seq_len => 2000,
);
GetOptions(\%opts,
	"h|help",
	"s|score=i",
	"m|map=s",
	"t|tail",
	"o|output=s",
);
die `pod2text $0` if($opts{h} or @ARGV!=1 or !$opts{o} or !$opts{m});

my $time=localtime;
print STDERR "$time\n";
my %score=(
	ins => -1,
	del => -1,
	mis => -2,
	mat => 2,
);

open IN,"<$opts{m}" or die $!;
<IN>;
my %map;
my %barcode_len;
my %subject_len;
while(<IN>){
	my @F=split /\t/;
	$map{$F[0]}="$F[1]$opts{linker_seq}";
	my $len=$opts{linker}+(length $F[1]);
	$barcode_len{$F[0]}=$len;
	$subject_len{ $len }++;
}
close IN;

my %preset;
for my $l(keys %subject_len){
	my @matrix;
	for my $i(0 .. $l){
		for my $j(0 .. $opts{align}){
			$matrix[$i][$j]=0;
		}
	}
	$preset{$l}=\@matrix;
}


open OUT,">$opts{o}" or die $!; 
#open OUT2,">$opts{o}.erro" or die $!; 
my $counter=1;

my $seq= $ARGV[0]=~/(fa|fasta|fsa|fna)$/ ? 'fa' : $ARGV[0]=~/(fq|fastq)$/ ? 'fq' : "unknown" ;
die "unknown suffix of file $ARGV[0]\n"  if $seq eq "unknown";

{
	open IN,"<$ARGV[0]" or die $!;
	local $/="\n>" if $seq eq 'fa';
	while(<IN>){
		chomp;
		s/^(>|\@)//;
		my @F;
		if($seq eq 'fa'){
			@F=split /\n/,$_,2;
			$F[1]=~s/\n//g;
		}else{
			my $l2=<IN>;
			chomp $l2;
			@F=($_,$l2);
			<IN>;<IN>;
		}
		my $len=length $F[1];
		next if ($len < $opts{min_seq_len} or $len >$opts{max_seq_len});
		my $f=substr($F[1],0,$opts{align});
		my $r=substr($F[1],$len-$opts{align});
		$r=~tr/AGTC/TCAG/;
		$r=reverse $r;
		my %hash;
		for my $sample(keys %map){
			my @matrix=@{$preset{ $barcode_len{$sample} }};
			my ($s1,$l1)=&my_align($map{$sample},$f,$barcode_len{$sample},$opts{align},\@matrix );
			my @matrix2=@{$preset{ $barcode_len{$sample} }};
			my ($s2,$l2)=&my_align($map{$sample},$r,$barcode_len{$sample},$opts{align},\@matrix2 );
			$hash{$s1}{$sample}{ forward}=$l1;
			$hash{$s2}{$sample}{ reverse }=$l2;
		}
		my $max_score=0;
		for my $s(sort {$b<=>$a}keys %hash){
			last if $s < $opts{s};
			my @samples=keys %{$hash{$s}};
			if( @samples ==1 ){
				my @direction=keys %{$hash{$s}{$samples[0]}};
				#if( @direction >1){print OUT2 "$s\t@samples\t@direction\t$F[0]\n";last;}
				last if( @direction >1);
				my $l=$hash{$s}{$samples[0]}{$direction[0]};
				my $str;
				if($direction[0] eq 'forward'){
					my $t= $opts{t} ? $len-$l : $len-$opts{linker}-$l;
					$str=substr($F[1],$l,$t);
				}else{
					my $start= $opts{t} ? 0 : $opts{linker};
					my $end= $opts{t} ? $len-$l : $len-$l-$opts{linker};
					$str=substr($F[1],$start,$end);
				}
				print OUT">$samples[0]\_$counter $F[0] score=$s\n$str\n";
				$counter++;
			}else{
			#	print OUT2 "$s\t@samples\t$F[0]\n";
			}
			last;
		}
	}
	close IN;
}


$time=localtime();
print STDERR "$time\n";

sub my_align{
	my ($s1,$s2,$l1,$l2,$ref)=@_;
	my @matrix=@{$ref};
	my ($max_score,$len)=(0,0);
	for my $i(1 .. $l1){
		my $c1=substr($s1,$i-1,1);
		for my $j(1 .. $l2){
			my $c2=substr($s2,$j-1,1);
			my $score1= $matrix[$i-1][$j-1] + ($c1 eq $c2 ? $score{mat} :  $score{mis});
			my $score2= $matrix[$i-1][$j] + $score{ins};
			my $score3= $matrix[$i][$j-1] + $score{del};
			$matrix[$i][$j]=max( $score1,$score2,$score3,0);
		}
	}
	for my $j(1 .. $l2){
		if($matrix[$l1][$j] > $max_score){
			$max_score= $matrix[$l1][$j] ;
			$len= $j;
		}
	}
	return ($max_score,$len);
}


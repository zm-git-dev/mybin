use strict;
use List::Util qw /max/;

=pod

USAGE ： extract_barcode_and_sequence.pl  paired_1.fq  paired_2.fq  > stat.txt

=cut

die `pod2text $0` unless @ARGV==2;
my %score=(
	'match' => 1,
	'mismatch' => -1,
	'gap' => -2,
);

my @score;
for my $j(0..150){
	for my $i(0 .. 44){
		if($j==0){
			$score[$i][$j]= $score{gap} * $i;
		}else{
			$score[$i][$j]=0;
		}
	}
}

my $bait = 'GTTTTAGAGCTAGAAATAGCAAGTTAAAATAAGGCTAGTCCGTT';
my $bait_len= 44;
my $seq_len = 20;
my $barcode_len = 6;
my $goal = 35;   ### bait score >= 35  
my $seq_mismatch=2;  ### seq mismatch <= 2
my %sample_rev=(
	'CGATGT' => 1,
	'TTAGGC' => 2,
	'TGACCA' => 3,
	'ACAGTG' => 4,
	'GCCAAT' => 5,
	'CAGATC' => 6,
	'ACTTGA' => 7,
	'GATCAG' => 8,
	'TAGCTT' => 9,
	'GGCTAC' => 10,
	'CTTGTA' => 11, 
	'AGTCAA' => 12,
	'AGTTCC' => 13, 
);
my %sample;
for my $seq(keys %sample_rev){
	my $rev = &rev_com($seq);
	$sample{$rev} = $sample_rev{$seq};
}
open IN1,"$ARGV[0]" or die $!;
open IN2,"$ARGV[1]" or die $!;
my $count=0;
my %hash;
my %total;
my %sam2num;
my %error;
my $tmp=0;
while(<IN1>){
	my $name=$_;
	chomp $name;
        my $s1=<IN1>;
	chomp $s1;
        <IN1>;
	my $q1=<IN1>;
	<IN2>;
	my $s2=<IN2>;
	chomp $s2;
	<IN2>;
	my $q2=<IN2>;
	my $r1 = &rev_com($s1);
	my $r2 = &rev_com($s2);
	$count++;
	my $pos_s1 = index($s1,$bait);
	my $pos_r1 = index($r1,$bait);
	my $pos_s2 = index($s2,$bait);
	my $pos_r2 = index($r2,$bait);
	my ($seq1,$seq2,$barcode1,$barcode2,$flag,$seq1_start,$seq2_start);
###     1st of paired end  ###
	if($pos_s1 >0){
		$seq1 = substr($s1,$pos_s1-$seq_len,$seq_len);
		$barcode1 = substr($s1,$pos_s1+$bait_len,$barcode_len);
		$seq1_start=$pos_s1-$seq_len;
		$flag=1;
	}elsif($pos_r1 >0){
		$flag=-1;
		$seq1 = substr($r1,$pos_r1-$seq_len,$seq_len);
		$seq1_start = length($s1)-$pos_r1+$seq_len-1;
		$barcode1 = substr($r1,$pos_r1+$bait_len,$barcode_len);
	}else{
		my @out1 = &my_compare($bait,$s1,\@score);
		if($out1[0] >= $goal ){
			$flag=1;
			$seq1 = substr($s1,$out1[1]-1-$seq_len,$seq_len);
			$barcode1 = substr($s1,$out1[2],$barcode_len);
			$seq1_start = $out1[1]-1-$seq_len;
		}else{
			@out1= &my_compare($bait,$r1,\@score);
			if($out1[0] >= $goal){
				$flag=-1;
				$seq1 = substr($r1,$out1[1]-1-$seq_len,$seq_len);
				$seq1_start = length($s1)-$out1[1]+$seq_len;
				$barcode1 = substr($r1,$out1[2],$barcode_len);
			}
		}
	}
###     second of paired end ###	
	if($pos_s2 >0){
		$seq2 = substr($s2,$pos_s2-$seq_len,$seq_len);
		$seq2_start = $pos_s2-$seq_len;
		$barcode2 = substr($s2,$pos_s2+$bait_len,$barcode_len);
		$flag=-1 ;
	}elsif($pos_r2 >0){
		$flag=1 ;
		$seq2 = substr($r2,$pos_r2-$seq_len,$seq_len);
		$seq2_start = length($s2)-$pos_r2+$seq_len-1;
		$barcode2 = substr($r2,$pos_r2+$bait_len,$barcode_len);
	}else{
		my @out1 = &my_compare($bait,$s2,\@score);
		if($out1[0] >= $goal ){
			$flag=-1 ;
			$seq2 = substr($s2,$out1[1]-1-$seq_len,$seq_len);
			$seq2_start = $out1[1]-1-$seq_len;
			$barcode2 = substr($s2,$out1[2],$barcode_len);
		}else{
			@out1= &my_compare($bait,$r2,\@score);
			if($out1[0] >= $goal){
				$flag=1;
				$seq2 = substr($r2,$out1[1]-1-$seq_len,$seq_len);
				$seq2_start = length($s2)-$out1[1]+$seq_len;
				$barcode2 = substr($r2,$out1[2],$barcode_len);
			}
		}
	}
###   hit or not ###
	my $sample_name;
	if($barcode1 and $sample{$barcode1} ){
		$sample_name = $sample{$barcode1};
	}
	if($barcode2 and $sample{$barcode2} ){
		if(!$sample_name or $sample_name eq $sample{$barcode2} ){
			$sample_name = $sample{$barcode2};
		}elsif($sample_name ne $sample{$barcode2}){
			$sample_name = '';
		}
	}
	if($sample_name){
		if($seq1 eq $seq2 or $seq1 && !$seq2 or  !$seq1 && $seq2 ){
			my $seq = $seq1 || $seq2;
			$hash{$seq}{$sample_name}++;
			$total{$seq}++;
			$sam2num{$sample_name}++;
		}elsif($seq1 and $seq2){
			next unless(length $seq1==$seq_len and length $seq2 == $seq_len);
			my $seq;
			my $inconsistent=0;
			for my $i(0..$seq_len-1){
				my $c1 = substr($seq1,$i,1);
				my $c2 = substr($seq2,$i,1);
				if($c1 eq $c2){
					$seq.=$c1;
				}else{
					$inconsistent++;
					my $qc1=substr($q1,$seq1_start+$flag*$i,1);
					my $qc2=substr($s2,$seq2_start-$flag*$i,1);
					$seq.= ord($qc1)<ord($qc2) ? $c2 :  $c1;
				}
			}
			next if $inconsistent > $seq_mismatch;
#			print "$name\t$flag\t$seq1\t$seq2\t$seq\t$inconsistent\t$seq1_start\t$seq2_start\t".(length $s1)."\n";
			$hash{$seq}{$sample_name}++;
			$total{$seq}++;
			$sam2num{$sample_name}++;
			$error{$inconsistent}++;
		}
	}
#	if($count % 10000 ==0){
#		print STDERR "$count\n";
#	}
}
close IN1;
close IN2;
#print STDERR "tmp:$tmp\n";
#for my $incon(sort {$a<=>$b}keys %error){
#	print STDERR "$incon\t$error{$incon}\n";
#}
print join "\t",'Seq','Total',1..13;
print "\n";
for my $s(sort {$total{$b} <=> $total{$a} } keys %total){
	print "$s\t$total{$s}";
	for my $sam(1..13){
		my $tmp = $hash{$s}{$sam} || 0;
		print "\t$tmp";
	}
	print "\n";
}


sub rev_com{
	my $s=shift @_;
	$s = reverse $s;
	$s=~tr/ACTG/TGAC/;
	return $s;
}

sub my_compare{
	my ($s1,$s2,$ref)=@_;
	my $l1 = length $s1;
	my $l2 = length $s2;
	my @score = @{$ref};
	my $total_max_v=0;
	my (@y,$max_y);
	for my $j(1.. $l2){
		my $c2 = substr($s2,$j-1,1);
		for my $i(1 .. $l1){
			my $c1 = substr($s1,$i-1,1);
			my $mat = $score[$i-1][$j-1] + ( $c1 eq $c2 ? $score{'match'} : $score{'mismatch'} );
			my $ins = $score[$i][$j-1] + $score{'gap'} ;
			my $del = $score[$i-1][$j] + $score{'gap'} ;
			my $max_v = max($mat,$ins,$del);
			$score[$i][$j]= $max_v;
			if($i==1){
				$y[1][$j]= $j;
			}else{
				$y[$i][$j]= $mat == $max_v ? $y[$i-1][$j-1] : $ins == $max_v ? $y[$i][$j-1] : $y[$i-1][$j] ;
			}
		}
	}
	for my $j(0 .. $l2){
		if($score[$l1][$j] > $total_max_v){
			$total_max_v = $score[$l1][$j];
			$max_y = $j;
		}
	}
	return($total_max_v,$y[$l1][$max_y],$max_y);
}

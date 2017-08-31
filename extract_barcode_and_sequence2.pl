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

my $bait2 = 'GTTTTAGAGCTAGAAATAGCAAGTTAAAATAAGGCTAGTCCGTT';
my $bait2_rev = &rev_com($bait2);
my $bait1 = 'GTGGAAAGGACGAAACACCG';
my $bait1_rev = &rev_com($bait1);
my $bait2_len= 44;
my $bait1_len= 20;
my $seq_len = 20;
my $barcode_len = 6;
my $goal2 = 35;   ### bait score >= 35  
my $goal1 = 15; 
my $goal = 15;
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
	$count++;
	my ($flag1,$seq1,$start1,$len1,$barcode1)=&find_substr($s1);
	my ($flag2,$seq2,$start2,$len2,$barcode2)=&find_substr($s2);
	if($flag1 * $flag2 <0){
		if(  $sample{$barcode1} or $sample{$barcode2}  ){
			if( $barcode1 eq $barcode2 or $sample{$barcode1} && !$sample{$barcode2} or !$sample{$barcode1} && $sample{$barcode2} ){
				$barcode1 = $barcode2 if $sample{$barcode2};
				if($seq1 eq $seq2){
					$hash{$seq1}{$sample{$barcode1}}++;
					$total{$seq1}++;
				}elsif(length $seq1 eq length $seq2){
					my ($out_seq,$mismatch_count);
					if($flag1 >0){
						($out_seq,$mismatch_count)=&optimize($seq1,$seq2,substr($q1,$start1,$len1),reverse(substr($q2,$start2,$len2)) );
					}else{
						($out_seq,$mismatch_count)=&optimize($seq1,$seq2,reverse(substr($q1,$start1,$len1)),substr($q2,$start2,$len2) );
					
					}
					if ($mismatch_count <= $seq_mismatch){
						$hash{$out_seq}{$sample{$barcode1}}++;
						$total{$out_seq}++;
					}else{
					}
				}else{
				}
			}else{
			}
		}else{
		}
	}elsif($flag1*$flag2>0){
#	}elsif($flag1 ){
	}elsif(0 ){
		if($sample{$barcode1}){
			$hash{$seq1}{$sample{$barcode1}}++;
			$total{$seq1}++;
		}else{
		}
#	}elsif($flag2){
	}elsif(0){
		if($sample{$barcode2}){
			$hash{$seq2}{$sample{$barcode2}}++;
			$total{$seq2}++;
		}else{
		}
	}else{
	}
	if($count % 1000 ==0){
#		print STDERR "$count\n";
	}
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

sub optimize{
	my ($s1,$s2,$q1,$q2)=@_;
	my $str;
	my $count=0;
	for my $i(0 .. (length $s1)-1 ){
		my $c1 = substr($s1,$i,1);
		my $c2 = substr($s2,$i,1);
		if($c1 eq $c2){
			$str.= $c1;
		}else{
			my $t1 = ord(substr($q1,$i,1));
			my $t2 = ord(substr($q2,$i,1));
			$count++;
			$str.= $t1 > $t2 ? $c1 : $c2;
		}
	}
	return($str,$count);
}

sub my_compare{
	my ($s1,$s2,$ref,%score)=@_;
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

sub find_substr{
	my ($s)=@_;
	my $pos1=index($s,$bait1);
	my $pos1_rev=index($s,$bait1_rev);
	my $pos2=index($s,$bait2);
	my $pos2_rev=index($s,$bait2_rev);
	my $flag = 0 ;
	my ($e1,$e2);
	if($pos1 >=0 or $pos2 >=0){
		$flag = 1;
		
	}elsif($pos1_rev >=0 or $pos2_rev>=0){
		$flag = -1;
	}

	if($pos1 >=0 or $pos1_rev >=0){
		$e1 = $pos1 >=0 ? $pos1+$bait1_len-1 : $pos1_rev + $bait1_len-1;
		$pos1 = $pos1_rev if $pos1_rev >=0;
	}
	if($pos2 >=0 or $pos2_rev >=0){
		$e2 = $pos2 >=0 ? $pos2+$bait2_len-1 : $pos2_rev + $bait2_len-1;
		$pos2 = $pos2_rev if $pos2_rev >=0;
	}
	### bait1 ###
	if($pos1 <0 ){
		my ($score1,$start1,$end1);
		if($flag==1){
			($score1,$start1,$end1)=&my_compare($bait1,$s,\@score);
			if($score1 < $goal1){
				return(0,1,0,0,0);
			}else{
				($pos1,$e1)=($start1-1,$end1-1);
			}
		}elsif($flag==-1){
			($score1,$start1,$end1)=&my_compare($bait1_rev,$s,\@score);
			if($score1 < $goal1){
				return(0,2,0,0,0);
			}else{
				($pos1,$e1)=($start1-1,$end1-1);
			}
		}else{
			($score1,$start1,$end1)=&my_compare($bait1,$s,\@score);
			if($score1 < $goal1){
				($score1,$start1,$end1)=&my_compare($bait1_rev,$s,\@score);
				if ($score1 >= $goal1){
					$flag = -1;
					($pos1,$e1)=($start1-1,$end1-1);
				}
			}else{
				$flag = 1;
				($pos1,$e1)=($start1-1,$end1-1);
			}
		}
	}
	### bait2 ###
	if($pos2 <0 ){
		my ($score2,$start2,$end2);
		if($flag==1){
			($score2,$start2,$end2)=&my_compare($bait2,$s,\@score);
			if($score2 < $goal2){
				return(0,3,0,0,0);
			}else{
				($pos2,$e2)=($start2-1,$end2-1);
			}
		}elsif($flag==-1){
			($score2,$start2,$end2)=&my_compare($bait2_rev,$s,\@score);
			if($score2 < $goal2){
				return(0,4,0,0,0);
			}else{
				($pos2,$e2)=($start2-1,$end2-1);
			}
		}else{
			($score2,$start2,$end2)=&my_compare($bait2,$s,\@score);
			if($score2 < $goal2){
				($score2,$start2,$end2)=&my_compare($bait2_rev,$s,\@score);
				if ($score2 >= $goal2){
					$flag = -1;
					($pos2,$e2)=($start2-1,$end2-1);
				}
			}else{
				$flag = 1;
				($pos2,$e2)=($start2-1,$end2-1);
			}
		}
	}
	if($pos1 <0 or $pos2<0){
		return(0,5,0,0,0);
	}
	if($flag>0){
		my $barcode = substr($s,$e2+1,$barcode_len) ;
		my $out = substr($s,$e1+1,$pos2-$e1-1);
		return ($flag,$out,$e1+1,$pos2-$e1-1,$barcode);
	}elsif($flag<0){
		my $barcode = &rev_com(substr($s,0,$pos2));
		my $out = &rev_com(substr($s,$e2+1,$pos1-$e2-1));
		return ($flag,$out,$e2+1,$pos1-$e2-1,$barcode);
	}else{
		return(0,6,0,0,0);
	}
}

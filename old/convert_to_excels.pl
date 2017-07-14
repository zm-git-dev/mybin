#!/usr/bin/perl -w
use strict;
use threads;
use Getopt::Long;

=pod

USAGE : convert_to_excels.pl [opt]  *.txt 

-m --max [int]		max threads number. default : 10

-s --sleep [int]	sleep N seconds to search completed threads and start new threads. default : 1	

-r --row [int]          first row number to bold

-h --help		print this.

=cut

my %opts=(
	max => 10,
	sleep => 1,
	row => 1,
);
GetOptions(
	"max|m=i" => \$opts{max},
	"sleep|s=i" => \$opts{sleep},
	"row|r=i" => \$opts{row},
	"help|h" => \$opts{help},
);

die `pod2text $0` if($opts{help} or @ARGV==0 );
my @th;
my $flag=1;

LAB:
while(1){
	my $count=0;
	for my $i(0 .. $opts{max}-1){
		if($flag and  !$th[$i] || $th[$i]->is_joinable() ){
			$th[$i]->join if ($th[$i] and $th[$i]->is_joinable() );
			my $f=shift @ARGV;
			unless ($f){
				$flag=0;
				next;
			}
			$th[$i]=threads->create( sub{
				my $file=shift @_;
				system "txt_to_excel.pl -f -s tab -r $opts{row}  $file ";
			},$f);
			$count++;
		}elsif($th[$i] and $th[$i]->is_joinable()  ){
			$count++;
			$th[$i]->join();
		}elsif($th[$i] and $th[$i]->is_running() ){
			$count++;
		}
	}
	last if $count==0;
	sleep($opts{sleep});
}


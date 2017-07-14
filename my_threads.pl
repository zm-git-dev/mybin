#!/usr/bin/perl -w
use strict;
use threads;
use Getopt::Long;


=pod 

USAGE: my_threads.pl [opt]  <command>  [argvs] 

opt:

-n --num_threads 	[default: 10]

-s --sleep 	[default: 1]

-h --help

=cut

my %opts=(
	'n' => 10,
	's' => 1,
);
GetOptions(\%opts,
	'n|num_threads=i',
	's|sleep=i',
	'h|help',
) or die `pod2text $0`;

die `pod2text $0` if($opts{h} or !@ARGV);
my @th;
my $flag=1;
my $command=shift @ARGV;

LAB:
while(1){
	my $count=0;
	for my $i(0 .. $opts{n}-1){
		if($flag and  !$th[$i] || $th[$i]->is_joinable() ){
			$th[$i]->join if ($th[$i] and $th[$i]->is_joinable() );
			my $f=shift @ARGV;
			unless ($f){
				$flag=0;
				next;
			}
			$th[$i]=threads->create( sub{
				my $file=shift @_;
				system "$command $file";
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
	sleep($opts{s});
}


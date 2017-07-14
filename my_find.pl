#!/usr/bin/perl
use strict;
use warnings;


my ($d,$find)=@ARGV;
unless($d and $find){
	print  "USAGE: \n  $0  dir  query_str\n\n" ;
	exit(0);
}
&read_dir($d);

sub read_dir{
	my $dir=shift @_;
	$d=~s/\/*$//g;
	opendir DIR,"$dir" or die $!;
	for my $info(readdir DIR){
		next if($info=~ /^\./);
		if( -d "$dir/$info"){
			&read_dir("$dir/$info");
		}elsif(-b "$dir/$info"){

		}elsif($info =~ /\.jar/){
		
		}elsif(-e "$dir/$info"){
			my $str= `grep $find $dir/$info`;
			print "$dir/$info:\n$str\n" if $str;
		}else{
			print "no $dir/$info\n";
		}		
	}
}

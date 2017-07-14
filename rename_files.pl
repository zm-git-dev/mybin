#!/usr/bin/perl -w
use strict;

=pod

USAGE: rename_files.pl  <dir>  <old_str> <new_str>

=cut

die `pod2text $0` unless @ARGV==3;
my ($directory,$old,$new)=@ARGV;
&read_dir($directory);


sub read_dir{
	my $dir=shift @_;
	$dir=~s/\/$//;
	opendir DIR,"$dir" or die $!;
	my @files=readdir DIR;
	closedir DIR;
	for my $f(@files){
		next if $f =~ /^\./;
		if( $f =~/$old/){
			(my $out=$f)=~s/$old/$new/;
			system "mv $dir/$f $dir/$out ";
			$f=$out;
		}
		if(-d $f){
			&read_dir("$dir/$f");
		}
	}
}



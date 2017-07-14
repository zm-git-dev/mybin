#!/usr/bin/perl -w
 use strict;
 use Text::Iconv;
use Spreadsheet::XLSX;
use Thread;

=pod

USAGE:  excel_to_txt.pl  files.xlsx

=cut

die `pod2text $0` if(!@ARGV or $ARGV[0] eq '-h' or $ARGV[0] eq '--help');
 #my $converter = Text::Iconv -> new ("utf-8", "windows-1251");
 
 # Text::Iconv is not really required.
 # This can be any object with the convert method. Or nothing.

my $cutoff=50;
die "file numbers cannot be larger than $cutoff!\n" if(@ARGV >$cutoff);

my @th;
my $i=0;
for my $file(@ARGV){
 $th[$i++]=Thread->new( sub{
 my $file=shift @_;
 if($file !~ /xlsx$/){
 	print STDERR "file:$file is not excel 2008 format(.xlsx)! This thread exit!\n";
 	exit(0);
 }
 my $excel = Spreadsheet::XLSX -> new ($file);
 $file=~s/\.[^\.]+$//;
 my $flag=0;
 $flag=1 if ( @{$excel ->{Worksheet}} ==1 );
 for my $sheet (@{$excel -> {Worksheet}}) {
 	print "read $file.xlsx:",$sheet->{Name},"\n";
	my $out= $flag ?  "$file.txt"   : "$file.". $sheet->{Name} . ".txt" ;
 	open OUT,">$out" or die $!;
        
        $sheet -> {MaxRow} ||= $sheet -> {MinRow};
        
         for my $row ($sheet -> {MinRow} .. $sheet -> {MaxRow}) {
         
                $sheet -> {MaxCol} ||= $sheet -> {MinCol};
                my $str="";
                for my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
                	
                        my $val = $sheet -> {Cells} [$row] [$col] -> {Val};
                 	$val= $val // '';
 			$str .= $col==$sheet->{MinCol} ? $val : "\t$val" ;
                }
                $str=~s/\&gt;/>/g;
                $str=~s/\&lt;/</g;
                $str=~s/\&amp;/\&/g;
                $str=~s/\&apos;/'/g;
                print OUT "$str\n";
        }
 	close OUT;
 	print "complete $file.xlsx:",$sheet->{Name},"\n";
 }
 },$file);
}

for (@th){
	$_->join();
}




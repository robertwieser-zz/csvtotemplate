#!/usr/bin/perl

use strict;
use FindBin '$Bin';
use Template;
use Text::CSV_XS;
use Data::Dumper;

# fetch CSV file path from args and validate it
my $csv = $ARGV[0];
unless(-e $csv) {
	die "No such file: $csv\n";
}

print "Attempting to parse: $csv\n";
my @rows;
my $csv_xs = Text::CSV_XS->new( {
	binary		=> 1,
	auto_diag	=> 1
});
open my $fh, "<", $csv or die "$csv: $!";
# get first line of CSV, we assume this is the column names
my $cols = $csv_xs->getline($fh);
while( my $row = $csv_xs->getline($fh)) {
	my %hash;
	@hash{@$cols} = @$row;
	push @rows, \%hash;
}
print "Successfully parsed CSV file\n";

foreach my $vars (@rows) {
	if(!defined($vars->{'domain'})) {
		print "Skipping entry: Missing domain\n";
		next;
	}
	my $domain = $vars->{'domain'};
	$domain =~ s/[^A-Za-z0-9\-\.]//g;
	if($domain eq '') {
		print "Skipping entry: Invalid domain\n";
		next;
	}

	if(!defined($vars->{'username'})) {
		print "Skipping entry: Missing username\n";
		next;
	}
	my $username = $vars->{'username'};
	$username =~ s/[^A-Za-z0-9\-\.]//g;
	if($username eq '') {
		print "Skipping entry: Invalid username\n";
		next;
	}
	my $filename = "$domain/$username.xml";
	my $template = 'default.tt';
	if(defined($vars->{'template'}) && "$vars->{'template'}" ne '') {
		$template = $vars->{'template'};
	}

	my $tt = Template->new({
		INCLUDE_PATH 	=> "$Bin/templates",
		OUTPUT_PATH 	=> "$Bin/output",
		INTERPOLATE  	=> 1
	}) || die "$Template::ERROR\n";

	print "Processing [$filename] using template [$template]\n";
	$tt->process($template, $vars, $filename) || die $tt->error(), "\n";
	$tt = undef;
}

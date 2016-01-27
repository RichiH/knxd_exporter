#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;


# Yes, this is global.
my %knx_group_address_value;

sub build_and_send_data {
	my $output;
	$output = "# TYPE knx_group_address_value gauge\n";
	$output .= "# HELP knx_group_address_value Value of a group address, no matter if from Write or Response\n";
	foreach my $group_address (sort keys %knx_group_address_value) {
		$output .= "knx_group_address_value{group_address=\"$group_address\"} $knx_group_address_value{$group_address}\n";
	}
	#print $output;
	
	my @curl = ('curl', '-X', 'POST', '--data-binary', $output, 'http://localhost:9091/metrics/job/knx_exporter');
	system (@curl);
}

sub main {
	open(GROUPSOCKETLISTEN, "unbuffer /usr/lib/knxd/groupsocketlisten ip:127.0.0.1 |") or die "Could not execute groupsocketlisten: $!";
	while ( defined( my $line = <GROUPSOCKETLISTEN> )  ) {
		chomp ($line);
		print localtime . " '$line' parsed into: ";

		#TODO handle Read which does not have $4 so it needs to be recorded as an action, not a return value
		next if $line =~ /^Read/;
		# One KNX actor Jalousieaktor '00 ' and 'FF '
		$line =~ /^(.+) from (.+) to (.+): (\w+)\s*$/;
		my ($action, $physical_address, $group_address, $value) = (lc($1), $2, $3, hex("0x$4"));
		print "'$action' '$physical_address' '$group_address' '$value' '$1' '$2' '$3' '$4'\n";
		$knx_group_address_value{$group_address} = $value;
		build_and_send_data();
		print "\n";
	}
	close GROUPSOCKETLISTEN;
}

main;

#! /usr/bin/perl

use strict;
use warnings;

open F, '<', 'base_mesh.svg'
    or die "Cannot open file for reading: $!\n";

while (<F>) {
  if (m/d="m ([-.0-9 ,]+) z"/) {
    my @points = split ' ', $1;
    print "mesh_cell([[",
        join("], [", @points),
        "]]);\n";
  }
}

close F;

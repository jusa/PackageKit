#!/usr/bin/perl
#
# Copyright (C) 2008 Aurelien Lefebvre <alefebvre@mandriva.com>
#
# Licensed under the GNU General Public License Version 2
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#

use strict;

use lib;
use File::Basename;

BEGIN {
  push @INC, dirname($0);
}

use URPM;
use urpm;
use urpm::args;
use urpm::media;
use urpm::select;

use urpmi_backend::open_db;
use urpmi_backend::tools;

use perl_packagekit::enums;
use perl_packagekit::prints;

# 3 arguments (filter, package id, recursive)
$#ARGV == 2 or exit 1;

my @filters = split(/;/, $ARGV[0]);
my @pkgids = split(/\|/, $ARGV[1]);
my $recursive_option = 0;

# We force the recursive option
$recursive_option = 1;

pk_print_status(PK_STATUS_ENUM_DEP_RESOLVE);

my $urpm = urpm->new_parse_cmdline;
urpm::media::configure($urpm);

my @pkgnames;
foreach (@pkgids) {
  my @pkgid = split(/;/, $_);
  push(@pkgnames, $pkgid[0]);
}
print join(" ", @pkgnames);
print "\n";
my %requested;
my $results = urpm::select::search_packages($urpm, \%requested, \@pkgnames,
  fuzzy => 0,
  caseinsensitive => 0,
  all => 0
);

$results or exit;

my $empty_db = new URPM;
my $state = {};
$urpm->resolve_requested($empty_db,
  $state,
  \%requested,
);

my $db = open_rpm_db();
$urpm->compute_installed_flags($db);

my %selected = %{$state->{selected}};
my @selected_keys = keys %selected;
my @depslist = @{$urpm->{depslist}};

foreach(sort {@depslist[$b]->flag_installed <=> @depslist[$a]->flag_installed} @selected_keys) {
  my $pkg = @depslist[$_];
  if($pkg->flag_installed) {
    next if(grep(/^${\FILTER_NOT_INSTALLED}$/, @filters));
    pk_print_package(INFO_INSTALLED, get_package_id($pkg), $pkg->summary);
  }
  else {
    next if(grep(/^${\FILTER_INSTALLED}$/, @filters));
    pk_print_package(INFO_AVAILABLE, get_package_id($pkg), $pkg->summary);
  }
}


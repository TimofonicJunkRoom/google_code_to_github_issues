#!/usr/bin/env perl

use v5.10;
use warnings;
use strict;

use utf8::all;
use YAML qw(Load Dump LoadFile DumpFile);
use Template::Toolkit::Simple;
use Encode qw(encode decode);

my $yaml = LoadFile(*STDIN);

foreach my $issue (@{$yaml->{issues}}) {
    # render issue
    say STDERR "issue: $issue->{issue}";
    my $data = 
	tt->path('templates')->data($issue)->post_chomp(0)->render('issue.mkdn');
# render encodes with utf8
    $data = decode("UTF-8", $data);
    say STDERR $data;
    $issue->{data} = $data;
}

DumpFile(*STDOUT, $yaml)

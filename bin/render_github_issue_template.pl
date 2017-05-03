#!/usr/bin/env perl

use v5.10;
use warnings;
use strict;

use Mojo::File;
use YAML qw(Load Dump LoadFile DumpFile);
use Encode qw(encode decode);
use Template::Toolkit::Simple;

my $yaml = LoadFile(*STDIN);

foreach my $issue (@{$yaml->{issues}}) {
    # render issue
    say STDERR "issue: $issue->{issue}";
    my $data = 
	tt->path('templates')->data($issue)->post_chomp(0)->render('issue.mkdn');
    say STDERR $data;
    $issue->{data} = $data;
}

DumpFile(*STDOUT, $yaml)

#!/usr/bin/env perl

use Net::GitHub::V3;

my $gh = Net::GitHub::V3->new(
  login => $ENV{GITHUB_USER},
  pass  => $ENV{GITHUB_PASS}
);

my $oauth = $gh->oauth;
my $o = $oauth->create_authorization( {
    scopes => ['user', 'public_repo', 'repo', 'gist'], # just ['public_repo']
    note   => 'test purpose',
} );
print $o->{token};

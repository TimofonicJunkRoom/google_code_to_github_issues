#!/usr/bin/env perl

use v5.10;
use warnings;
use strict;

use YAML qw(Load Dump LoadFile DumpFile);
use Encode qw(encode decode);
use Net::GitHub;
use Data::Dumper;
use Try::Tiny;


my $token = $ENV{GITHUB_TOKEN} or die "GITHUB_TOKEN required";
my $user  = 'libwww-perl';
my $repo  = 'WWW-Mechanize';
my $github = Net::GitHub->new(
    access_token => $token
);
$github->set_default_user_repo($user, $repo);
my $gh_issue = $github->issue;

#my $yaml = decode('UTF-8', LoadFile(*STDIN));
my $yaml = LoadFile(*STDIN);

my @issues = @{ $yaml->{issues}};

foreach my $issue (@issues) {
    my $num   = $issue->{issue} // '<undef>';
    my $title = $issue->{title};
    my $data  = $issue->{data};

    say STDERR "Working on issue num:$num";
    unless ($title && $data) {
        say STDERR "skipping.  title and data must be set";
	next;
    }
    if (my $new_issue = $issue->{new_issue}) {
        say STDERR "skipping.  Already uploaded as $new_issue";
        say STDERR "num:$num, new_issue:$new_issue, new_url:$issue->{new_url}";
	next;
    }
    my $url = post_issue($num, $title, $data);
 
    redo unless defined $url;

    $issue->{new_url}   = $url;

    my $new_issue = "unknown";
    if ($url =~ m,.*/(.*)$,) {
      $new_issue = $1;
      $issue->{new_issue} = $new_issue;
    }
    say STDERR "$num => $new_issue :: $url";
}


# post_issue($num, $title, $data)
sub post_issue {
    my ($num, $title, $data) = @_;
    my $response;
    try {
        $response = $gh_issue->create_issue({
            title => $title,
            body  => $data,
        });
        say STDERR "response succeeded";
    } catch {
        warn "caught error : $_";
        say STDERR "sleeping and retrying";
        sleep 60;
    };
    return unless defined $response;
    return $response->{url};
}

END: {
  say STDERR "dumping yaml";
  DumpFile(*STDOUT, $yaml)
}

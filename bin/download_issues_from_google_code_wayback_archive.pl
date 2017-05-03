#!/usr/bin/env perl

use strict;
use warnings;

use WWW::WebArchive::WaybackMachine;

my $url = "http://code.google.com/p/www-mechanize/issues/list";

# Download specific older wayback urls, since the most
# current versions 301 redirect to an empty page.

my @wayback_urls = (
    #"https://web.archive.org/web/20130510090410/$url",
    "https://web.archive.org/web/20150227111857/$url",
    "https://web.archive.org/web/20130510011416/http://code.google.com/p/www-mechanize/issues/list?num=100&start=100"
);

my $wayback = WWW::WebArchive::WaybackMachine->new(
    url     => $url,
    verbose => 1,
);

# make our own Mech to match the one internal to WWW::WA::WM.
my $ua = WWW::Mechanize->new();
$ua->agent_alias('Windows IE 6');
$ua->stack_depth(1);

my $file   = $url;
$file      =~ s,https?://,,;
my $dir    = './issues/';
my $domain = 'code.google.com';

for my $wayback_url (@wayback_urls) {
    $ua->get($wayback_url);
    my @links = $ua->find_all_links(
        tag        => "a",
        text_regex => qr/^\d+$/,
        url_regex  => qr/issues.detail/,
    );

    foreach my $link (@links) {
        printf ("text:%s url:%s\n", $link->text, $link->url);
        $wayback->mirror($ua, $link->url, $link->text, $dir, $domain);
    }
}

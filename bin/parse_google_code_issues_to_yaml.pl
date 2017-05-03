#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Mojo::DOM;
use Mojo::File;
use YAML qw(Dump);
use Encode qw(encode decode);

#my $base = "file://home/andrew/src/ZipRecruiter/WWW-Mechanize/code.google";
my $file = "2015/102";
my $base_issue_url = 'http://code.google.com/p/www-mechanize/issues/detail?id=';
my $base_issue_url_archive = 'https://web.archive.org/web/20150227111857/http://code.google.com/p/www-mechanize/issues/detail?id=';

sub main {
  my (@files) = @_;

  my @issues = map { parse_ticket_file($_) } @files;
  print encode('UTF-8', Dump(@issues));
}


sub _trim { $_[0] =~ s/\A\s*(.*?)\s*\z/$1/sm; }

sub parse_ticket_file {
  my $file = shift;

  my ($issue) = $file =~ m/(\d+)$/;
  my $issue_url   = $base_issue_url . $issue;
  my $archive_url = $base_issue_url_archive . $issue;

  my $path = Mojo::File->new($file);
  my $html = decode('UTF-8', $path->slurp());
  my $dom  = Mojo::DOM->new($html);

  my $header      = get_header($dom);
  my $description = get_description($dom);
  my @comments    = get_comments($dom);
  my $meta        = get_meta($dom);

  {
    issue       => $issue,
    url         => $issue_url,
    archive_url => $archive_url,
    description => $description,
    comments    => \@comments,
    meta        => $meta,
    title       => $header->{title},
  }
}

sub get_comments {
  my ($dom, $selector) = @_;
  $selector //= 'div.issuecomment';
  $dom->find($selector)->map(sub {parse_comment(@_)})->each;
}

sub _first_text_trim {
  my ($e, $selector) = @_;
  if (my $dom = $e->find($selector)) {
    my $value = $dom->first->text;
    _trim($value);
    return $value
  }
  return
}

sub parse_date {
  my ($e, $selector) = @_;
  $selector //= 'span.date';

  if (my $date_dom = $e->find($selector)) {
    $date_dom = $date_dom->first;
    my $date      = $date_dom->text;
    _trim($date);
    my $timestamp = $date_dom->attr('title');

    return {
      date      => $date,
      timestamp => $timestamp,
    }
  }
}

sub get_header { 
  my ($e, $selector) = @_;
  $selector //= '#issueheader';
  my $dom = $e->find($selector)->first;

  return unless $dom;

  parse_header($dom);

};

sub parse_header {
  my ($e) = @_;
  {
    title       => $e->at('span.h3')->text,
  }
}

sub get_description {
  my ($e, $selector) = @_;
  $selector //= 'div.issuedescription';
  my $description_dom = $e->find($selector)->first;
  return unless $description_dom;

  parse_description($description_dom);
}

sub parse_description {
  my ($e) = @_;

  {
    reporter    => $e->at('a.userlink')->text,
    description => $e->at('pre')->to_string,
    date        => parse_date($e),
  }
}

sub parse_comment {
  my ($e) = @_;

  my $author  = $e->at('a.userlink')->text;
  my $comment = $e->at('pre')->all_text;
  _trim($comment);

  my $date_dom = $e->at('span.date');
  my $date      = $date_dom->text;
  my $date_long = $date_dom->attr('title');
  _trim($date);

  my $inner;
  if (my $inner_dom = $e->at('div.box-inner')) {
    $inner = parse_inner($inner_dom)
  }

  {
    author      => $author,
    comment     => $comment,
    date        => $date,
    date_long   => $date_long,
    inner       => $inner,
  }
}


sub parse_inner {
  my ($e) = @_;

  my $inner = [];

  # let's remove the br first.
  $e->find('br')->each('remove');

  my @kids = $e->child_nodes->each();
  while (my ($_blank, $key, $value) = splice(@kids, 0, 3)) {
    next unless defined $value; #last iteration only matches $_blank
    $key   = $key->all_text;
    _trim($key);
    $key   =~ s/:$//;

    # value is raw text, so doesn't have a ->text or ->all_text method.
    $value = $value->to_string;
    _trim($value);
    push @$inner, {key => $key, value => $value };
  }
  return $inner;
}

sub get_meta {
  my ($e, $selector) = @_;
  $selector //= '#issuemeta > div';

  #$selector = 'td.issuemeta';

  my $meta_dom = $e->find($selector)->first;
  #say "meta_dom: <<\n" . $meta_dom->to_string . "\n>>";
  return unless $meta_dom;

  parse_meta($meta_dom);
}

sub parse_meta {
  my ($e) = @_;
  my $meta = {};

  # get key_values
  my $kv_selector = 'tr > th';  # we want all tr rows that have a th, so we'll take parent.
  my @kv_nodes = $e->find('tr > th')->map('parent')->each(sub {
    my $key = $_->at('th')->all_text;
    $key =~ s/:.$//;  # remove trailing :&nbsp;

    my $value = $_->at('td')->all_text;
    _trim($value);

    $meta->{$key} = $value;
  });

  # get labels:
  my $label_selector = 'td[colspan=2] a';  #td colspan=2
  my $labels = [];
  #my @label_doms = $e->find($label_selector)->each('to_string')->each;
  my @label_doms = $e->find($label_selector)->each( sub {
    my $value = $_->text;
    if (my $key_dom = $_->at('b') ){
      my $label = $key_dom->text;
      $label =~ s/-$//;
      $meta->{$label} = $value;
    } else {
      push @$labels, $value;
    }
  });
  $meta->{Labels} = $labels if @$labels;

  return $meta
}


my $doc = '
<div class="box-inner">
 
 <b>Summary:</b>
 WM: submit_form() with invalid input field throws a warning
 
 <br>
 
 <b>Labels:</b>
 WM
 
 <br>
 
 </div>
';



main (@ARGV);


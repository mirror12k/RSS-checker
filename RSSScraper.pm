#!/usr/bin/env perl
package RSSScraper;
use parent 'WWW::Mechanize';
use strict;
use warnings;

use feature 'say';

use HTML::TreeBuilder::XPath;
use XML::XPath;
use URI;


# <link rel="alternate" type="application/rss+xml" title="red|blue - RSS" href="http://www.redblue.team/feeds/posts/default?alt=rss" />



sub extract_rss_link {
	my ($self, $url) = @_;

	$self->get($url);

	my $xp = HTML::TreeBuilder::XPath->new;
	$xp->parse_content($self->content);

	my $link = $xp->findvalue('//link[@type="application/rss+xml"]/@href');
	return URI->new_abs($link, $self->uri) if $link ne '';
	return
}


sub main {
	my $ua =RSSScraper->new;
	say $ua->extract_rss_link('http://www.redblue.team/');
}

caller or main(@ARGV)

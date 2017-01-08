#!/usr/bin/env perl
package RSSScraper;
use parent 'WWW::Mechanize';
use strict;
use warnings;

use feature 'say';

use HTML::TreeBuilder::XPath;
use XML::XPath;
use URI;

use Data::Dumper;



# <link rel="alternate" type="application/rss+xml" title="red|blue - RSS" href="http://www.redblue.team/feeds/posts/default?alt=rss" />



sub get_rss_link {
	my ($self, $url) = @_;

	$self->get($url);

	my $xp = HTML::TreeBuilder::XPath->new;
	$xp->parse_content($self->content);

	my $link = $xp->findvalue('//link[@type="application/rss+xml"]/@href');
	return URI->new_abs($link, $self->uri) if $link ne '';
	return
}

sub get_rss_data {
	my ($self, $rss_url) = @_;

	$self->get($rss_url);

	my %data;
	my $xp = XML::XPath->new(xml => $self->content);
	$data{title} = '' . $xp->findvalue('/rss/channel/title');
	$data{description} = '' . $xp->findvalue('/rss/channel/description');
	$data{link} = '' . $xp->findvalue('/rss/channel/link');
	$data{managing_editor} = '' . $xp->findvalue('/rss/channel/managingEditor');
	$data{build_date} = '' . $xp->findvalue('/rss/channel/lastBuildDate');
	foreach my $category ($xp->findnodes('/rss/channel/category')) {
		push @{$data{categories}}, '' . $category->findvalue('.');
	}

	foreach my $item ($xp->findnodes('/rss/channel/item')) {
		my %item_data;
		$item_data{title} = '' . $item->findvalue('./title');
		$item_data{description} = '' . $item->findvalue('./description');
		$item_data{link} = '' . $item->findvalue('./link');
		$item_data{author} = '' . $item->findvalue('./author');
		$item_data{pub_date} = '' . $item->findvalue('./pubDate');

		push @{$data{items}}, \%item_data;
	}

	return \%data
}


sub main {
	my $ua =RSSScraper->new;
	my $link = $ua->get_rss_link('http://www.redblue.team/');
	say $link;
	say Dumper $ua->get_rss_data($link);
}

caller or main(@ARGV)

#!/usr/bin/env perl
package RSSScraper;
use parent 'WWW::Mechanize';
use strict;
use warnings;

use feature 'say';

use HTML::TreeBuilder::XPath;
use XML::XPath;
use URI;
use DateTime;

# use Data::Dumper;



# <link rel="alternate" type="application/rss+xml" title="red|blue - RSS" href="http://www.redblue.team/feeds/posts/default?alt=rss" />



sub get_rss_link {
	my ($self, $url) = @_;

	$self->get($url);

	my $xp = HTML::TreeBuilder::XPath->new;
	$xp->parse_content($self->content);

	return map URI->new_abs($_, $self->uri), map $_->findvalue('./@href'), $xp->findnodes('//link[@type="application/rss+xml"]');
	# my $link = $xp->findvalue('//link[@type="application/rss+xml"]/@href');
	# return URI->new_abs($link, $self->uri) if $link ne '';
	# return
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
	$data{build_date_parsed} = parse_datetime($data{build_date}) // die "failed to parse datetime from $rss_url: $data{build_date}" if $data{build_date} ne '';
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
		$item_data{pub_date_parsed} = parse_datetime ($item_data{pub_date}) // die "failed to parse datetime from $rss_url: $item_data{pub_date}";
		foreach my $category ($item->findnodes('./category')) {
			push @{$data{categories}}, '' . $category->findvalue('.');
		}

		push @{$data{items}}, \%item_data;
	}

	return \%data
}

our %month_string_to_number = qw/
	jan 1
	feb 2
	mar 3
	apr 4
	may 5
	jun 6
	jul 7
	aug 8
	sep 9
	oct 10
	nov 11
	dec 12
/;
# parses a datetime stamp as specified by rfc822, because that's what rss 2.0 spec says it's using
# rfc822 specifies 2 digits for the year, but that doesn't really work for the dates that i'm seeing, so i'm deviating a little
sub parse_datetime {
	my ($datetime) = @_;

	return unless $datetime =~ /(?:(mon|tue|wed|thu|fri|sat|sun), )?(\d{1,2}) (jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec) (\d{4,5}) (\d{2}):(\d{2})(?::(\d{2}))? (UT|GMT|EST|EDT|CST|CDT|MST|MDT|PST|PDT|[a-z]|[\+\-]\d{4})/i;

	my %data = (
		day => $2,
		month => $month_string_to_number{lc $3},
		year => $4,
		hour => $5,
		minute => $6,
		second => $7,
		timezone => $8,
	);
	return DateTime->new(
		year       => $data{year},
		month      => $data{month},
		day        => $data{day},
		hour       => $data{hour},
		minute     => $data{month},
		second     => $data{second} // 0,
		# nanosecond => 500000000,
		time_zone  => $data{timezone},
	)
}


sub main {
	my ($url) = @_;
	die "url required" unless $url;
	my $ua =RSSScraper->new;
	say foreach $ua->get_rss_link($url);
	# say $link;
	# say Dumper $ua->get_rss_data($link);
}

caller or main(@ARGV)

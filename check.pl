#!/usr/bin/perl
use strict;
use warnings;

use feature 'say';

use DateTime;

use RSSScraper;



my @rss_urls = qw#
http://www.redblue.team/feeds/posts/default?alt=rss
#;



my $days = shift // die 'number of days required';
my $checkdate = DateTime->now( time_zone => 'floating' )->subtract( days => $days );

my $scraper = RSSScraper->new;
foreach my $url (@rss_urls) {
	my $data = $scraper->get_rss_data($url);
	my $count = 0;
	foreach my $item (@{$data->{items}}) {
		if ($item->{pub_date_parsed} >= $checkdate) {
			say "[[$data->{title}]]" if $count++ == 0;
			say "\t$count: $item->{title} ($item->{pub_date})";
			say "\t\t[[$item->{link}]]";
		}
	}
}

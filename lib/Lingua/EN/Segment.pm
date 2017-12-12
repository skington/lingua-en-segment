package Lingua::EN::Segment;

use strict;
use warnings;
no warnings 'uninitialized';

our $VERSION = '0.001';
$VERSION = eval $VERSION;

=head1 NAME

Lingua::EN::Segment - split English-language domain names etc. into words

=head1 SYNOPSIS

 my $segmenter = Lingua::EN::Segment->new;
 for my $domain (<>) {
     chomp $domain;
     my @words = $segmenter->segment_string($domain);
     print "$domain: ", join(', ', @words), "\n";
 }

=head1 DESCRIPTION

Sometimes you have a string that to a human eye is clearly made up of many
words glommed together without spaces or hyphens. This module uses some mild
cunning and a large list of known words from Google to try and work out how
the string should be split into words.

=head2 new

 Out: $segmenter

Returns a Lingua::EN::Segment object.

=cut

sub new {
	my $package = shift;
	return bless {} => ref($package) || $package;
}

=head2 segment

 In: $unsegmented_string
 Out: @words

Supplied with an unsegmented string - e.g. a domain name - returns a list of
words that are most statistically likely to be the words that make up this
string.

=cut

sub segment {
	my ($self, $unsegmented_string) = @_;

	### TODO: actually do something with this.
	return $unsegmented_string;
}

=head1 ACKNOWLEDGEMENTS

This code is based on
L<chapter 14 of Peter Norvig's book Beautiful Data|http://norvig.com/ngrams/>.

=cut

1;

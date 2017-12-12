package Lingua::EN::Segment;

use strict;
use warnings;
no warnings 'uninitialized';

our $VERSION = '0.001';
$VERSION = eval $VERSION;

use Carp;
use English qw(-no_match_vars);
use File::ShareDir;
use List::Util qw(min);

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
	my ($package, %args) = @_;

	return bless \%args => ref($package) || $package;
}

=head2 dist_dir

 Out: $dist_dir

Returns the name of the directory where distribution-specific files are
installed.

=cut

sub dist_dir {
	my ($self) = @_;

	$self->{dist_dir} ||= File::ShareDir::dist_dir('Lingua-EN-Segment');
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

	# Divide this string into all the possible segments.
	my @segments = $self->_find_all_possible_segments($unsegmented_string);
	return if !@segments;
	
	### FIXME: bah, just throw all of this work away and return something.
	return $unsegmented_string;
}

sub _find_all_possible_segments {
	my ($self, $unsegmented_string) = @_;

	return if !length($unsegmented_string);

	my @segments;
	# Go through looking for possible words. The longest word in the corpus
	# that is actually a word (as opposed to come-ons stuck together)
	# is currently 31 characters.
	for my $prefix_length (1..min(length($unsegmented_string), 31)) {
		my $prefix = substr($unsegmented_string, 0, $prefix_length);
		if (my $suffix = substr($unsegmented_string, $prefix_length)) {
			my @subsegments = $self->_find_all_possible_segments($suffix);
			push @segments, map { [$prefix, @$_] } @subsegments;
		} else {
			push @segments, [$prefix];
		}
	}
	return @segments;
}

=head2 unigrams

 Out: \%unigrams

Returns a hashref of word => likelihood to appear in Google's huge list of
words that they got off the Internet. The higher the likelihood, the more
likely that this is a genuine regularly-used word, rather than an obscure
word or a typo.

=cut

sub unigrams {
	my ($self) = @_;

	return $self->{unigrams} ||= do {
        my $unigram_filename = $self->dist_dir . '/count_1w.txt';
        open(my $fh, '<', $unigram_filename)
            or croak "Couldn't read unigrams from $unigram_filename: $OS_ERROR";
		my %likelihood;
		while (<$fh>) {
			chomp;
			my ($word, $score) = split(/\t+/, $_);
			$likelihood{$word} = $score;
		}
		\%likelihood;
	};
}

=head1 ACKNOWLEDGEMENTS

This code is based on
L<chapter 14 of Peter Norvig's book Beautiful Data|http://norvig.com/ngrams/>.

=cut

1;

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
use Memoize;

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

    return if !length($unsegmented_string);
    my @segments = $self->_segment($unsegmented_string, '<S>');
    return map { $_->{word} } @segments;
}

memoize('_segment', NORMALIZER => sub { "$_[1] $_[2]" });
sub _segment {
    my ($self, $unsegmented_string, $previous_word) = @_;

    # Work out all the possible words at the beginning of this string.
    # (31 characters is the longest word in our corpus that is genuinely
    # a real word, and not other words glommed together.)
    # Then run this whole algorithm on the remainder, thus effectively
    # working on the string from both the front and the back.
    my @possible_segments;
    for my $prefix_length (1..min(length($unsegmented_string), 31)) {
        my $current_word = substr($unsegmented_string, 0, $prefix_length);
        my $current_segment = {
            word        => $current_word,
            probability => $self->_probability($current_word, $previous_word),
        };
        push @possible_segments,
            [
            $current_segment,
            $self->_segment(substr($unsegmented_string, $prefix_length),
                $current_word)
            ];
    }
    return if !@possible_segments;

    # We can now work out the cumulative probability of all of these segments.
    return @{
        (
            map  { $_->[1] }
            sort { $b->[0] <=> $a->[0] }
            map {
                my $segments = $_;
                [$self->_cumulative_probability($segments), $segments]
            } @possible_segments
        )[0]
    };
}

sub _cumulative_probability {
    my ($self, $segments) = @_;

    my $overall_probability = 1;
    for my $segment (@$segments) {
        $overall_probability *= $segment->{probability};
    }
    return $overall_probability;
}

memoize('_probability', NORMALIZER => sub { "$_[1] $_[2]" });
sub _probability {
    my ($self, $word, $previous_word) = @_;
    
    my $biword = $previous_word . ' ' . $word;
    if (exists $self->bigrams->{$biword}) {
        return $self->bigrams->{$biword}
            / $self->_unigram_probability($previous_word);
    } else {
        return $self->_unigram_probability($word);
    }
}

sub _unigram_probability {
    my ($self, $word) = @_;

    return $self->unigrams->{$word} || $self->unigrams->{__unknown__}->($word);
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

    return $self->{unigrams} ||= $self->_read_file('count_1w.txt');
}

=head2 bigrams

 Out: \%bigrams

As L<unigrams>, but returns a lookup table of "word1 word2" => likelihood
for combinations of words.

=cut

sub bigrams {
    my ($self) = @_;

    return $self->{bigrams} ||= $self->_read_file('count_2w.txt');
}

sub _read_file {
    my ($self, $filename) = @_;

    my $full_filename = $self->dist_dir . '/' . $filename;
    open(my $fh, '<', $full_filename)
        or croak "Couldn't read unigrams from $full_filename: $OS_ERROR";
    my (%count, $total_count);
    while (<$fh>) {
        chomp;
        my ($word, $count) = split(/\t+/, $_);
        $count{$word} = $count;
        $total_count += $count;
    }
    my %likelihood = map { $_ => $count{$_} / $total_count } %count;
    $likelihood{__unknown__} = sub {
        my $word = shift;
        return 10 / ($total_count * 10**length($word));
    };
    return \%likelihood;
}


=head1 ACKNOWLEDGEMENTS

This code is based on
L<chapter 14 of Peter Norvig's book Beautiful Data|http://norvig.com/ngrams/>.

=cut

1;

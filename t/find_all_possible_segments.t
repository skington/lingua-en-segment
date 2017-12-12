#!/usr/bin/env perl
# Make sure that we split up words correctly.

use strict;
use warnings;
no warnings 'uninitialized';

use Test::More;

# Pull in the segmenter library.
use_ok('Lingua::EN::Segment');
my $segmenter = Lingua::EN::Segment->new;
isa_ok($segmenter, 'Lingua::EN::Segment');

# We split up words into segments correctly.
is_deeply([$segmenter->_find_all_possible_segments('')], [],
    q{Trivially, the empty string doesn't split});
is_deeply([$segmenter->_find_all_possible_segments('a')], ['a'],
    'Trivially, one-letter strings only split one way');
is_deeply(
    [$segmenter->_find_all_possible_segments('ab')],
    [['a', 'b'], ['ab']],
    'Two-letter strings: the first element is always populated'
);
is_deeply(
    [$segmenter->_find_all_possible_segments('abc')],
    [['a', 'b', 'c'], ['a', 'bc'], ['abc'], ['ab', 'c']],
    'Three-letter strings split in a number of ways'
);

# And we're done.
done_testing();

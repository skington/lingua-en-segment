#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'uninitialized';

use Test::More;

use_ok('Lingua::EN::Segment');
my $segmenter = Lingua::EN::Segment->new;

done_testing();

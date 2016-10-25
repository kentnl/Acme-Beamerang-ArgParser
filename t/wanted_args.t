use strict;
use warnings;

use Test::More;
use Acme::Beamerang::ArgParser;

is_deeply(
    Acme::Beamerang::ArgParser->new->parse( '--unary', '--arged=foo',
        'command', '--command', 'args' )->args,
    [],
    "No filter has no results"
);

is_deeply(
    Acme::Beamerang::ArgParser->new( filter => ['unary'] )
      ->parse( '--unary', '--arged=foo', 'command', '--command', 'args' )->args,
    [ ['unary'] ],
    "Cherry picked unary arg"
);

is_deeply(
    Acme::Beamerang::ArgParser->new( filter => ['arged'] )
      ->parse( '--unary', '--arged=foo', 'command', '--command', 'args' )->args,
    [ [ 'arged', 'foo' ] ],
    "Cherry picked parameterized arg"
);

is_deeply(
    Acme::Beamerang::ArgParser->new( filter => ['command'] )
      ->parse( '--unary', '--arged=foo', 'command', '--command', 'args' )->args,
    [],
    "Ignored post-command arg that matches"
);

done_testing;


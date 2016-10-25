use strict;
use warnings;

use Test::More;
use Acme::Beamerang::ArgParser;

is_deeply(
    Acme::Beamerang::ArgParser->new->parse( '--unary', '--arged=foo',
        'command', '--command', 'args' )->extra_args,
    [ '--unary', '--arged=foo', 'command', '--command', 'args' ],
    "No filter is a passthrough"
);

is_deeply(
    Acme::Beamerang::ArgParser->new( filter => ['unary'] )
      ->parse( '--unary', '--arged=foo', 'command', '--command', 'args' )
      ->extra_args,
    [ '--arged=foo', 'command', '--command', 'args' ],
    "Cherry picked unary arg"
);

is_deeply(
    Acme::Beamerang::ArgParser->new( filter => ['arged'] )
      ->parse( '--unary', '--arged=foo', 'command', '--command', 'args' )
      ->extra_args,
    [ '--unary', 'command', '--command', 'args' ],
    "Cherry picked parameterized arg"
);

is_deeply(
    Acme::Beamerang::ArgParser->new( filter => ['command'] )
      ->parse( '--unary', '--arged=foo', 'command', '--command', 'args' )
      ->extra_args,
    [ '--unary', '--arged=foo', 'command', '--command', 'args' ],
    "Ignored post-command arg that matches"
);

done_testing;


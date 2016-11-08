use strict;
use warnings;

use Test::Needs + {
    'Capture::Tiny' => '0',
    'Path::Tiny'    => '0.014',
};

use Test::More tests => 18;
use Path::Tiny qw/ path /;
use Capture::Tiny qw/ capture /;
use Acme::Beamerang::ArgParser;

sub defconst {
    no strict;
    ${ *{ __PACKAGE__ . '::' } }{ $_[0] } = \"$_[1]";
}

BEGIN {
    defconst SCRIPT => path(__FILE__)->parent(3)->child('examples/basic.pl')
      ->absolute->realpath->stringify;

    defconst INCDIR =>
      path( $INC{'Acme/Beamerang/ArgParser.pm'} )->absolute->parent(3)
      ->realpath->stringify;
}

{
    my ( $out, $err, $result ) = capture {
        system( $^X, '-I' . INCDIR, SCRIPT );
    };
    note $out, $err, $result;
    cmp_ok( $result, '==', 256, "plain: errored" )
      and like( $err, qr/No command specified/, "plain: Right error message" )
      and like( $out, qr/Commands:/sm,          "plain: Help shown" );
}

{
    my ( $out, $err, $result ) = capture {
        system( $^X, '-I' . INCDIR, SCRIPT, "bogus" );
    };
    note $out, $err, $result;
    cmp_ok( $result, '==', 256, "bogus: errored" )
      and like( $err, qr/Unknown command bogus/, "bogus: Right error message" )
      and like( $out, qr/Commands:/sm,           "bogus: Help shown" );
}

{
    my ( $out, $err, $result ) = capture {
        system( $^X, '-I' . INCDIR, SCRIPT, "--param" );
    };
    note $out, $err, $result;
    cmp_ok( $result, '==', 256, "badparam: errored" )
      and like(
        $err,
        qr/Unknown App parameters.*--param/,
        "badparam: Right error message"
      ) and like( $out, qr/Commands:/sm, "badparam: Help shown" );
}

{
    my ( $out, $err, $result ) = capture {
        system( $^X, '-I' . INCDIR, SCRIPT, "help" );
    };
    note $out, $err, $result;
    cmp_ok( $result, '==', 256, "cmd_help: errored" )
      and like( $err, qr/\A\s*\z/,     "cmd_help: No error message" )
      and like( $out, qr/Commands:/sm, "cmd_help: Help shown" );
}

{
    my ( $out, $err, $result ) = capture {
        system( $^X, '-I' . INCDIR, SCRIPT, "version" );
    };
    note $out, $err, $result;
    cmp_ok( $result, '==', 0, "cmd_version: not-errored" )
      and like( $err, qr/\A\s*\z/,             "cmd_version: No error message" )
      and like( $out, qr/::ArgParser:\s*\d/sm, "cmd_version: version shown" );
}

{
    my ( $out, $err, $result ) = capture {
        system( $^X, '-I' . INCDIR,
            SCRIPT, "echo", "--misc", "--", "command", "--args" );
    };
    note $out, $err, $result;
    cmp_ok( $result, '==', 0, "cmd_echo: not-errored" )
      and like( $err, qr/\A\s*\z/, "cmd_echo: No error message" )
      and
      like( $out, qr/\A--misc -- command --args/sm, "cmd_echo: args passed" );
}

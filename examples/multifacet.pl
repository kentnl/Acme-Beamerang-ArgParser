#!perl
use strict;
use warnings;

BaseApp->new->run(@ARGV);

{

    package BaseApp;

    use Acme::Beamerang::ArgParser;

    sub new { bless {}, $_[0] }

    sub run {
        my $self = shift;
        my $cfg =
          Acme::Beamerang::ArgParser->new( filter => [qw( D dispatcher )] )
          ->parse(@_);
        my $state = {};
        my $rules = {
            dispatcher => sub {
                die "D/dispatcher expects a value"
                  unless defined $_[0] and length $_[0];
                die "D/dispatcher cannot be set twice"
                  if exists $state->{dispatcher};
                $state->{dispatcher} = $_[0];
            }
        };
        $rules->{D} = $rules->{dispatcher};

        for my $arg ( @{ $cfg->args } ) {
            my ( $arg, $value ) = @{$arg};
            $rules->{$arg}->($value);
        }

        $state->{dispatcher} = 'A' unless exists $state->{dispatcher};

        my $dispatch_class = "BaseApp::Dispatch::" . $state->{dispatcher};

        $dispatch_class->new()->run( @{ $cfg->extra_args } );
    }
}
{

    package BaseApp::Dispatch::A;

    sub new { bless {}, $_[0] }

    sub run {
        my $self = shift;
        my $cfg  = Acme::Beamerang::ArgParser->new()->parse(@_);

        if ( @{ $cfg->unknown_args } ) {
            warn sprintf "Unknown App parameters: <%s>\n",
              join q[> <], @{ $cfg->unknown_args };
            exit $self->cmd_help();
        }

        if ( not defined $cfg->command ) {
            warn "No command specified\n";
            exit $self->cmd_help();
        }

        my $cmd_sub = $self->can( 'cmd_' . $cfg->command );

        if ( not $cmd_sub ) {
            warn sprintf "Unknown command %s\n", $cfg->command;
            exit $self->cmd_help();
        }

        $self->$cmd_sub( @{ $cfg->unparsed_args } );
    }

    sub commands {
        {
            help    => "Show This Help",
            version => "Show Version",
            echo    => "Parrot arguments to STDOUT",
        };
    }

    sub cmd_help {
        my ( $self, @args ) = @_;
        my $commands = $self->commands;
        if ( not @args ) {
            print "$0 --args [COMMAND] --command-args\n";
            print "\n";
            print "Commands:\n";
            my ( $max_command, ) = reverse sort map length, keys %$commands;
            for my $command ( sort keys %{$commands} ) {
                printf "    %*s - %s\n", $max_command, $command,
                  $commands->{$command};
            }
            exit 1;
        }
    }

    sub cmd_version {
        printf "%s: %s\n", 'Acme::Beamerang::ArgParser',
          $Acme::Beamerang::ArgParser::VERSION;
        exit 0;
    }

    sub cmd_echo {
        shift;
        print join q[ ], @_;
        print "\n";
        exit 0;
    }

}
{

    package BaseApp::Dispatch::B;

    our @ISA;
    BEGIN { @ISA = ('BaseApp::Dispatch::A') }

    sub commands {
        my $result = next::method(@_);
        $result->{twinkle} = "Waste CPU Printing for a while";
        return $result;
    }

    sub cmd_twinkle {
        $|++;
        for ( 0 .. 10 ) {
            for my $i (qw( / - \ | )) {
                print "$i";
                select( undef, undef, undef, 0.01 );
                print "\b";
            }
        }
        print "\n";
        exit 0;
    }
}

=head1 ABOUT

This example demonstrates the use of nested fragment parsing, including
"Stealing" parameters for a higher component.

This seems like an odd pattern until you consider you want an app with a user
defined list of commands loaded from a config file,  or you want a config file
to define the loader that provides the commands, B<AND> you want that loader to
have its own arguments, as well as the commands having arguments.

Ok, maybe that's not very common.

Though to see it in action:

  perl -Ilib examples/multifacet.pl -D=A help
  perl -Ilib examples/multifacet.pl -D=B help
  perl -Ilib examples/multifacet.pl -D=A twinkle # error
  perl -Ilib examples/multifacet.pl -D=B twinkle # spinner

#!perl
use strict;
use warnings;

use Acme::Beamerang::ArgParser;

my $ap = Acme::Beamerang::ArgParser->new();

my $cfg = $ap->parse(@ARGV);

if ( @{ $cfg->unknown_args } ) {
    warn sprintf "Unknown App parameters: <%s>\n",
      join q[> <], @{ $cfg->unknown_args };
    exit __PACKAGE__->cmd_help();
}

if ( not defined $cfg->command ) {
    warn "No command specified\n";
    exit __PACKAGE__->cmd_help();
}

my $cmd_sub = __PACKAGE__->can( 'cmd_' . $cfg->command );

if ( not $cmd_sub ) {
    warn sprintf "Unknown command %s\n", $cfg->command;
    exit __PACKAGE__->cmd_help();
}

exit __PACKAGE__->$cmd_sub( @{ $cfg->unparsed_args } );

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
    my ($self) = shift;
    print join q[ ], @_;
    print "\n";
    exit 0;
}

=head1 ABOUT

This example demonstrates how one can build a very low level "command"
dispatcher using this tool.

Its important to note that the library does nothing fancy itself, it just
conceptualises arguments to the application in a way that is easier to reason
about, while giving one maximum flexibility to implement dispatch/arg handling
as they see fit.

This doesn't leverage advanced features like nested arg extraction, and simply
demonstrates command-name extraction.


use 5.006;    # our
use strict;
use warnings;

package Acme::Beamerang::ArgParser;

our $VERSION = '0.001000';

use Acme::Beamerang::Logger;
use namespace::clean;

# ABSTRACT: A partial command-let oriented args parser

# AUTHORITY
#
sub new {
    my ( $class, @args ) = @_;
    my $instance = bless { ref $args[0] ? %{ $args[0] } : @args }, $class;
    $instance->{filter} = [] unless exists $instance->{filter};
    return $instance;
}

sub parse {
    my ( $self, @orig_args ) = @_;
    my (@unparsed_args) = @orig_args;

    my %matchables = map {
      #<<<
      1 == length $_ ? ( "-$_"  => $_ )
                     : ( "--$_" => $_ )
      #>>>
    } @{ $self->{filter} };

    DlogS_debug { "Starting argument parse for $_" } caller;
    Dlog_trace { "Extracting Arguments: $_" } sort keys %matchables;

    my ( @args, $command, @unknown_args );
    while (@unparsed_args) {

        my $item = shift @unparsed_args;

        if ( $item !~ /\A[-]/ ) {
            Dlog_trace { "- Found Command: $_" } $item;
            $command = $item;
            last;
        }

        my ( $opt, $val ) = split /=/, $item, 2;

        if ( not exists $matchables{$opt} ) {
            Dlog_trace { "- Ignoring: $_" } $item;
            push @unknown_args, $item;
            next;
        }
        Dlog_trace { "- Found Argument: $_" } $matchables{$opt};
        Dlog_trace { " - Argument value: $_" } $val if defined $val;
        push @args, [ $matchables{$opt}, ($val) x defined $val ];
    }

    my $stash = {
        args          => \@args,
        command       => $command,
        orig_args     => \@orig_args,
        unknown_args  => \@unknown_args,
        unparsed_args => \@unparsed_args,
    };

    Dlog_debug { "Parsed Commands: $_" } $stash;
    return bless $stash, 'Acme::Beamerang::ArgParser::Cfg';
}
{
    package    #
      Acme::Beamerang::ArgParser::Cfg;

    sub args          { $_[0]->{args} }
    sub command       { $_[0]->{command} }
    sub orig_args     { $_[0]->{orig_args} }
    sub unknown_args  { $_[0]->{unknown_args} }
    sub unparsed_args { $_[0]->{unparsed_args} }

    sub extra_args {
        [
            @{ $_[0]->{unknown_args} },
            ( $_[0]->{command} ) x defined $_[0]->{command},
            @{ $_[0]->{unparsed_args} }
        ];
    }
}

1;

=head1 NAME

Acme::Beamerang::ArgParser - A partial commandlet oriented args parser

=head1 SYNOPSIS

  use Acme::Beamerang::ArgParser;
  use My::Sub::Dispatcher::Thing;

  my $state = {};
  my $opts  = {
    output => sub { defined $_[0] ? $state->{output} = $_[0] : die "--output expects a parameter" },
    quiet  => sub { defined $_[0] ? $state->{quiet}  = $_[0] : $state->{quiet}++ },
  };
  $opts->{o} = $opts->{output};
  $opts->{q} = $opts->{quiet};

  # Note: Only defines which pre-command "args" are "ours" for filtering.
  # and ropes the rest off for children to parse themselves.
  my $cfg = Acme::Beamerang::ArgParser->new( filter => [keys %opts] )->parse( @ARGV );
  for my $argument ( @{$cfg->args} ) {
    my ( $name, $value ) = @{ $argument };
    $opts->{$name}->( $value );
  }

  my $worker = My::Sub::Dispatcher::Thing->new( %$state );
  $worker->exec( @{ $cfg->extra_args } );

=head1 DESCRIPTION

C<B<Acme::Beamerang::ArgParser>> is an experimental argument parsing utility to
simplify some of the essential flow control needed when building a multi-level
C<-cmd> style argument parser.

The general priniciple is to not actually implement anything specific to
argument validation and dispatch, and to leave that up to the user, while
focusing on determining the I<associations> of arguments and the I<ownership>
of arguments, in order to allow composed command lines where the root node is
blind to what their child nodes expect.

=head1 ANATOMY OF MULTI LEVEL COMMANDS

  app [APP AND APP FACET ARGS] command [COMMAND ARGS]

C<app> Reads its arguments up to the first non-argument, C<command>.

Elements of C<[APP AND APP FACET ARGS]> that it recognizes due to the filter
rule it takes posession of, and hides them from any composed in facets.

Any elements of C<[APP AND APP FACET ARGS]> that C<app> does not recognize it
assumes will be handled by child facets, or will otherwise be handled to be
"excess" by the consuming code.

C<command> and C<COMMAND ARGS> are captured verbatim and not processed in any
way.

=head1 APP AND FACET ARGS

All C<app> level and C<facet> level arguments need to be in one of the
following forms in order to work as intended.

  -u
  --unary
  -o=argument
  --option=argument

Split style parameters are unsupported:

  # NOT POSSIBLE as it would think the command to be "argument"
  app --option argument command --commandarg

This is required to be able to parse out facet arguments without knowing what
that facet expects those arguments to be.

For example, imagine an application as follows:

  app --verbose --dispatcher legacy --size 10 command

Where C<size> and C<verbose> are arguments that only the dispatcher called
C<legacy> understood, and that dispatcher is loaded lazily.

As far as C<app> is concerned, it only knows about the C<dispatcher> argument.

Without the tight-binding of C<=>, the logic would have to assume strange
things, eventually culminating in C<--verbose> having an argument of
C<--dispatcher> and the command being C<legacy> (LOL!), or C<--size> not
supporting arguments, and the command being C<10> (LOL!)

And this design choice is considered an important axiom of this approach.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 LICENSE

This software is copyright (c) 2016 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.


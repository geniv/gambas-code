# Copyright (C) 2002-03  Stephane Galland <galland@arakhne.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

=pod

=head1 NAME

PhpDocGen::Parser::Scanner - An abstract scanner for extracted source blocks

=head1 SYNOPSYS

use PhpDocGen::Parser::Scanner ;

my $scan = PhpDocGen::Parser::StateMachine->new(
                       transitions,
                       initial_state,
                       final_states
                       ) ;

=head1 DESCRIPTION

PhpDocGen::Parser::Scanner is a Perl module, which is a
state machine which reads a input stream. This is an
abstract scanner, i.e. it is not specific to a language
such as PHP, HTML...

=head1 GETTING STARTED

=head2 Initialization

To start a scanner, say something like this:

    use PhpDocGen::Parser::Scanner;

    my $sm = PhpDocGen::Parser::StateMachine->new(
                       { '0' => [ { callback => 'myfunc',
		                    pattern => 'a+',
				    state => '1',
		                  },
				  { state => '0' },
				],
			 '1' => { state => '0',
			        },
		       },
		       '0',
		       [ '1' ]
                       ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * transitions (hash ref)

describes the states of this machine. It must be an
associative array in which the keys are the name of
each states, and the associated values describe the
states with an array of transitions or with only
one transition. A transition is defined as an
associative array in which the following keys are
recognized:

=over

=item * state (string)

is the name of the state on which the machine must be
after this transition. B<This value is required.>

=item * pattern (string)

is a regular expression that describe the selection
condition needed to do this translation. B<This
value is optional>. But, only once transition
is able to not defined the pattern. This special
transition is the default (if no other transition
could be selected).

=item * callback (string)

is the name (not the reference) to a function that
must be called each time this transition was selected.
B<This value is optional>.

=item * merge (boolean)

if true and the state does not changed, the recognized
token will be merged to the previous token.
B<This value is optional>.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Scanner.pm itself.

=over

=cut

package PhpDocGen::Parser::Scanner;

@ISA = ('PhpDocGen::Parser::StateMachine');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;
use File::Basename ;

use PhpDocGen::Parser::StateMachine ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the scanner
my $VERSION = "0.2" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$$)  {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $parent = ref($proto) && $proto ;

  my $self ;
  if ( $parent ) {
    %{$self} = %{$parent} ;
  }
  else {
    $self = $class->SUPER::new( $_[0], $_[1], $_[2] ) ;
    $self->{'LINENO'} = 0 ;
  }
  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Scanning functions
#
#------------------------------------------------------

=pod

=item * scan()

Reads a input stream. Replies if the state machine is
in a final state.
Takes 1 arg:

=over

=item * filename (string)

is the name of the file from which the tokens must
be extracted.

=back

=cut
sub scan($)  {
  my $self = shift ;

  $self->{'LINENO'} = 0 ;
  $self->resetstatemachine() ;

  if ( ( $_[0] ) && ( -f $_[0] ) ) {
    local *SOURCEFILE ;
    open( *SOURCEFILE, "< $_[0]" )
      or PhpDocGen::General::Error::syserr( "unable to open $_[0]: $!" ) ;

    while ( my $line = <SOURCEFILE> ) {
      $self->{'LINENO'} ++ ;
      if ( $line !~ /^(\n|\r|\s)$/ ) {
	while ( $line ) {
	  $line = $self->changestatefrom( $line ) ;
	}
      }
    }

    close( *SOURCEFILE )
      or PhpDocGen::General::Error::syserr( "unable to close $_[0]: $!" ) ;

    $self->changestateforEOF() ;

  }

  PhpDocGen::General::Verbose::three( join( '',
					    "\t",
					    $self->{'LINENO'},
					    " line",
					    ($self->{'LINENO'}>1)?"s":"",
					    "\n" ) ) ;
  return $self->isfinalstate() ;
}

1;
__END__

=back

=head1 COPYRIGHT

(c) Copyright 2002-03 Stéphane Galland <galland@arakhne.org>, under GPL.

=head1 AUTHORS

=over

=item *

Conceived and initially developed by Stéphane Galland E<lt>galland@arakhne.orgE<gt>.

=back

=head1 SEE ALSO

phpdocgen.pl

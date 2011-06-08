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

PhpDocGen::Generator::Lang - A Language support for the generators

=head1 SYNOPSYS

use PhpDocGen::Generator::Lang ;

my $gen = PhpDocGen::Generator::Lang->new( name, defs ) ;

=head1 DESCRIPTION

PhpDocGen::Generator::Lang is a Perl module, which proposes
a generic language support for all the generators.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use PhpDocGen::Generator::Lang;

    my $gen = PhpDocGen::Generator::Lang->new( 'English',
					       { 'toto' => 'This is toto' } ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * name (string)

is the name of the current language.

=item * defs (hash)

contains the definitions of the language strings.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Lang.pm itself.

=over

=cut

package PhpDocGen::Generator::Lang;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;

use Carp ;

use PhpDocGen::General::Error ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of language support
my $VERSION = "0.1" ;

# Language definitions
my %LANG_DEFS = ( 'I18N_LANG_STATIC' => "static",
		  'I18N_LANG_PROTECTED' => "protected",
		  'I18N_LANG_PRIVATE' => "private",
		  'I18N_LANG_VOID' => "void",
		  'I18N_LANG_CLASS' => "class",
		  'I18N_LANG_EXTENDS' => "extends",
		) ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$)  {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = { 'defs' => $_[1] || {},
	       'name' => $_[0] || 'unknow',
	     } ;
  foreach my $key (keys %LANG_DEFS) {
    $self->{'defs'}->{$key} = $LANG_DEFS{$key} ;
  }
  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Getters
#
#------------------------------------------------------

=pod

=item * get()

Replies the specified string according to the language.
Takes at least 1 arg:

=over

=item * id (string)

is the id of the string.

=item * param1 (string)

is a string which must replace the string "#1" in the language definition.

=item * param2 (string)

is a string which must replace the string "#2" in the language definition.

=item ...

=back

=cut
sub get($)  {
  my $self = shift ;
  my $id = shift || confess( 'you must supply the id' ) ;
  my $str = ( ( exists $self->{'defs'}{$id} ) ?
	      $self->{'defs'}{$id} : '' ) ;
  PhpDocGen::General::Error::syserr( "the string id '$id' is not defined ".
				     "for the current language" ) unless $str ;
  if ( @_ ) {
    for(my $i=0; $i<=$#_; $i++ ) {
      my $j = $i+1 ;
      $str =~ s/\#$j/$_[$i]/g ;
    }
  }
  return $str ;
}

=pod

=item * getname()

Replies the name of the current language.

=cut
sub getname()  {
  my $self = shift ;
  return $self->{'name'} ;
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

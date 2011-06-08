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

PhpDocGen::General::Parsing - General parsing definitions

=head1 DESCRIPTION

PhpDocGen::General::Parsing is a Perl module, which permits to support
some general parsing functions.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Parsing.pm itself.

=over

=cut

package PhpDocGen::General::Parsing;

@ISA = ('Exporter');
@EXPORT = qw( &extract_param );
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the parsing functions
my $VERSION = "0.2" ;

#------------------------------------------------------
#
# Parameter parsing functions
#
#------------------------------------------------------

=pod

=item * extract_param()

Replies the n-th parameter from the specified string.
Takes 3 args:

=over

=item * index (integer)

is an I<integer> which corresponds to the location of
the parameter in the string.

=item * str (string)

is a I<string> which corresponds to the string from
which the parameter must be extracted.

=item * multiword (boolean)

is a I<boolean> which must be true if the
parameter allows more than one word.

=back

=cut
sub extract_param($$$) {
  my $counter=$_[0] || 1;
  my $params=$_[1] || '';
  my $multiword=$_[2];
  my $p="" ;
  $params =~ s/\s+$//s ;
  while ( $counter > 0 ) {
    $params =~ s/^\s+//s ;
    # Gets first param
    if ( $params =~ /^\{([^\}]*)\}(.*)/s ) {
      $p = $1 ;
      $params = $2 ;
    }
    elsif ( $params =~ /^([^ \t\r\n]*)(.*)/s ) {
      $p = $1 ;
      $params = $2 ;
    }
    else {
      $p = "" ;
    }
    $counter -- ;
  }
  # Replies
  if ( $multiword ) {
    $p = "$p $params" ;
  }
  $p =~ s/^\s+//s ;
  $p =~ s/\s+$//s ;
  return $p ;
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

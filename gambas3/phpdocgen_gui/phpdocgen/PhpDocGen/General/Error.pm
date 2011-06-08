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

PhpDocGen::General::Error - Error functions

=head1 DESCRIPTION

PhpDocGen::General::Error is a Perl module, which proposes
a set of functions to manage the errors.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Error.pm itself.

=over

=cut

package PhpDocGen::General::Error;

@ISA = ('Exporter');
@EXPORT = qw( &warm &err &warningcount &invalidlink
              &syserr &syswarm &printwarningcount
	      &debugflag &debug );
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use Data::Dumper ;

use PhpDocGen::General::Verbose ;
use PhpDocGen::General::Misc ;
use PhpDocGen::General::PHP ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the error functions
my $VERSION = "0.3" ;

# The quantity of warning encounted during the generation
my $WARNING_COUNT = 0 ;

# Indicates that the warnings are considered as errors
my $WARNING_HAS_ERROR = 0 ;

# Indicates if the debug mode is on
my $DEBUG_MODE = 0 ;

#------------------------------------------------------
#
# Debugging
#
#------------------------------------------------------

=pod

=item * debugflag()

Sets or replies the debugging flag.
Takes 1 arg:

=over

=item * flag (optional boolean)

=back

=cut
sub debugflag {
  $DEBUG_MODE = $_[0] if ( @_ ) ;
  return $DEBUG_MODE ;
}

=pod

=item * debugflag()

Sets or replies the debugging flag.
Takes 1 arg:

=over

=item * texts (array)

=back

=cut
sub debug {
  if ( $DEBUG_MODE ) {
    die( Data::Dumper::Dumper(@_) ) ;
  }
}

#------------------------------------------------------
#
# Warning getters/setters
#
#------------------------------------------------------

=pod

=item * warningcount()

Replies the quantity of warnings.

=cut
sub warningcount() {
  return $WARNING_COUNT ;
}

=pod

=item * setwarningaserror()

Sets that the warnings will be considered as errors.

=cut
sub setwarningaserror() {
  $WARNING_HAS_ERROR = 1 ;
}

=pod

=item * unsetwarningaserror()

Sets that the warnings will not be considered as errors.

=cut
sub unsetwarningaserror() {
  $WARNING_HAS_ERROR = 0 ;
}

#------------------------------------------------------
#
# Error reporting
#
#------------------------------------------------------

=pod

=item * syserr()

Displays a system error and stop.
Takes 1 arg:

=over

=item * message (string)

is the error message to display.

=back

=cut
sub syserr($) {
  my $msg = $_[0] || '-- error message not given --' ;
  $msg =~ s/\n+$// ;
  die( "Error: $msg\n" ) ;
}

=pod

=item * syswarm()

Displays a system warning.
Takes 1 arg:

=over

=item * message (string)

is the warning message to display.

=back

=cut
sub syswarm($) {
  my $msg = $_[0] || '-- error message not given --' ;
  if ( ! $WARNING_HAS_ERROR ) {
    $msg =~ s/\n+$// ;
    print STDERR "Warning: $msg\n" ;
    $WARNING_COUNT ++ ;
  }
  else {
    syserr( $msg ) ;
  }
}

=pod

=item * printwarningcount()

Displays the count of warnings.

=cut
sub printwarningcount() {
  if ( ( PhpDocGen::General::Verbose::currentlevel() ) &&
       ( $WARNING_COUNT > 0 ) ) {
    print STDERR "$WARNING_COUNT warning".(($WARNING_COUNT>1)?"s":"")."\n" ;
  }
}

=pod

=item * err()

Displays an error and stop.
Takes 3 args:

=over

=item * message (string)

is the error message to display.

=item * file (string)

is the name of the file in which the error occurs.

=item * line (integer)

is the line where the error occurs.

=back

=cut
sub err($$$) {
  my $msg = $_[0] || '-- error message not given --' ;
  my $file = $_[1] ;
  my $line = $_[2] ;
  if ( ! $line ) {
    $line = 0 ;
  }
  printwarningcount() ;
  $msg =~ s/\n+$// ;
  die( "Error".
        (($file)?
        (" ($file".(($line>0)?
		    ":$line":"").")"): "").
        ": $msg\n" ) ;
}

=pod

=item * warm()

Displays a warning.
Takes 3 args:

=over

=item * message (string)

is the warning message to display.

=item * file (string)

is the name of the file in which the warning occurs.

=item * line (integer)

is the line where the warning occurs.

=back

=cut
sub warm($$$) {
  my $msg = $_[0] || '-- error message not given --' ;
  my $file = $_[1] ;
  my $line = $_[2] ;
  if ( ! $line ) {
    $line = 0 ;
  }
  if ( ! $WARNING_HAS_ERROR ) {
    if ( PhpDocGen::General::Verbose::currentlevel() ) {
      $msg =~ s/\n+$// ;
      print STDERR "Warning".
	           (($file)?
	            (" ($file".(($line>0)?
		       ":$line":"").")"): "").
		          ": $msg\n" ;
    }
    $WARNING_COUNT ++ ;
  }
  else {
    err( $msg, $file, $line ) ;
  }
}

=pod

=item * invalidlink()

Reports a warning about an invalid link.
Takes 5 args:

=over

=item * object (string)

is the object name you try to link.

=item * comment (string)

is the comment attached to the link.

=item * message (string)

is the error message.

=item * php (boolean)

is true is the PHP predefined variables must be supported.

=item * location (string)

is the location in the input stream where the link error
occurs.

=back

=cut
sub invalidlink($$$$$) {
  if ( ( ! $_[3] ) ||
       ( ! is_predefined_global( $_[0] ) ) ) {
    PhpDocGen::General::Error::warm( $_[2],
				     extract_file_from_location( $_[4] ),
				     extract_line_from_location( $_[4] ) ) ;
  }
  return $_[1] ;
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

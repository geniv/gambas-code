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

PhpDocGen::General::Misc - Miscellaneous definitions

=head1 DESCRIPTION

PhpDocGen::General::Misc is a Perl module, which proposes
a set of miscellaneous functions.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Misc.pm itself.

=over

=cut

package PhpDocGen::General::Misc;

@ISA = ('Exporter');
@EXPORT = qw( &strinarray &mkdir_rec &add_value_entry 
	      &isemptyhash &buildtree &removefctbraces
	      &addfctbraces &extract_file_from_location
	      &extract_line_from_location &formathashkeyname
	      &formatfctkeyname &isarray &ishash &isemptyarray
	      &hashcount &is_valid_regex &tohumanreadable
              &readfileastext &valueinhash &posinarray
	      &is_valid_location &to_th &formatvarkeyname
	      &formatvarname &unformatvarname );
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use File::Spec ;;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the misc functions
my $VERSION = "0.5" ;

#------------------------------------------------------
#
# General purpose functions
#
#------------------------------------------------------

=pod

=item * to_th()

=cut
sub to_th($) {
  my $n = $_[0] || 0 ;
  my $r = ( $n || 0 ) % 10 ;
  if ( $r == 1 ) {
    return $n."st" ;
  }
  elsif ( $r == 2 ) {
    return $n."nd" ;
  }
  elsif ( $r == 3 ) {
    return $n."rd" ;
  }
  else {
    return $n."th" ;
  }
}

=pod

=item * strinarray()

Replies if the specified value is in an array.
Takes 2 args:

=over

=item * str (string)

is the string to search.

=item * array (array ref)

is the array in which the string will be searched.

=back

=cut
sub strinarray($$) {
  return 0 unless $_[1] ;
  my $str = $_[0] || '' ;
  foreach my $g (@{$_[1]}) {
    if ( $g eq $str ) {
      return 1 ;
    }
  }
  return 0 ;
}

=pod

=item * posinarray()

Replies the location of the specified string inside the array
Takes 2 args:

=over

=item * str (string)

is the string to search.

=item * array (array ref)

is the array in which the string will be searched.

=back

=cut
sub posinarray($$) {
  return -1 unless $_[1] ;
  my $str = $_[0] || '' ;
  for(my $i=0; $i<=$#{$_[1]}; $i++) {
    if ( $_[1][$i] eq $str ) {
      return $i ;
    }
  }
  return -1 ;
}

=pod

=item * valueinhash()

Replies if the specified value is a value of thez associative array.
Takes 2 args:

=over

=item * str (string)

is the string to search.

=item * hash (hash ref)

is the associative array in which the string will be searched.

=back

=cut
sub valueinhash($$) {
  return 0 unless $_[1] ;
  my $str = $_[0] || '' ;
  foreach my $k (keys %{$_[1]}) {
    if ( ( exists $_[1]->{$k} ) &&
	 ( $_[1]->{$k} ) &&
         ( $_[1]->{$k} eq $str ) ) {
      return 1 ;
    }
  }
  return 0 ;
}

=pod

=item * mkdir_rec()

Creates recursively a directory.
Takes 1 arg:

=over

=item * path (string)

is the name of the directory to create.

=back

=cut
sub mkdir_rec($) {
  return 0 unless $_[0] ;
  # Fix proposed by joezespak@yahoo.com:
  # platform-independant paths
  my $param = File::Spec->rel2abs($_[0]) ;
  my @parts = File::Spec->splitdir( $param ) ;
  my $current = "" ;
  foreach my $r (@parts) {
    # Fix by joezespak@yahoo.com:
    # support of absolute paths
    if ( $r ) {
      # Fix by emilis@gildija.lt:
      # for Windows platform support which
      # crashes with the previous version
      if ( $current ) {
	$current = File::Spec->catdir($current,$r) ;
      }
      else {
	$current = $r ;
      }
    }
    else {
      $current = File::Spec->rootdir() ;
    }
    if ( ! -d "$current" ) {
      if ( ! mkdir( "$current", 0777 ) ) {
	return 0 ;
      }
    }
  }
  return 1 ;
}

=pod

=item * isemptyhash()

Replies if the specified hashtable was empty.
Takes 1 arg:

=over

=item * hash (hash ref)

is the hash table.

=back

=cut
sub isemptyhash($) {
  if ( ! $_[0] ) {
    return 1 ;
  }
  else {
    my @k = keys %{$_[0]} ;
    return ($#k < 0) ;
  }
}

=pod

=item * isemptyarray()

Replies if the specified array was empty.
Takes 1 arg:

=over

=item * array (array ref)

is the array.

=back

=cut
sub isemptyarray($) {
  if ( ! $_[0] ) {
    return 1 ;
  }
  else {
    return ($#{$_[0]} < 0) ;
  }
}

=pod

=item * hashcount()

Replies the count of keys inside the specified hash.
Takes 1 arg:

=over

=item * hash (hash ref)

is the hash table.

=back

=cut
sub hashcount($) {
  if ( ! $_[0] ) {
    return 0 ;
  }
  else {
    my @k = keys %{$_[0]} ;
    return int(@k) ;
  }
}

=pod

=item * ishash()

Replies if the specified struct is an hash.
Takes 1 arg:

=over

=item * object

is the object to test.

=back

=cut
sub ishash {
  return 0 unless @_ ;
  my $r = ref( $_[0] ) ;
  return ( $r eq "HASH" ) ;
}

=pod

=item * isarray()

Replies if the specified struct is an array.
Takes 1 arg:

=over

=item * object

is the object to test.

=back

=cut
sub isarray {
  return 0 unless @_ ;
  my $r = ref( $_[0] ) ;
  return ( $r eq "ARRAY" ) ;
}

=pod

=item * add_value_entry()

Adds an entry to the specified hashtable. if the
the value is not defined, adds as a scalar, else
adds as a array entry.
Takes 3 args:

=over

=item * hash (hash ref)

is the hashtable.

=item * key (string)

is the key in which the value must be put.

=item * value

is the value.

=back

=cut
sub add_value_entry($$$) {
  return unless ishash($_[0]) ;
  my $key = $_[1] || '' ;
  if ( exists $_[0]{$key} ) {
    my $old = $_[0]{$key} ;
    my $r = ref( $old ) ;
    if ( ! ( $r eq "ARRAY" ) ) {
      delete $_[0]{$key} ;
      push( @{$_[0]{$key}}, $old ) ;
    }
    push( @{$_[0]{$key}}, $_[2] ) ;
  }
  else {
    $_[0]{$key} = $_[2] ;
  }
}

=pod

=item * buildtree()

Updates the specified hashtable by
adding the value at the specified keys.
Takes 2 args:

=over

=item * hash (hash ref)

is the tree.

=item * keys (array ref)

is the array of the keys.

=item * name (string)

is the classname.

=back

=cut
sub buildtree($$$) {
  return unless ( $_[0] && ishash($_[0]) && 
		  $_[1] && isarray($_[1]) ) ;
  my $newkey = $_[2] || '' ;
  my $ref = $_[0] ;
  foreach my $key (@{$_[1]}) {
    if ( ! ( exists $$ref{$key} ) ) {
      my %hash = () ;
      $$ref{$key} = \%hash ;
    }
    $ref = $$ref{$key} ;
  }
  if ( ! ( exists $$ref{$newkey} ) ) {
    $$ref{$newkey} = { } ;
  }
}

=pod

=item * removefctbraces()

Replies a string without "()" at the end.
Takes 1 arg:

=over

=item * str (string)

is a string.

=back

=cut
sub removefctbraces($) {
  my $name = $_[0] || '' ;
  if ( $name ) {
    $name =~ s/\s*\(\s*\)\s*$// ;
  }
  return $name ;
}

=pod

=item * addfctbraces()

Replies a string with "()" at the end.
Takes 1 arg:

=over

=item * str (string)

is a string.

=back

=cut
sub addfctbraces($) {
  my $name = removefctbraces( $_[0] ) ;
  return $name."()" ;
}

=pod

=item * extract_file_from_location()

Replies the file from the specified location.
Takes 1 arg:

=over

=item * location (string)

is the location inside the input stream.

=back

=cut
sub extract_file_from_location($) {
  return '' unless $_[0] ;
  my $loc = $_[0] ;
  my $file = "" ;
  $loc =~ s/^(.*):[0-9]*/$file=$1;/e ;
  return $file ;
}

=pod

=item * extract_line_from_location()

Replies the line number from the specified location.
Takes 1 arg:

=over

=item * location (string)

is the location inside the input stream.

=back

=cut
sub extract_line_from_location($) {
  return 0 unless $_[0] ;
  my $loc = $_[0] ;
  my $line = 0 ;
  $loc =~ s/^.*:([0-9]*)/$line=$1;/e ;
  if ( $line > 0 ) {
    return $line ;
  }
  else {
    return 0 ;
  }
}

=pod

=item * is_valid_location()

Replies if the specified string is a valid location
Takes 1 arg:

=over

=item * text (string)

=back

=cut
sub is_valid_location($) {
  return 0 unless $_[0] ;
  return ( $_[0] =~ /^.*:[0-9]*/ ) ;
}

#------------------------------------------------------
#
# Formating of the name of the tokens
#
#------------------------------------------------------

=pod

=item * formathashkeyname()

Replies a formatted hash key name.
Takes 1 arg:

=over

=item * name (string)

is the string to format.

=back

=cut
sub formathashkeyname($) {
  return lc( $_[0] || '' ) ;
}

=pod

=item * formatvarkeyname()

Replies a formatted hash key name for a variable.
Takes 1 arg:

=over

=item * name (string)

is the string to format.

=back

=cut
sub formatvarkeyname($) {
  my $key = formathashkeyname($_[0] || '') ;
  if ( ( $key ) && ( $key !~ /^\$/ ) ) {
    $key = "\$$key" ;
  }
  return $key ;
}

=pod

=item * formatvarname()

Replies a formatted name for a variable (ie with
a dollar sign in the begining).
Takes 1 arg:

=over

=item * name (string)

is the string to format.

=back

=cut
sub formatvarname($) {
  my $name = $_[0] || '' ;
  if ( ( $name ) && ( $name !~ /^\$/ ) ) {
    $name = "\$$name" ;
  }
  return $name ;
}

=pod

=item * unformatvarname()

Replies an unformatted name for a variable (ie without
a dollar sign in the begining).
Takes 1 arg:

=over

=item * name (string)

is the string to format.

=back

=cut
sub unformatvarname($) {
  my $name = $_[0] || '' ;
  $name =~ s/^\$// ;
  return $name ;
}

=pod

=item * formatfctkeyname()

Replies a formatted hash key name for functions.
Takes 1 arg:

=over

=item * name (string)

is the string to format.

=back

=cut
sub formatfctkeyname($) {
  return addfctbraces( formathashkeyname( $_[0] ) ) ;
}

=pod

=item * is_valid_regex()

Replies if the specified regular expression
was well-formed.
Takes 1 arg:

=over

=item * regex (string)

is the regular expression to verify.

=back

=cut
sub is_valid_regex($) {
  return 0 unless $_[0] ;
  return eval { "" =~ /$_[0]/; 1; } || 0 ;
}

=pod

=item * tohumanreadable()

Replies a string string that corresponds to
the human readable form of the specified string.
Takes 1 arg:

=over

=item * string (string)

is the string to convert.

=back

=cut
sub tohumanreadable($) {
  my $string = $_[0] || '' ;
  $string =~ s/\n/\\n/g;
  $string =~ s/\r/\\r/g;
  $string =~ s/\t/\\t/g;
  $string =~ s/\"/\\\"/g;
  $string =~ s/\'/\\\'/g;
  return $string ;
}

=pod

=item * readfileastext()

Replies the content of a file as a string
Takes 1 arg:

=over

=item * filename (string)

is the name of the file to read

=back

=cut
sub readfileastext($) {
  if ( ( $_[0] ) && ( -f $_[0] ) ) {
    my $string = "" ;
    open( READFILE_FID, "< $_[0]" )
      or PhpDocGen::General::Error::syserr( "unable to open $_[0]: $!" ) ;
    while ( my $line = <READFILE_FID> ) {
      $string .= $line ;
    }
    close( READFILE_FID )
      or PhpDocGen::General::Error::syserr( "unable to close $_[0]: $!" ) ;
    return $string ;
  }
  return '' ;
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

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

package PhpDocGen::Release;
@ISA = ('Exporter');
@EXPORT = qw( &getVersionNumber &getVersionDate &getBugReportURL
	      &getAuthorName &getAuthorEmail &getMainURL ) ;
@EXPORT_OK = qw();
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
my $VERSION = "0.1" ;

#------------------------------------------------------
#
# DEFINITIONS
#
#------------------------------------------------------

my $PHPDOCGEN_VERSION      = '0.17-rc3' ;
my $PHPDOCGEN_DATE         = '2003/08/08' ;
my $PHPDOCGEN_BUG_URL      = 'http://www.arakhne.org/bugtrack/' ;
my $PHPDOCGEN_AUTHOR       = 'Stéphane GALLAND' ;
my $PHPDOCGEN_AUTHOR_EMAIL = 'galland@arakhne.prg' ;
my $PHPDOCGEN_URL          = 'http://www.arakhne.org/tools/phpdocgen/' ;

#------------------------------------------------------
#
# Functions
#
#------------------------------------------------------

sub getVersionNumber() {
  return $PHPDOCGEN_VERSION ;
}

sub getVersionDate() {
  return $PHPDOCGEN_DATE ;
}

sub getBugReportURL() {
  return $PHPDOCGEN_BUG_URL ;
}

sub getAuthorName() {
  return $PHPDOCGEN_AUTHOR ;
}

sub getAuthorEmail() {
  return $PHPDOCGEN_AUTHOR_EMAIL ;
}

sub getMainURL() {
  return $PHPDOCGEN_URL ;
}

1;
__END__

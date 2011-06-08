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

PhpDocGen::General::PHP - PHP support definitions

=head1 DESCRIPTION

PhpDocGen::General::PHP is a Perl module, which permits to support
some PHP definitions.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in PHP.pm itself.

=over

=cut

package PhpDocGen::General::PHP;

@ISA = ('Exporter');
@EXPORT = qw(&is_predefined_global &is_reserved_php_keyword);
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use PhpDocGen::General::Misc ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the PHP support functions
my $VERSION = "0.3" ;

# Predefined variables from the PHP server.
my @PREDEFINED_PHP_GLOBALS = ( 'GATEWAY_INTERFACE', 'SERVER_NAME',
			       'SERVER_SOFTWARE', 'SERVER_PROTOCOL',
			       'REQUEST_METHOD', 'QUERY_STRING',
			       'DOCUMENT_ROOT', 'HTTP_ACCEPT',
			       'HTTP_ACCEPT_CHARSET', 'HTTP_ENCODING',
			       'HTTP_ACCEPT_LANGUAGE', 'HTTP_CONNECTION',
			       'HTTP_HOST', 'HTTP_REFERER', 'HTTP_USER_AGENT',
			       'REMOTE_ADDR', 'REMOTE_PORT', 'SCRIPT_FILENAME',
			       'SERVER_ADMIN', 'SERVER_PORT', 'SERVER_SIGNATURE',
			       'PATH_TRANSLATED', 'SCRIPT_NAME', 'REQUEST_URI',
			       'argv', 'argc', 'PHP_SELF', 'HTTP_COOKIE_VARS',
			       'HTTP_GET_VARS', 'HTTP_POST_VARS',
			       '__FILE__', '__LINE__', 'PHP_VERSION',
			       'PHP_OS', 'TRUE', 'FALSE', 'E_ERROR',
			       'E_WARNING', 'E_PARSE', 'E_NOTICE',
			     ) ;

# Reserved keywords for PHP
my @RESERVED_PHP_WORDS = ( 'class', 'new',  'if',
			   'while', 'else', 'repeat',
			   'until', 'include', 'echo',
			   'print', 'unless',
			   'join', 'global', 'exit',
			   'return', 'die', 'extends',
			   'function', 'break', 'continue',
			   'switch', 'foreach', 'for',
			   'default', 'case', 'eval',
			   'define', 'var', 'include_once' ) ;

#------------------------------------------------------
#
# Predefined PHP variables support
#
#------------------------------------------------------

=pod

=item * is_predefined_global()

Replies if the specified string is the name
of a predefined PHP variable.
Takes 1 arg:

=over

=item * name (string)

is a I<string> which correspond to the name to test.

=back

=cut
sub is_predefined_global($) {
  return 0 unless $_[0] ;
  return strinarray( uc( $_[0] ), \@PREDEFINED_PHP_GLOBALS ) ;
}

=pod

=item * is_reserved_php_keyword()

Replies if the specified string is the name
of a reserved PHP keyword.
Takes 1 arg:

=over

=item * name (string)

is a I<string> which correspond to the name to test.

=back

=cut
sub is_reserved_php_keyword($) {
  return 0 unless $_[0] ;
  return strinarray( lc( $_[0] ), \@RESERVED_PHP_WORDS ) ;
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

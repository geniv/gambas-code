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

PhpDocGen::Generator::Html::Theme - A theme for the LaTeX generator

=head1 SYNOPSYS

use PhpDocGen::Generator::LaTeX::JavaDocTheme ;

my $gen = PhpDocGen::Generator::LaTeX::JavaDocTheme->new( phpdocgen,
                                                  target,
                                                  title,
                                                  phpgen,
                                                  webgen ) ;

=head1 DESCRIPTION

PhpDocGen::Generator::LaTeX::JavaDocTheme is a Perl module, which proposes
a documentation theme for the HTML generator of phpdocgen.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use PhpDocGen::Generator::LaTeX::JavaDocTheme;

    my $gen = PhpDocGen::Generator::LaTeX::JavaDocTheme->new( { 'VERSION' => '0.11' },
						      './phpdoc',
						      'Title',
						      1, 1 ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * phpdocgen (hash)

contains some data about phpdocgen.

=item * target (string)

The directory in which the documentation must be put.

=item * title (string)

is the title of the documentation.

=item * phpgen (boolean)

indicates if the PHP doc was generated

=item * webgen (boolean)

indicates if the WEB doc was generated

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Html.pm itself.

=over

=cut

package PhpDocGen::Generator::LaTeX::JavaDocTheme;

@ISA = ('PhpDocGen::Generator::LaTeX::Theme');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;

use Carp ;
use File::Spec ;

use PhpDocGen::Generator::LaTeX::Theme ;
use PhpDocGen::General::Verbose ;
use PhpDocGen::General::Error ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of theme
my $VERSION = "0.1" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$$$$)  {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = $class->SUPER::new( @_ ) ;
  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Preamble API
#
#------------------------------------------------------

=pod

=item * get_document_class()

Replies the name of the LaTeX document class.

=cut
sub get_document_class()  {
  my $self = shift ;
  return 'book' ;
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

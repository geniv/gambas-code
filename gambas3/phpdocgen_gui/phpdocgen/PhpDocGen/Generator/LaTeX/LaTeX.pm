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

PhpDocGen::Generator::LaTeX::LaTeX - A LaTeX generator

=head1 SYNOPSYS

use PhpDocGen::Generator::LaTeX::LaTeX ;

my $gen = PhpDocGen::Generator::LaTeX::LaTeX->new(
                      documentation_content,
                      long_title,
                      short_title,
                      output_path,
                      theme_name,
                      php_definition ) ;

=head1 DESCRIPTION

PhpDocGen::Generator::LaTeX::LaTeX is a Perl module, which proposes
a documentation generator for LaTeX documents.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use PhpDocGen::Generator::LaTeX::LaTeX;

    my $gen = PhpDocGen::Generator::LaTeX::LaTeX->new(
                $content,
		"This is the documentation",
		"Documentation",
		"/tmp/phpdoc/",
                { 'version' => "0.5.2",
                  'date' => "2002-08-12",
                  'author' => "Somebody",
                  'email' => "somebody@somewhere",
                  'url' => "http://somewhere/",
                  'bug' => "http://somewhere/",
                },
                { 'sources' => 0,
                  'php' => 1,
		  'web' => 0,
		},
		"JavaDoc",
                "/usr/lib/phpdocgen" ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * content (hash ref)

The content of the documentation inside an hashtable.

=item * long_title (string)

The title of the documentation in a long format.

=item * short_title (string)

The title of the documentation in brief format.

=item * output (string)

The directory or the file in which the documentation
must be put.

=item * phpdef (hash ref)

An hashtable that contains the description of
the phpdocgen script.

=item * generation_behavior (hash)

Indicates what kind of generation must be do. Each key corresponds to
a boolean value :

=over

=item I<sources> generation of the highligthed source files

=item I<php> generation of the documentation about the PHP functions, classes...

=item I<web> generation of the documentation about the web modules and web pages

=back

=item * theme (string)

is the name of the theme to use

=item * PHPdir (string)

this is the absolute path to the directory where the root of the
modules is

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in LaTeX.pm itself.

=over

=cut

package PhpDocGen::Generator::LaTeX::LaTeX;

@ISA = ('PhpDocGen::Generator::Generator');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;

use Carp ;
use File::Spec ;
use File::Copy ;

use PhpDocGen::Generator::Generator ;
use PhpDocGen::General::Error ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of LaTeX generator
my $VERSION = "0.2" ;

# Translation table
my %TRANS_TBL = ( '~' => '{\\textasciitilde}', #modifier letter tilde accent
		  '^' => '{\\textasciicircum}', #modifier letter circumflex accent
		  '{' => '\\{', # opening brace
		  '}' => '\\}', # closing brace
		  '$' => '\\$', # dollar sign
		  '&' => '\\&', #ampersand sign
		  '£' => '{\\pounds}', #pound sign
		  '¤' => '{\\textcurrency}', #currency sign
		  '§' => '{\\S}', #section sign
		  '°' => '{\\textdegree}', #degree sign
		  '²' => '{\\ensuremath{^{2}}}', #superscript two = superscript digit two = squared
		  'µ' => '{\\ensuremath{\\mu}}', #micro sign
		  'À' => '{\\`{A}}', #latin capital letter A with grave = latin capital letter A grave
		  'Á' => '{\\\'{A}}', #latin capital letter A with acute
		  'Â' => '{\\^{A}}', #latin capital letter A with circumflex
		  'Ã' => '{\\~{A}}', #latin capital letter A with tilde
		  'Ä' => '{\\"{A}}', #latin capital letter A with diaeresis
		  'Å' => '{\\r{A}}', #latin capital letter A with ring above = latin capital letter A ring
		  'Æ' => '{\\AE}', #latin capital letter AE = latin capital ligature AE
		  'Ç' => '{\\c{C}}', #latin capital letter C with cedilla
		  'È' => '{\\`{E}}', #latin capital letter E with grave
		  'É' => '{\\\'{E}}', #latin capital letter E with acute
		  'Ê' => '{\\^{E}}', #latin capital letter E with circumflex
		  'Ë' => '{\\"{E}}', #latin capital letter E with diaeresis
		  'Ì' => '{\\`{I}}', #latin capital letter I with grave
		  'Í' => '{\\\'{I}}', #latin capital letter I with acute
		  'Î' => '{\\^{I}}', #latin capital letter I with circumflex
		  'Ï' => '{\\"{I}}', #latin capital letter I with diaeresis
		  'Ñ' => '{\\~{N}}', #latin capital letter N with tilde
		  'Ò' => '{\\`{O}}', #latin capital letter O with grave
		  'Ó' => '{\\\'{O}}', #latin capital letter O with acute
		  'Ô' => '{\\^{O}}', #latin capital letter O with circumflex
		  'Õ' => '{\\~{O}}', #latin capital letter O with tilde
		  'Ö' => '{\\"{O}}', #latin capital letter O with diaeresis
		  'Ø' => '{\\O}', #latin capital letter O with stroke = latin capital letter O slash
		  'Ù' => '{\\`{U}}', #latin capital letter U with grave
		  'Ú' => '{\\\'{U}}', #latin capital letter U with acute
		  'Û' => '{\\^{U}}', #latin capital letter U with circumflex
		  'Ü' => '{\\"{U}}', #latin capital letter U with diaeresis
		  'Ý' => '{\\\'{Y}}', #latin capital letter Y with acute
		  'à' => '{\\`{a}}', #latin small letter a with grave = latin small letter a grave
		  'á' => '{\\\'{a}}', #latin small letter a with acute
		  'â' => '{\\^{a}}', #latin small letter a with circumflex
		  'ã' => '{\\~{a}}', #latin small letter a with tilde
		  'ä' => '{\\"{a}}', #latin small letter a with diaeresis
		  'å' => '{\\r{a}}', #latin small letter a with ring above = latin small letter a ring
		  'æ' => '{\\ae}', #latin small letter ae = latin small ligature ae
		  'ç' => '{\\c{c}}', #latin small letter c with cedilla
		  'è' => '{\\`{e}}', #latin small letter e with grave
		  'é' => '{\\\'{e}}', #latin small letter e with acute
		  'ê' => '{\\^{e}}', #latin small letter e with circumflex
		  'ë' => '{\\"{e}}', #latin small letter e with diaeresis
		  'ì' => '{\\`{\\i}}', #latin small letter i with grave
		  'í' => '{\\\'{\\i}}', #latin small letter i with acute
		  'î' => '{\\^{\\i}}', #latin small letter i with circumflex
		  'ï' => '{\\"{\\i}}', #latin small letter i with diaeresis
		  'ñ' => '{\\~{n}}', #latin small letter n with tilde
		  'ò' => '{\\`{o}}', #latin small letter o with grave
		  'ó' => '{\\\'{o}}', #latin small letter o with acute
		  'ô' => '{\\^{o}}', #latin small letter o with circumflex
		  'õ' => '{\\~{o}}', #latin small letter o with tilde
		  'ö' => '{\\"{o}}', #latin small letter o with diaeresis
		  'ø' => '{\\o}', #latin small letter o with stroke = latin small letter o slash
		  'ù' => '{\\`{u}}', #latin small letter u with grave
		  'ú' => '{\\\'{u}}', #latin small letter u with acute
		  'û' => '{\\^{u}}', #latin small letter u with circumflex
		  'ü' => '{\\"{u}}', #latin small letter u with diaeresis
		  'ý' => '{\\\'{y}}', #latin small letter y with acute
		  'ÿ' => '{\\"{y}}', #latin small letter y with adiaeresis
		  '~' => '{\\textasciitilde}', #modifier letter tilde accent
		  '^' => '{\\textasciicircum}', #modifier letter circumflex accent
		) ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$$$$$$$)  {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = $class->SUPER::new($_[0],$_[1],$_[2],$_[3]) ;

  $self->{'PHPDOCGEN'}{'VERSION'} = $_[4]{'version'} ;
  $self->{'PHPDOCGEN'}{'DATE'} = $_[4]{'date'} ;
  $self->{'PHPDOCGEN'}{'AUTHOR'} = $_[4]{'author'} ;
  $self->{'PHPDOCGEN'}{'AUTHOR_EMAIL'} = $_[4]{'email'} ;
  $self->{'PHPDOCGEN'}{'URL'} = $_[4]{'url'} ;
  $self->{'PHPDOCGEN'}{'BUG_URL'} = $_[4]{'bug'} ;
  $self->{'GENERATE_PHP_DOC'} = $_[5]{'php'} ;
  $self->{'GENERATE_WEB_DOC'} = $_[5]{'web'} ;
  $self->{'SHOWSOURCES'} = ( $_[5]{'sources'} && $self->{'GENERATE_PHP_DOC'} ) ;
  $self->{'WEBDOC_DIR'} = 'webdoc' ;
  $self->{'WEBTARGET'} = File::Spec->catdir($self->{'TARGET'},$self->{'WEBDOC_DIR'}) ;

  if ( ( ! $self->{'GENERATE_PHP_DOC'} ) &&
       ( ! $self->{'GENERATE_WEB_DOC'} ) ) {
    PhpDocGen::General::Error::syserr( "We don't want to generate the PHP documentation ".
				       "nor the web documentation." ) ;
  }

  my $themename = $_[6] || 'JavaDoc' ;
  if ( ( $themename ) &&
       ( $themename !~ /::/ ) ) {
    $themename = "PhpDocGen::Generator::LaTeX::".$themename."Theme" ;
  }
  eval "require ".$themename.";" ;
  if ( $@ ) {
    PhpDocGen::General::Error::syserr( "Unable to load the LaTeX theme $themename:\n$@" ) ;
  }
  $self->{'THEME'} = ($themename)->new( $self->{'PHPDOCGEN'},
					$self->{'TARGET'},
					$self->{'SHORT_TITLE'},
					$self->{'GENERATE_PHP_DOC'},
					$self->{'GENERATE_WEB_DOC'} ) ;
  if ( $_[7] ) {
    my @pack = split /\:\:/, __PACKAGE__ ;
    pop @pack ;
    $self->{'PERLSCRIPTDIR'} = File::Spec->canonpath( $_[7] ) ;
    $self->{'PERLSCRIPTDIR'} = File::Spec->catdir( $self->{'PERLSCRIPTDIR'}, @pack ) ;
  }
  else {
    $self->{'PERLSCRIPTDIR'} = "" ;
  }

  $self->{'COPY_FILES'} = [ 'Makefile' ] ;

  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# File API
#
#------------------------------------------------------

=pod

=item * write_file()

Writes a file.
Takes 2 args:

=over

=item * filename (string)

is the name of the file to write (inside the target directory)

=item * content (string)

is the content of the file.

=back

=cut
sub write_file($$)  {
  my $self = shift ;
  my $filename = $_[0] || confess( 'you must specify a filename' ) ;
  my $content = $_[1] || '' ;
  PhpDocGen::General::Verbose::one( "Writing ".$filename."..." ) ;
  $filename = File::Spec->catfile( $self->{'TARGET'}, $filename ) ;
  local *OUTPUT_FILE ;
  open( OUTPUT_FILE, "> $filename" )
    or PhpDocGen::General::Error::syserr( "$filename: $!" ) ;
  print OUTPUT_FILE join( '',
                          "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n",
                          "%% Generated by phpdocgen ",
                          $self->{'PHPDOCGEN'}{'VERSION'},
                          ",\n%% the ",
                          "".localtime(),
                          "\n\n",
                          $content ) ;
  close( OUTPUT_FILE ) ;
}

=pod

=item * copy_files()

Copy a set of files needed by the generated document.

=cut
sub copy_files()  {
  my $self = shift ;
  foreach my $file (@{$self->{'COPY_FILES'}}) {
    PhpDocGen::General::Verbose::one( "Copying ".$file."..." ) ;
    PhpDocGen::General::Verbose::two( "\tfrom ".$self->{'PERLSCRIPTDIR'} ) ;
    PhpDocGen::General::Verbose::two( "\tto   ".$self->{'TARGET'} ) ;
    my $from = File::Spec->catfile($self->{'PERLSCRIPTDIR'}, $file) ;
    copy( $from,
          File::Spec->catfile($self->{'TARGET'},$file) )
      or PhpDocGen::General::Error::syserr( "$from: $!\n" );
  }
  # Copy theme files
  $self->{'THEME'}->copy_files() ;
}

#------------------------------------------------------
#
# Generation API
#
#------------------------------------------------------

=pod

=item * generate_main_tex()

Creates the main .tex.

=cut
sub generate_main_tex()  {
  my $self = shift ;
  my $content = join( '',
                      "\\documentclass{",
                      $self->{'THEME'}->get_document_class(),
                      "}\n\n",
                      $self->{'THEME'}->get_preamble(),
                      "\n\\begin{document}\n",
                      "\\title{",
                      $self->{'TITLE'},
                      "}\n\\author{}\n",
                      "\\date{\\today}\n",
                      "\\maketitle\n" ) ;

  while ( my ($k,$v) = each(%TRANS_TBL) ) {
    $content .= "$v\n" ;
  }

$content .= "\\end{document}\n" ;

  $self->write_file( 'main.tex',
                     $content ) ;
}


=pod

=item * generate()

Creates the documentation.

=cut
sub generate()  {
  my $self = shift ;
  $self->generate_main_tex() ;
  $self->copy_files() ;
}

#------------------------------------------------------
#
# Theme API
#
#------------------------------------------------------

=pod

=item * display_supported_themes()

Display the list of supported types.
Takes 1 arg:

=over

=item * perldir (string)

is the path to the directory where the Perl packages
are stored.

=item * default (string)

is the name of the default theme

=back

=cut
sub display_supported_themes($$) {
  my $path = $_[0] || confess( 'you must specify the pm path' ) ;
  my $default = $_[1] || '' ;
  my @pack = split /\:\:/, File::Spec->catfile($path,__PACKAGE__) ;
  pop @pack ;
  push @pack, "Theme" ;
  foreach my $file ( glob(File::Spec->catfile(@pack, '*') ) ) {
    my $name = basename($file) ;
    if ( $name =~ /^(.+)Theme\.pm$/ ) {
      $name = $1 ;
      print join( '',
		  "$name",
		  ( $default && ( $default eq $name ) ) ?
		  " (default)" : "",
		  "\n" ) ;
    }
  }
}

=pod

=item * display_supported_languages()

Display the list of supported languages.
Takes 2 args:

=over

=item * perldir (string)

is the path to the directory where the Perl packages
are stored.

=item * default (string)

is the name of the default language

=back

=cut
sub display_supported_languages($$) {
  my $path = $_[0] || confess( 'you must specify the pm path' ) ;
  my $default = $_[1] || '' ;
  my @pack = split /\:\:/, File::Spec->catfile($path,__PACKAGE__) ;
  pop @pack ;
  push @pack, "Lang" ;
  foreach my $file ( glob(File::Spec->catfile(@pack, '*') ) ) {
    my $name = basename($file) ;
    if ( $name =~ /^(.+)Lang\.pm$/ ) {
      $name = $1 ;
      print join( '',
		  "$name",
		  ( $default && ( $default eq $name ) ) ?
		  " (default)" : "",
		  "\n" ) ;
    }
  }
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

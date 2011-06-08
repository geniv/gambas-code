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

PhpDocGen::General::HTML - HTML support definitions

=head1 DESCRIPTION

PhpDocGen::General::HTML is a Perl module, which permits to support
some HTML definitions.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in HTML.pm itself.

=over

=cut

package PhpDocGen::General::HTML;

@ISA = ('Exporter');
@EXPORT = qw(&get_html_entities &get_restricted_html_entities &translate_html_entities
	     &htmlcatdir &htmlcatfile &htmldirname &htmlfilename &htmltoroot &htmlpath
	     &htmlsplit &strip_html_tags &htmlcanonpath );
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use PhpDocGen::General::Misc ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the HTML support functions
my $VERSION = "0.5" ;

# Translation table
my %HTML_ENTITY_CODES = ( 'nbsp'       => 160, #no-break space = non-breaking space
			  'iexcl'      => 161, #inverted exclamation mark, U+00A1 ISOnum
			  'cent'       => 162, #cent sign
			  'pound'      => 163, #pound sign
			  'curren'     => 164, #currency sign
			  'yen'        => 165, #yen sign = yuan sign
			  'brvbar'     => 166, #broken bar = broken vertical bar
			  'sect'       => 167, #section sign
			  'uml'        => 168, #diaeresis = spacing diaeresis,
			  'copy'       => 169, #copyright sign
			  'ordf'       => 170, #feminine ordinal indicator
			  'laquo'      => 171, #left-pointing double angle quotation mark
			  'not'        => 172, #not sign
			  'shy'        => 173, #soft hyphen = discretionary hyphen
			  'reg'        => 174, #registered sign = registered trade mark sign
			  'macr'       => 175, #macron = spacing macron = overline = APL overbar
			  'deg'        => 176, #degree sign
			  'plusmn'     => 177, #plus-minus sign = plus-or-minus sign
			  'sup2'       => 178, #superscript two = superscript digit two = squared
			  'sup3'       => 179, #superscript three = superscript digit three = cubed
			  'acute'      => 180, #acute accent = spacing acute
			  'micro'      => 181, #micro sign
			  'para'       => 182, #pilcrow sign = paragraph sign
			  'middot'     => 183, #middle dot = Georgian comma = Greek middle dot
			  'cedil'      => 184, #cedilla = spacing cedilla
			  'sup1'       => 185, #superscript one = superscript digit one
			  'ordm'       => 186, #masculine ordinal indicator
			  'raquo'      => 187, #right-pointing double angle quotation mark = right pointing guillemet
			  'frac14'     => 188, #vulgar fraction one quarter = fraction one quarter
			  'frac12'     => 189, #vulgar fraction one half = fraction one half
			  'frac34'     => 190, #vulgar fraction three quarters = fraction three quarters
			  'iquest'     => 191, #inverted question mark = turned question mark
			  'Agrave'     => 192, #latin capital letter A with grave = latin capital letter A grave
			  'Aacute'     => 193, #latin capital letter A with acute
			  'Acirc'      => 194, #latin capital letter A with circumflex
			  'Atilde'     => 195, #latin capital letter A with tilde
			  'Auml'       => 196, #latin capital letter A with diaeresis
			  'Aring'      => 197, #latin capital letter A with ring above = latin capital letter A ring
			  'AElig'      => 198, #latin capital letter AE = latin capital ligature AE
			  'Ccedil'     => 199, #latin capital letter C with cedilla
			  'Egrave'     => 200, #latin capital letter E with grave
			  'Eacute'     => 201, #latin capital letter E with acute
			  'Ecirc'      => 202, #latin capital letter E with circumflex
			  'Euml'       => 203, #latin capital letter E with diaeresis
			  'Igrave'     => 204, #latin capital letter I with grave
			  'Iacute'     => 205, #latin capital letter I with acute
			  'Icirc'      => 206, #latin capital letter I with circumflex
			  'Iuml'       => 207, #latin capital letter I with diaeresis
			  'ETH'        => 208, #latin capital letter ETH
			  'Ntilde'     => 209, #latin capital letter N with tilde
			  'Ograve'     => 210, #latin capital letter O with grave
			  'Oacute'     => 211, #latin capital letter O with acute
			  'Ocirc'      => 212, #latin capital letter O with circumflex
			  'Otilde'     => 213, #latin capital letter O with tilde
			  'Ouml'       => 214, #latin capital letter O with diaeresis
			  'times'      => 215, #multiplication sign
			  'Oslash'     => 216, #latin capital letter O with stroke = latin capital letter O slash
			  'Ugrave'     => 217, #latin capital letter U with grave
			  'Uacute'     => 218, #latin capital letter U with acute
			  'Ucirc'      => 219, #latin capital letter U with circumflex
			  'Uuml'       => 220, #latin capital letter U with diaeresis
			  'Yacute'     => 221, #latin capital letter Y with acute
			  'THORN'      => 222, #latin capital letter THORN
			  'szlig'      => 223, #latin small letter sharp s = ess-zed
			  'agrave'     => 224, #latin small letter a with grave = latin small letter a grave
			  'aacute'     => 225, #latin small letter a with acute
			  'acirc'      => 226, #latin small letter a with circumflex
			  'atilde'     => 227, #latin small letter a with tilde
			  'auml'       => 228, #latin small letter a with diaeresis
			  'aring'      => 229, #latin small letter a with ring above = latin small letter a ring
			  'aelig'      => 230, #latin small letter ae = latin small ligature ae
			  'ccedil'     => 231, #latin small letter c with cedilla
			  'egrave'     => 232, #latin small letter e with grave
			  'eacute'     => 233, #latin small letter e with acute
			  'ecirc'      => 234, #latin small letter e with circumflex
			  'euml'       => 235, #latin small letter e with diaeresis
			  'igrave'     => 236, #latin small letter i with grave
			  'iacute'     => 237, #latin small letter i with acute
			  'icirc'      => 238, #latin small letter i with circumflex
			  'iuml'       => 239, #latin small letter i with diaeresis
			  'eth'        => 240, #latin small letter eth
			  'ntilde'     => 241, #latin small letter n with tilde
			  'ograve'     => 242, #latin small letter o with grave
			  'oacute'     => 243, #latin small letter o with acute
			  'ocirc'      => 244, #latin small letter o with circumflex
			  'otilde'     => 245, #latin small letter o with tilde
			  'ouml'       => 246, #latin small letter o with diaeresis
			  'divide'     => 247, #division sign
			  'oslash'     => 248, #latin small letter o with stroke = latin small letter o slash
			  'ugrave'     => 249, #latin small letter u with grave
			  'uacute'     => 250, #latin small letter u with acute
			  'ucirc'      => 251, #latin small letter u with circumflex
			  'uuml'       => 252, #latin small letter u with diaeresis
			  'yacute'     => 253, #latin small letter y with acute
			  'thorn'      => 254, #latin small letter thorn
			  'yuml'       => 255, #latin small letter y with diaeresis
			  'quot'       => 34, #quotation mark = APL quote
			  'amp'        => 38, #ampersand
			  'lt'         => 60, #less-than sign
			  'gt'         => 62, #greater-than sign
			  'OElig'      => 338, #latin capital ligature OE
			  'oelig'      => 339, #latin small ligature oe
			  'Scaron'     => 352, #latin capital letter S with caron
			  'scaron'     => 353, #latin small letter s with caron
			  'Yuml'       => 376, #latin capital letter Y with diaeresis
			  'circ'       => 710, #modifier letter circumflex accent
			  'tilde'      => 732, #small tilde
			) ;

# The characters which are displayed for each HTML entity (except &amp; &gt; &lt; &quot; )
my %HTML_ENTITY_CHARS = (  'Ocirc'        => 'Ô',
			   'szlig'        => 'ß',
			   'micro'        => 'µ',
			   'para'         => '¶',
			   'not'          => '¬',
			   'sup1'         => '¹',
			   'oacute'       => 'ó',
			   'Uacute'       => 'Ú',
			   'middot'       => '·',
			   'ecirc'        => 'ê',
			   'pound'        => '£',
			   'scaron'       => '¨',
			   'ntilde'       => 'ñ',
			   'igrave'       => 'ì',
			   'atilde'       => 'ã',
			   'thorn'        => 'þ',
			   'Euml'         => 'Ë',
			   'Ntilde'       => 'Ñ',
			   'Auml'         => 'Ä',
			   'plusmn'       => '±',
			   'raquo'        => '»',
			   'THORN'        => 'Þ',
			   'laquo'        => '«',
			   'Eacute'       => 'É',
			   'divide'       => '÷',
			   'Uuml'         => 'Ü',
			   'Aring'        => 'Å',
			   'ugrave'       => 'ù',
			   'Egrave'       => 'È',
			   'Acirc'        => 'Â',
			   'oslash'       => 'ø',
			   'ETH'          => 'Ð',
			   'iacute'       => 'í',
			   'Ograve'       => 'Ò',
			   'Oslash'       => 'Ø',
			   'frac34'       => '3/4',
			   'Scaron'       => '¦',
			   'eth'          => 'ð',
			   'icirc'        => 'î',
			   'ordm'         => 'º',
			   'ucirc'        => 'û',
			   'reg'          => '®',
			   'tilde'        => '~',
			   'aacute'       => 'á',
			   'Agrave'       => 'À',
			   'Yuml'         => '¾',
			   'times'        => '×',
			   'deg'          => '°',
			   'AElig'        => 'Æ',
			   'Yacute'       => 'Ý',
			   'Otilde'       => 'Õ',
			   'circ'         => '^',
			   'sup3'         => '³',
			   'oelig'        => '½',
			   'frac14'       => '1/4',
			   'Ouml'         => 'Ö',
			   'ograve'       => 'ò',
			   'copy'         => '©',
			   'shy'          => '­',
			   'iuml'         => 'ï',
			   'acirc'        => 'â',
			   'iexcl'        => '¡',
			   'Iacute'       => 'Í',
			   'Oacute'       => 'Ó',
			   'ccedil'       => 'ç',
			   'frac12'       => '1/2',
			   'Icirc'        => 'Î',
			   'eacute'       => 'é',
			   'egrave'       => 'è',
			   'euml'         => 'ë',
			   'Ccedil'       => 'Ç',
			   'OElig'        => '¼',
			   'Atilde'       => 'Ã',
			   'ouml'         => 'ö',
			   'cent'         => '¢',
			   'Aacute'       => 'Á',
			   'sect'         => '§',
			   'Ugrave'       => 'Ù',
			   'aelig'        => 'æ',
			   'ordf'         => 'ª',
			   'yacute'       => 'ý',
			   'Ecirc'        => 'Ê',
			   'auml'         => 'ä',
			   'macr'         => '¯',
			   'iquest'       => '¿',
			   'sup2'         => '²',
			   'Ucirc'        => 'Û',
			   'aring'        => 'å',
			   'Igrave'       => 'Ì',
			   'yen'          => '¥',
			   'uuml'         => 'ü',
			   'otilde'       => 'õ',
			   'uacute'       => 'ú',
			   'yuml'         => 'ÿ',
			   'ocirc'        => 'ô',
			   'Iuml'         => 'Ï',
			   'agrave'       => 'à',
			) ;


#------------------------------------------------------
#
# Predefined PHP variables support
#
#------------------------------------------------------

=pod

=item * strip_html_tags()

Removes the HTML tags from the specified string.
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
use PhpDocGen::General::Error ;
sub strip_html_tags($) {
  my $text = $_[0] || '' ;
  my $res = '' ;
  while ( ( $text ) &&
          ( $text =~ /^(.*?)<(.*)$/ ) ) {
    my ($prev,$next) = ($1,$2) ;
    $res .= "$prev" ;
    $text = $next ;
    my $inside = 1 ;
    while ( ( $inside ) && ( $text ) &&
            ( $text =~ /^.*?(>|\"|\')(.*)$/ ) ) {
      my ($sep,$next) = ($1,$2) ;
      $text = $next ;
      if ( $sep eq ">" ) {
        $inside = 0 ;
      }
      else {
        my $insidetext = 1 ;
        while ( ( $insidetext ) && ( $text ) &&
                ( $text =~ /^.*?((?:\\)|$sep)(.*)$/ ) ) {
          my ($sepi,$rest) = ($1,$2) ;
          if ( $sepi eq '\\' ) {
            $text = substr($rest,1) ;
          }
          else {
            $text = $rest ;
            $insidetext = 0 ;
          }
        }
      }
    }
  }
  if ( $text ) {
    $res .= $text ;
  }
  return $res ;
}

=pod

=item * get_restricted_html_entities()

Replies the specified string in which some characters have been
replaced by the corresponding HTML entities except for &amp;
&quot; &lt; and &gt;
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub get_restricted_html_entities($) {
  my $text = $_[0] || '' ;
  foreach my $entity (keys %HTML_ENTITY_CHARS) {
    $text =~ s/\Q&#$HTML_ENTITY_CODES{$entity};\E/&$entity;/g ;
    $text =~ s/\Q$HTML_ENTITY_CHARS{$entity}\E/&$entity;/g ;
  }
  return $text ;
}

=pod

=item * get_html_entities()

Replies the specified string in which some characters have been
replaced by the corresponding HTML entities
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub get_html_entities($) {
  my $text = $_[0] || '' ;
  $text =~ s/\Q&\E/&amp;/g ;
  $text =~ s/\Q<\E/&lt;/g ;
  $text =~ s/\Q>\E/&gt;/g ;
  $text =~ s/\Q\"\E/&quot;/g ;
  return get_restricted_html_entities($text) ;
}

=pod

=item * translate_html_entities()

Replies the specified string in which each HTML entity was replaced
by the corresponding character.
Takes 1 arg:

=over

=item * text (string)

is a I<string> which correspond to the text to translate.

=back

=cut
sub translate_html_entities($) {
  my $text = $_[0] || '' ;
  foreach my $entity (keys %HTML_ENTITY_CHARS) {
    $text =~ s/\Q&$entity;\E/$HTML_ENTITY_CHARS{$entity}/g ;
    $text =~ s/\Q&$HTML_ENTITY_CODES{$entity};\E/$HTML_ENTITY_CHARS{$entity}/g ;
  }
  $text =~ s/\Q&quot;\E/\"/g ;
  $text =~ s/\Q&lt;\E/</g ;
  $text =~ s/\Q&gt;\E/>/g ;
  $text =~ s/\Q&amp;\E/&/g ;
  return $text ;
}

=pod

=item * htmlcatdir()

Concatenate two or more directory names to form a complete path ending
with a directory. But remove the trailing slash from the resulting
string.
Takes 2 args or more:

=over

=item * dir... (string)

is a I<string> which correspond to a directory name to merge

=back

=cut
sub htmlcatdir {
  return '' unless @_ ;
  my $path = join('/', @_ ) ;
  $path =~ s/\/{2,}/\//g ;
  $path =~ s/\/$// ;
  return $path ;
}

=pod

=item * htmlcatfile()

Concatenate one or more directory names and a filename to form a
complete path ending with a filename
Takes 2 args or more:

=over

=item * dir... (string)

is a I<string> which correspond to a directory name to merge

=item * file (string)

is a I<string> which correspond to a file name to merge

=back

=cut
sub htmlcatfile {
  return '' unless ( @_ ) ;
  my $file = pop @_;
  return $file unless @_;
  my $dir = htmlcatdir(@_);
  $dir .= "/" unless substr($file,0,1) eq "/" ;
  return $dir.$file;
}

=pod

=item * htmldirname()

Replies the path of the from the specified file
Takes 1 arg:

=over

=item * path (string)

is a I<string> which correspond to the path from which
the dirname but be extracted

=back

=cut
sub htmldirname($) {
  my $dirname = $_[0] || '';
  $dirname =~ s/\/+\s*$// ;
  if ( $dirname =~ /^(.*?)\/[^\/]+$/ ) {
    return $1 || '/' ;
  }
  else {
    return '' ;
  }
}

=pod

=item * htmlfilename()

Replies the filename of the from the specified file
Takes 1 arg:

=over

=item * path (string)

is a I<string> which correspond to the path from which
the filename but be extracted

=back

=cut
sub htmlfilename($) {
  my $filename = $_[0] || '' ;
  $filename =~ s/\/+\s*$// ;
  if ( $filename =~ /^.*?\/([^\/]+)$/ ) {
    $filename = $1 ;
  }
  return $filename ;
}

=pod

=item * htmltoroot()

Replies a relative path in wich each directory of the
specified parameter was replaced by ..
Takes 1 arg:

=over

=item * path (string)

is a I<string> which correspond to the path to translate

=back

=cut
sub htmltoroot($) {
  my $dir = $_[0] || '' ;
  $dir =~ s/\/\s*$// ;
  $dir =~ s/[^\/]+/../g ;
  return $dir ;
}

=pod

=item * htmlpath()

Replies a path in which all the OS path separators were replaced
by the HTML path separator '/'
Takes 1 arg:

=over

=item * path (string)

is a I<string> which correspond to the path to translate

=back

=cut
sub htmlpath($) {
  my $path = $_[0] || '' ;
  my $sep = "/" ;
  my $p = File::Spec->catdir("a","b") ;
  if ( $p =~ /a(.+)b/ ) {
    $sep = $1 ;
  }
  $path =~ s/\//$sep/g ;
  return $path ;
}

=pod

=item * htmlsplit()

Replies an array of directories which correspond to each
parts of the specified path.
Takes 1 arg:

=over

=item * path (string)

is a I<string> which correspond to the path to split

=back

=cut
sub htmlsplit($) {
  my $path = $_[0] || '' ;
  return split( /\//, $path ) ;
}

=pod

=item * htmlcanonpath()

Replies a path that start from the root.
Takes 1 arg:

=over

=item * path (string)

is a path to canonize.

=back

=cut
sub htmlcanonpath($) {
  my $path = $_[0] || '' ;
  if ( substr($path,0,1) ne '/' ) {
    $path = "/$path" ;
  }
  return $path ;
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

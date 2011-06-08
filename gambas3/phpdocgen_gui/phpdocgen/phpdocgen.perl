#!/usr/bin/perl -w

# phpdocgen script to generate an HTML document for PHP source files
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

use Getopt::Long ;
use Pod::Usage ;
use File::Basename ;
use File::Spec ;
use File::Path ;
use strict ;

#------------------------------------------------------
#
# Initialization code
#
#------------------------------------------------------
my $PERLSCRIPTDIR ;
BEGIN{
  # Where is this script?
  $PERLSCRIPTDIR = "$0";
  my $scriptdir = dirname( $PERLSCRIPTDIR );
  while ( -e $PERLSCRIPTDIR && -l $PERLSCRIPTDIR ) {
    $PERLSCRIPTDIR = readlink($PERLSCRIPTDIR);
    if ( substr( $PERLSCRIPTDIR, 0, 1 ) eq '.' ) {
      $PERLSCRIPTDIR = File::Spec->catfile( $scriptdir, "$PERLSCRIPTDIR" ) ;
    }
    $scriptdir = dirname( $PERLSCRIPTDIR );
  }
  $PERLSCRIPTDIR = dirname( $PERLSCRIPTDIR ) ;
  $PERLSCRIPTDIR = File::Spec->rel2abs( "$PERLSCRIPTDIR" );
  # Push the path where the script is to retreive the arakhne.org packages
  push(@INC,"$PERLSCRIPTDIR");

}

use PhpDocGen::Release ;
use PhpDocGen::General::Token ;
use PhpDocGen::General::Verbose ;
use PhpDocGen::General::Error ;
use PhpDocGen::General::Misc ;
use PhpDocGen::General::Parsing ;
use PhpDocGen::Parser::Parser ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of phpdocgen
my $VERSION = PhpDocGen::Release::getVersionNumber() ;
# Date of this release of phpdocgen
my $VERSION_DATE = PhpDocGen::Release::getVersionDate() ;
# URL from which the users can submit a bug
my $SUBMIT_BUG_URL = PhpDocGen::Release::getBugReportURL() ;
# Email of the author of phpdocgen
my $AUTHOR = PhpDocGen::Release::getAuthorName() ;
# Email of the author of phpdocgen
my $AUTHOR_EMAIL = PhpDocGen::Release::getAuthorEmail() ; ;
# Page of phpdocgen
my $URL = PhpDocGen::Release::getMainURL() ; ;

# Command line options
my %options = () ;

#------------------------------------------------------
#
# Main program
#
#------------------------------------------------------

# Sets the general flags
PhpDocGen::General::Error::debugflag( $VERSION =~ /rc[0-9][0-9.]*/ ) ;

# Read the command line
$options{warnings} = 1 ;
$options{genphpdoc} = 1 ;
$options{theme} = 'JavaDoc' ;
$options{lang} = 'English' ;
Getopt::Long::Configure("bundling") ;
if ( ! GetOptions( "version" => \$options{'version'},
		   "help|h|?" => \$options{'help'},
		   "man|manual" => \$options{'manual'},
		   "f|force" => \$options{'force'},
		   "r|R" => \$options{'recurse'},
		   "verbatim" => \$options{'verbatim'},
		   "o|output=s" => \$options{'output'},
		   "defpack=s" => \$options{'default-package'},
		   "filters=s" => \$options{'filters'},
		   "q" => \$options{'quiet'},
		   "windowtitle=s" => \$options{'title'},
		   "warning!" => \$options{'warnings'},
		   "doctitle=s" => \$options{'summary-title'},
		   "html" => \$options{'html'},
		   "latex" => \$options{'latex'},
		   "v+" => \$options{'verbose'},
		   "sources!" => \$options{'gensources'},
                   "extscanner=s" => \$options{'extscanner'},
		   "phpgen!" => \$options{'genphpdoc'},
		   "webgen!" => \$options{'genwebdoc'},
		   "theme=s" => \$options{'theme'},
		   "themelist" => \$options{'themelist'},
		   "lang=s" => \$options{'lang'},
		   "langlist" => \$options{'langlist'},
		   "x|exclude=s" => \$options{'exclude-file'},
		   "X|exclude-from=s" => \$options{'exclude-from-file'},
		  ) ) {
  pod2usage(2) ;
}

# Show the version number
if ( $options{version} ) {
  print "phpdocgen $VERSION, $VERSION_DATE\n" ;
  print "Copyright (c) 2002-03, $AUTHOR <$AUTHOR_EMAIL>, under GPL\n" ;
  exit 1 ;
}

# Show the help screens
if ( $options{manual} ) {
    system( "perldoc $0" ) ;
    exit(1) ;
}
elsif ( $options{'themelist'} ) {

  if ( $options{'latex'} ) {
    # Use the LaTeX generator
    PhpDocGen::General::Error::syserr( 'The LaTeX generator is not yet implemented' ) ;
    use PhpDocGen::Generator::LaTeX::LaTeX ;
    PhpDocGen::Generator::LaTeX::LaTeX::display_supported_themes( $PERLSCRIPTDIR, $options{'theme'} ) ;
  }
  else {
    # Use the HTML generator
    use PhpDocGen::Generator::Html::Html ;
    PhpDocGen::Generator::Html::Html::display_supported_themes( $PERLSCRIPTDIR, $options{'theme'} ) ;
  }

  exit(0) ;
}
elsif ( $options{'langlist'} ) {

  if ( $options{'latex'} ) {
    # Use the LaTeX generator
    PhpDocGen::General::Error::syserr( 'The LaTeX generator is not yet implemented' ) ;
    use PhpDocGen::Generator::LaTeX::LaTeX ;
    PhpDocGen::Generator::LaTeX::LaTeX::display_supported_languages( $PERLSCRIPTDIR, $options{'lang'} ) ;
  }
  else {
    # Use the HTML generator
    use PhpDocGen::Generator::Html::Html ;
    PhpDocGen::Generator::Html::Html::display_supported_languages( $PERLSCRIPTDIR, $options{'lang'} ) ;
  }

  exit(0) ;
}
elsif ( $options{help} || ( $#ARGV < 0 ) ) {
    pod2usage(1);
}

#
# Sets the default values of options
#

# Verbosing:
if ( $options{quiet} ) {
  $options{verbose} = 0 ;
}
elsif ( $options{verbose} ) {
  $options{verbose} ++ ;
}
else {
  $options{verbose} = 1 ;
}
PhpDocGen::General::Verbose::setlevel( $options{verbose} ) ;

# Error messages:
if ( $options{'warnings'} ) {
  PhpDocGen::General::Error::unsetwarningaserror() ;
}
else {
  PhpDocGen::General::Error::setwarningaserror() ;
}

# Package:
if ( ! $options{'default-package'} ) {
  $options{'default-package'} = "main" ;
}

# Filters:
if ( $options{'filters'} ) {
  my @filt = split( /:/, $options{'filters'} ) ;
  $options{'filters'} = "" ;
  foreach my $f (@filt) {
    if ( $options{'filters'} ) {
      $options{'filters'} .= "|" ;
    }
    $f =~ s/\./\\./g ;
    $f =~ s/\*/.*/g ;
    $f =~ s/\?/.?/g ;
    $options{'filters'} .= "($f)" ;
  }
}
if ( ! $options{'filters'} ) {
  $options{'filters'} = "(.*\\.php[^~]*)" ;
}
$options{'filters'} = "^".$options{'filters'}."\$" ;

#
# Build the list of parsable files
#
my @parsable_files = () ;
my @excludefiles = () ;
if ( $options{'exclude-file'} ) {
  push @excludefiles, File::Spec->canonpath($options{'exclude-file'}) ;
}
if ( ( $options{'exclude-from-file'} ) &&
     ( -f $options{'exclude-from-file'} ) ) {
  local *EXCLUDEFILE ;
  open( *EXCLUDEFILE, "< $options{'exclude-from-file'}" )
    or PhpDocGen::General::Error::syserr( "unable to open ".
					  $options{'exclude-from-file'}.
					  ": $!" ) ;
  while ( my $line = <EXCLUDEFILE> ) {
    $line =~ s/[\n\r]+//g ;
    push @excludefiles, File::Spec->canonpath($line) ;
  }
  close( *EXCLUDEFILE ) ;
}

#
# Read the content of the files
#
my $parser = PhpDocGen::Parser::Parser->new( $options{'filters'},
					     $options{'recurse'},
					     $options{'verbatim'},
					     $options{'default-package'},
					     $options{'extscanner'} ) ;

$parser->parse( \@ARGV, \@excludefiles ) ;

#
# Create the output directory
#
if ( ! $options{'output'} ) {
  $options{'output'} = "./phpdoc/" ;
}
$options{'output'} =~ s/\/\s*$// ;
if ( ! -d $options{'output'} ) {
  mkdir( $options{'output'}, 0777 )
    or PhpDocGen::General::Error::syserr( $options{'output'}.": $!\n" );
}
elsif ( ! $options{'force'} ) {
  PhpDocGen::General::Error::syserr( "The output directory '".$options{'output'}.
				     "' already exists. Use the -f option to force the overwrite\n" ) ;
}
else {
  rmtree( $options{'output'} )
    or PhpDocGen::General::Error::syserr( "The output directory '".$options{'output'}.
					  "' can't be deleted: $!\n" ) ;
  mkdir( $options{'output'}, 0777 )
    or PhpDocGen::General::Error::syserr( $options{'output'}.": $!\n" );
}

PhpDocGen::General::Verbose::two( $parser->contentstats() ) ;

#
# Outputs the pages
#
my $generator ;
my $generator_class ;
if ( $options{'latex'} ) {
  # Use the LaTeX generator
  PhpDocGen::General::Error::syserr( 'The LaTeX generator is not yet implemented' ) ;
  $generator_class = "PhpDocGen::Generator::LaTeX::LaTeX" ;
}
else {
# Use the HTML generator
  $generator_class = "PhpDocGen::Generator::Html::Html" ;
}

# Instances the generator
eval "use $generator_class ;" ;
if ( $@ ) {
  die "$@" ;
}

$generator = $generator_class->new( $parser->content(),
				    $options{'title'},
				    $options{'summary-title'},
				    $options{'output'},
				    { 'version' => $VERSION,
				      'date' => $VERSION_DATE,
				      'author' => $AUTHOR,
				      'email' => $AUTHOR_EMAIL,
				      'url' => $URL,
				      'bug' => $SUBMIT_BUG_URL,
				    },
				    { 'sources' => $options{'gensources'},
				      'php' => $options{'genphpdoc'},
				      'web' => $options{'genwebdoc'},
				    },
				    $options{'theme'},
				    $options{'lang'},
				    $PERLSCRIPTDIR
				  ) ;
$generator->generate() ;

# Display the quantity of warnings
PhpDocGen::General::Error::printwarningcount() ;

exit 0 ;

__END__

=head1 NAME

phpdocgen - A perl script that generates an API documentation for PHP source files

=head1 SYNOPSYS

phpdocgen_checker [options] I<file> [I<file> ...]

=head1 DESCRIPTION

phpdocgen_checker is a script which extract the data in the same way
as phpdocgen, and display the result of the coherence checking algorithm.

=head1 OPTIONS

=over 4

=item B<--defpack> I<name>

Sets the name of the default package.

=item B<--doctitle> I<text>

Sets the title of the documentation that appears in the summary.

=item B<--exclude> I<file>

Excludes the I<file> from the list of files which will be parsed.

=item B<--exclude-from> I<file>

Excludes from the list of files which will be parsed all the files which
are listed inside the specified I<file>. The I<file> must contain one
filename per line.

=item B<--extscanner> I<name>

Force phpdocgen to use the specified extended scanner. This option is
not officially supported. The I<name> must be the name of the Perl
class which must be used to scan the PHP source files.

=item B<-f>

=item B<--force>

If the option B<-o> was not given, forces to overwrite into the
default output directory (./doc/).

=item B<--filters> I<filters>

Sets the filters used to recognized the PHP files. I<filters> must
be a list of filters separated by ':'. You can use the shell
wildcards in the filters. The default filter is '*.php*'.

=item B<-?>

=item B<-h>

=item B<--help>

Show the list of available options.

=item B<--html>

Generates the documentation as HTML pages.

=item B<--lang> I<name>

Sets the language used by the documentation generator.

=item B<--langlist>

Display the list of supported languages.

=item B<--latex>

Generates the documentation as a LaTeX document.

=item B<--man>

=item B<--manual>

Show the manual page.

=item B<-o> I<file>

=item B<--output> I<file>

Sets the directory or the file in which the documentation will be put.

=item B<--[no]phpgen>

Indicates if the documentation of the PHP functions and classes must be generated.

=item B<-q>

Don't be verbose: only error messages are displayed.

=item B<-r>

=item B<-R>

Scans the directories recursively.

=item B<--[no]sources>

Generates additional pages that contain the PHP source code.

=item B<--theme> I<name>

Sets the graphical theme used by the documentation generator.

=item B<--themelist>

Display the list of supported themes.

=item B<-v>

Be more verbose.

=item B<--verbatim>

All comments have the tag @verbatim by default.

=item B<--version>

Show the version of this script.

=item B<--[no]warning>

If false, the warning are converted to errors.

=item B<--[no]webgen>

Indicates if the documentation of the web modules and pages.

=item B<--windowtitle> I<text>

Sets the title of the documentation that appears as the window's title.

=item B<-x> I<file>

See B<--exclude>

=item B<-X> I<file>

See B<--exclude-from>.

=back

=head1 Supported tags

=over 4

=item @attribute [public|protected|private] I<type> I<name>

This optional tag is to force the current comment to be for
for an class attribute named I<name>.
You could use the tag @class to specified the class in which this attribute is.
I<type> must be one of the types described in the section B<Types>.
If this tag is missed, the type is always "mixed". The modifiers "public", "protected"
and "private" are not supported by PHP. They are added for documentation
convenience.

=item @author I<name>

Sets the I<name>name of an author.

=item {@block I<text>}

The I<text> is considered as an unsplitable text.

=item @brief I<comment>

Sets the brief description for the comment. If this tag was not given,
the first sentence of the description will be the brief description.

=item @bug [fixed] I<comment>

Adds a bug report to the current comment.
It is explained by the I<comment>.
If "fixed" is present, it applies that this bug was fixed.

=item @class I<name>

This optional tag is used to force the classname used by a comment.

=item @constant [I<type>] I<name>

This optional tag is used to force the comment to be for a
global constant named I<name>.
You could use the tag @package to specified the package in which this constant is.
I<type> must be one of the types described in the section B<Types>.

=item @constructor I<name>

This optional tag is for a constructor ofthe class named I<name>.
You could use the tag @class to specified the class in which this attribute is.

=item @copyright I<comment>

Adds a copyright description.

=item @date I<date>

    Attaches a date to the current comment.

=item @deprecated I<text>

The currently documented stuff is deprecated. I<text> is the explanation.

=item {@example [frame|noframe] I<file>|I<text>}

Adds a example inside the text. It could be enclosed inside a frame box
(option frame) or not (option noframe). The example could be typed as
inline I<text> or put inside a I<file>.

=item @extends I<name>

See @inherited

=item @function I<name>

This optional tag is used to force the current comment to be for
a global function named I<name>.
You could use the tag @package to specified the class in which is this attribute.

=item @global I<name>

See @use.

=item {@hash [I<key>] I<comment>}

Not supported yet.

=item @inherited I<name>

This optional tag permits to force the documented class inherites from the class I<name>.

=item {@link I<name> [I<comment>]}

Adds a link to the documentation of I<name> with the I<comment>.

=item @log I<date> I<comment>

Adds a changelog for the current comment.
The change is explained by the I<comment> and was applied
since the I<date>.

=item @method [static] [public|protected|private] I<name>

This optional tag is used to force the current comment to be
for an class method named I<name>.
You could use the tag @class to specified the class in which this method is.
If "static" is present, it applies that this method is static, i.e. the
use of the variable $this is not allowed. The modifiers "public", "protected"
and "private" are not supported by PHP. They are added for documentation
convenience.

=item @modifiers [static] [private|protected|public]

This optional tag is used to specify the modified of the current
commented object. It override the modifiers given by @method
and @attribute.

=item @package I<name>

Forces the current package name to I<name>.

=item @param [optional] [reference|ref] I<type> I<name> I<comment>

Adds a parameter comment for the current documented stuff.
The parameter has named I<name> and is commented by I<comment>.
I<type> must be one of the types described in the section B<Types>.
If "optional" was present, it applies that this parameter is optional.
If "reference" (or "ref") was present, it applies that this parameter is
passed by reference.

=item @private

Indicates that the current method or attribute has a private access.

=item @protected

Indicates that the current method or attribute has a protected access.

=item @public

Indicates that the current method or attribute has a public access.

=item @return [reference|ref] [I<type>] I<comment>

Explains what is return by the current documented function.
I<type> must be one of the types described in the section B<Types>.
If "reference" (or "ref") was present, it applies that the returned
value is a reference.

=item @see I<comment>

Gives a pointer to another documentation. If I<comment> is a valid name,
show a link to the corresponding documentation page.

=item @since I<comment>

Explains from when the current comment is exists.

=item @static

Indicates that the current method or attribute was static.

=item @todo I<comment>

Explains something to do for the current documented object.

=item @use I<name>

Indicates that the current function uses the global variable I<name>.

=item @variable I<type> I<name>

This optional tag permits to force the current comment to be for
a global variable named I<name>.
You could use the tag @package to specified the package in which this variable is.
I<type> must be one of the types described in the section B<Types>.

=item @verbatim

The explanation of the current comment will be putted as-is in the
generated documentation. The generated explanation will be enclosed
by <PRE> and </PRE>.

=item @version I<comment>

Describes the version of the documented object.

=item @webmodule I<name>

This tag permits to force the current comment to be for
a webmodule called I<name>. The I<name> must be a valid
HTML path.

=item @webpage [I<path>]/I<name>

This tag permits to force the current comment to be for
a webpage called I<name>. The I<path> must be a valid
HTML path.

=back

=head1 Types

=over 4

=item array

is an array in which all the keys are integers.

=item bool

=item boolean

supports only the values B<TRUE> and B<FALSE>.

=item callback

is an user callback function (eg, parameter of usort()).

=item flt

=item float

is for floating-point numbers.

=item hash

=item hashtable

is for hashtables.

=item int

=item integer

is for integer numbers.

=item mix

=item mixed

indicates that the value could be anything (one of the other types).

=item num

=item number

is a number ie, a float or an integer.

=item obj

=item object

is for PHP objects.

=item resource

is an external resource (eg, SQL request).

=item str

=item string

is a string.

=item time

=item date

=item timestamp

an unix timestamp.

=back

=head1 COPYRIGHT

Copyright (c) 2002-03 Stéphane Galland <galland@arakhne.org>, under GPL.

=head1 SEE ALSO

L<javadoc>

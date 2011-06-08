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
use PhpDocGen::Parser::Parser ;
use PhpDocGen::Checker::Checker ;

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
my $AUTHOR_EMAIL = PhpDocGen::Release::getAuthorEmail() ;
# Page of phpdocgen
my $URL = PhpDocGen::Release::getMainURL() ;

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

		   # Specific to the checker
		   "cdc!" => \$options{'checktree'},
		  ) ) {
  pod2usage(2) ;
}

# Show the version number
if ( $options{version} ) {
  print "checker for phpdocgen $VERSION, $VERSION_DATE\n" ;
  print "Copyright (c) 2002-03, $AUTHOR <$AUTHOR_EMAIL>, under GPL\n" ;
  exit 1 ;
}

# Show the help screens
if ( $options{manual} ) {
    system( "perldoc $0" ) ;
    exit(1) ;
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
# Check the extracted data
#
my $checker = PhpDocGen::Checker::Checker->new( $options{'checktree'} ) ;
my $ret = $checker->check( $parser->content() ) ;

# Display the quantity of warnings
PhpDocGen::General::Error::printwarningcount() ;

exit ( $ret ? 0 : 2 )  ;

__END__

=head1 NAME

phpdocgen_checker - A checker for phpdocgen

=head1 SYNOPSYS

phpdocgen [options] I<file> [I<file> ...]

=head1 DESCRIPTION

phpdocgen is a script similar to I<javadoc>, but designed for PHP source files.
It permits to generate a set of pages (HTML, LaTeX...) that contain the API
documentation of the specified PHP files. If I<file> is a directory, 
all the PHP files of it are readed.

=head1 OPTIONS

=over 4

=item B<--[no]cdc>

Shows or not the real data collection parsed from the PHP source files.

=item B<--defpack> I<name>

Sets the name of the default package.

=item B<--extscanner> I<name>

Force phpdocgen to use the specified extended scanner. This option is
not officially supported. The I<name> must be the name of the Perl
class which must be used to scan the PHP source files.

=item B<--filters> I<filters>

Sets the filters used to recognized the PHP files. I<filters> must
be a list of filters separated by ':'. You can use the shell
wildcards in the filters. The default filter is '*.php*'.

=item B<-?>

=item B<-h>

=item B<--help>

Show the list of available options.

=item B<--man>

=item B<--manual>

Show the manual page.

=item B<-q>

Don't be verbose: only error messages are displayed.

=item B<-r>

=item B<-R>

Scans the directories recursively.

=item B<-v>

Be more verbose.

=item B<--verbatim>

All comments have the tag @verbatim by default.

=item B<--version>

Show the version of this script.

=item B<--[no]warning>

If false, the warning are converted to errors.

=back

=head1 COPYRIGHT

Copyright (c) 2002-03 Stéphane Galland <galland@arakhne.org>, under GPL.

=head1 SEE ALSO

L<javadoc>

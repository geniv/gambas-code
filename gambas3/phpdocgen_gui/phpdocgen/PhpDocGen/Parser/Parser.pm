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

PhpDocGen::Parser::Parser - A parser for PHP source code.

=head1 SYNOPSYS

use PhpDocGen::Parser::Parser ;

my $gen = PhpDocGen::Parser::Parser->new( filters, 
                               recurse, 
                               verbatim,
			       default_package ) ;

=head1 DESCRIPTION

PhpDocGen::Parser::Parser is a Perl module, which parses
a source file to recognize the PHP documentation
tokens.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use PhpDocGen::Parser::Parser;

    my $gen = PhpDocGen::Parser::Parser->new( "^.*\.php.*$",
                                   1,
                                   0,
				   "Pack" ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * filters (string)

is a string that lists the filters used to
select the files to read. It must be expressed
as a regular expression.

=item * recurse (boolean)

must be true if the parser must scan recursively
the input directories.

=item * verbatim (boolean)

must be true if the parser must assume that all
comments are in verbatim mode.

=item * default_package (string)

is the name of the package which will be used
when a tag @package will be not found.

=item * scanner_class (optional string)

is the name of the perl class which must be used to
scan the source files. If not present, the default
(and officially supported scanner) will be used.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Parser.pm itself.

=over

=cut

package PhpDocGen::Parser::Parser;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;
use File::Basename ;
use File::Spec ;

use PhpDocGen::General::Token ;
use PhpDocGen::General::Misc ;
use PhpDocGen::General::Error ;
use PhpDocGen::General::Parsing ;
use PhpDocGen::General::Verbose ;
use PhpDocGen::Parser::BlockScanner ;
use PhpDocGen::Parser::CommentExtractor ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the parser
my $VERSION = "0.2" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$$$)  {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $parent = ref($proto) && $proto ;

  my $self ;
  if ( $parent ) {
    %{$self} = %{$parent} ;
    bless( $self, $class );
  }
  else {
    $self = { 'CONTENT' => {},
              'FILTERS' => $_[0] || "^(.*\\.php[^~]*)\$",
 	      'RECURSE' => $_[1],
	      'VERBATIM' => $_[2],
	      'DEFAULT_PACKAGE' => $_[3],
              'SCANNER_CLASSNAME' => $_[4],
	    } ;
    bless( $self, $class );
    if ( ( $self->{'SCANNER_CLASSNAME'} ) &&
         ( $self->{'SCANNER_CLASSNAME'} !~ /::/ ) ) {
      $self->{'SCANNER_CLASSNAME'} = "PhpDocGen::Parser::ExtScanner::".$self->{'SCANNER_CLASSNAME'} ;
    }
    $self->clearcontent() ;
  }
  return $self;
}

#------------------------------------------------------
#
# Getter/setter functions
#
#------------------------------------------------------

=pod

=item * content()

Replies the content of the documentation
read by the parser.

=cut
sub content()  {
  my $self = shift ;
  return $self->{'CONTENT'} ;
}

=pod

=item * clearcontent()

Destoys the readed content and sets it
to the empty.

=cut
sub clearcontent()  {
  my $self = shift ;
  $self->{'CONTENT'} = { 'packages' => {},
                         'classes' => {} } ;
}

#------------------------------------------------------
#
# Main parsing functions
#
#------------------------------------------------------

=pod

=item * parse()

Parses the source files.
Takes 2 args:

=over

=item * file_list (array ref)

is an array that contains the names of the files and the
directories from which the parser must read the PHP sources.

=item * excluded_file_list (array ref)

is an array that contains the names of the files and the
directories that the parser must ignore.

=back

=cut
sub parse($$)  {
  my $self = shift ;
  $self->clearcontent() ;
  if ( isarray($_[0]) ) {
    foreach my $file (@{$_[0]}) {
      $file = File::Spec->canonpath( $file ) ;
      if ( -d $file ) {
	$self->readdirectory( $file, $_[1] ) ;
      }
      elsif ( ! strinarray( $file, $_[1] ) ) {
	$self->readfile( $file ) ;
      }
      else {
	PhpDocGen::General::Verbose::two( "Skip $_[0]...\n" ) ;
      }
    }
  }
  return $self->content() ;
}

=pod

=item * readdirectory()

Reads the content of a directory.
Takes 1 arg:

=over

=item * name (string)

is the name of the directory to read.

=item * excluded_file_list (array ref)

is an array that contains the names of the files and the
directories that the parser must ignore.

=back

=cut
sub readdirectory($$)  {
  my $self = shift ;
  my $dir = $_[0] ;
  if ( $dir ) {
    $dir = File::Spec->canonpath( $dir ) ;
    if ( ! strinarray( $dir, $_[1] ) ) {
      PhpDocGen::General::Verbose::two( "Scan directory $dir...\n" ) ;
      foreach my $file (glob File::Spec->catfile("$dir","*") ) {
	$file = File::Spec->canonpath($file) ;
	if ( ( -d $file ) &&
	     ( $self->{'RECURSE'} ) ) {
	  $self->readdirectory( $file, $_[1] ) ;
	}
	elsif ( $file =~ /$self->{'FILTERS'}/ ) {
	  if ( ! strinarray( $file, $_[1] ) ) {
	    $self->readfile( $file ) ;
	  }
	  else {
	    PhpDocGen::General::Verbose::two( "Skip $file...\n" ) ;
	  }
	}
      }
    }
    else {
      PhpDocGen::General::Verbose::two( "Skip directory $dir...\n" ) ;
    }
  }
}

=pod

=item * readfile()

Reads the content of a file.
Takes 1 arg:

=over

=item * name (string)

is the name of the file to read.

=back

=cut
sub readfile($)  {
  my $self = shift ;

  if ( $_[0] ) {
    PhpDocGen::General::Verbose::two( "Read $_[0]...\n" ) ;

    # extracts the parts of the sources
    my @content = $self->extract_source_parts( $_[0] ) ;

    # Parses each part of the source
    $self->parse_comment( \@content, $_[0] ) ;
  }
}

#------------------------------------------------------
#
# Extraction of the source parts
#
#------------------------------------------------------

=pod

=item * extract_source_parts()

Replies an array that contains the source
part readed from the source file.
A source part is a comment or a block of code.
Takes 1 arg:

=over

=item * filename (string)

is the name of the file from which the source parts must
be extracted.

=back

=cut
sub extract_source_parts($)  {
  my $self = shift ;

  PhpDocGen::General::Verbose::three( "\tExtracting the blocks..." ) ;
  my $bscan ;
  if ( $self->{'SCANNER_CLASSNAME'} ) {
    PhpDocGen::General::Error::syswarm( "**** use of the extended scanner ".
					$self->{'SCANNER_CLASSNAME'} ) ;
    eval "require ".$self->{'SCANNER_CLASSNAME'}.";" ;
    if ( $@ ) {
      PhpDocGen::General::Error::syserr( "Unable to load the extended scanner" ) ;
    }
    $bscan = ($self->{'SCANNER_CLASSNAME'})->new() ;
  }
  else {
    $bscan = PhpDocGen::Parser::BlockScanner->new() ;
  }
  # Display the copyright string
  my $funcref = $bscan->can( 'get_copyright' ) ;
  if ( $funcref ) {
    my $copyright_text = $bscan->$funcref() ;
    if ( $copyright_text ) {
      $copyright_text =~ s/^/ * /gm ;
      $copyright_text =~ s/\n+$/\n/ ;
      PhpDocGen::General::Verbose::one( $copyright_text ) ;
    }
  }

  return $bscan->scanblocks( $_[0] ) ;
}

#------------------------------------------------------
#
# Comment parsing
#
#------------------------------------------------------

=pod

=item * parse_comment()

Parses the specified comment and fills the
content of the documentation.
Takes 2 args:

=over

=item * blocks (array ref)

is the list of the blocks extracted
from the source file.

=item * filename (string)

is the name of the file from which the
blocks was extracted.

=back

=cut
sub parse_comment($$) {
  my $self = shift ;

  PhpDocGen::General::Verbose::three( "\tParsing the blocks..." ) ;

  # Parses the content of the comment
  my $ext = PhpDocGen::Parser::CommentExtractor->new( $self->{'CONTENT'},
						      $self->{'VERBATIM'},
						      $self->{'DEFAULT_PACKAGE'} ) ;
  $ext->extract( $_[0],
		 $_[1] ) ;
}

#------------------------------------------------------
#
# Statictic functions
#
#------------------------------------------------------

=pod

=item * get_package_count()

Replies the quantity of packages currently readed.

=cut
sub get_package_count()  {
  my $self = shift ;
  return hashcount( $self->{'CONTENT'}{'packages'} ) ;
}

=pod

=item * get_class_count()

Replies the quantity of classes currently readed.

=cut
sub get_class_count()  {
  my $self = shift ;
  return hashcount( $self->{'CONTENT'}{'classes'} ) ;
}

=pod

=item * get_constant_count()

Replies the quantity of constants currently readed.

=cut
sub get_constant_count()  {
  my $self = shift ;
  my $count = 0 ;
  foreach my $pack ( keys %{$self->{'CONTENT'}{'packages'}} ) {
    $count += hashcount($self->{'CONTENT'}{'packages'}{$pack}{'constants'}) ;
  }
  return $count ;
}

=pod

=item * get_variable_count()

Replies the quantity of variables currently readed.

=cut
sub get_variable_count()  {
  my $self = shift ;
  my $count = 0 ;
  foreach my $pack ( keys %{$self->{'CONTENT'}{'packages'}} ) {
    $count += hashcount($self->{'CONTENT'}{'packages'}{$pack}{'variables'}) ;
  }
  return $count ;
}

=pod

=item * get_function_count()

Replies the quantity of functions currently readed.

=cut
sub get_function_count()  {
  my $self = shift ;
  my $count = 0 ;
  foreach my $pack ( keys %{$self->{'CONTENT'}{'packages'}} ) {
    $count += hashcount($self->{'CONTENT'}{'packages'}{$pack}{'functions'}) ;
  }
  return $count ;
}

=pod

=item * get_method_count()

Replies the quantity of methods currently readed.

=cut
sub get_method_count()  {
  my $self = shift ;
  my $count = 0 ;
  foreach my $class ( keys %{$self->{'CONTENT'}{'classes'}} ) {
    $count += hashcount($self->{'CONTENT'}{'classes'}{$class}{'methods'}) ;
  }
  return $count ;
}

=pod

=item * get_attribute_count()

Replies the quantity of attributes currently readed.

=cut
sub get_attribute_count()  {
  my $self = shift ;
  my $count = 0 ;
  foreach my $class ( keys %{$self->{'CONTENT'}{'classes'}} ) {
    $count += hashcount($self->{'CONTENT'}{'classes'}{$class}{'attributes'}) ;
  }
  return $count ;
}

=pod

=item * get_constructor_count()

Replies the quantity of constructors currently readed.

=cut
sub get_constructor_count()  {
  my $self = shift ;
  my $count = 0 ;
  foreach my $class ( keys %{$self->{'CONTENT'}{'classes'}} ) {
    if ( exists $self->{'CONTENT'}{'classes'}{$class}{'constructor'} ) {
      $count ++ ;
    }
  }
  return $count ;
}

=pod

=item * get_web_count()

Replies the quantity of webmodules and webpages currently readed.

=cut
sub get_web_count()  {
  my $self = shift ;
  my ($count_mod,$count_page) = (0,0) ;
  my $src ;
  if ( defined( $_[0] ) ) {
    $src = $_[0] ;
  }
  else {
    $src = $self->{'CONTENT'}{'webmodules'} ;
  }
  foreach my $mod ( keys %{$src} ) {
    if ( exists $src->{$mod}{'this'} ) {
      $count_mod ++ ;
    }
    if ( exists $src->{$mod}{'pages'} ) {
      $count_page ++ ;
    }
    if ( exists $src->{$mod}{'submodules'} ) {
      my ($c1,$c2) = $self->get_web_count($src->{$mod}{'submodules'}) ;
      $count_mod += $c1 ;
      $count_page += $c2 ;
    }
  }
  return ($count_mod,$count_page) ;
}

=pod

=item * contentstats()

Replies a string that contains the stastics about
the current content.

=cut
sub contentstats()  {
  my $self = shift ;
  my $npack = $self->get_package_count() ;
  my $nclass = $self->get_class_count() ;
  my $nconst = $self->get_constant_count() ;
  my $nvar = $self->get_variable_count() ;
  my $nfunc = $self->get_function_count() ;
  my $nmeth = $self->get_method_count() ;
  my $nclassconst = $self->get_constructor_count() ;
  my $nattr = $self->get_attribute_count() ;
  my ($nwebmod,$nwebpage) = $self->get_web_count() ;
  return join( '',
               "Statistics:\n\t",
               $npack,
	       " package",
	       ($npack>1)?"s":"",
	       "\n\t",
               $nclass,
	       " class",
	       ($nclass>1)?"es":"",
	       "\n\t",
               $nconst,
	       " constant",
	       ($nconst>1)?"s":"",
	       "\n\t",
               $nvar,
	       " variable",
	       ($nvar>1)?"s":"",
	       "\n\t",
               $nfunc,
	       " function",
	       ($nfunc>1)?"s":"",
	       "\n\t",
               $nmeth,
	       " method",
	       ($nmeth>1)?"s":"",
	       "\n\t",
               $nclassconst,
	       " constructor",
	       ($nclassconst>1)?"s":"",
	       "\n\t",
               $nattr,
	       " attribute",
	       ($nattr>1)?"s":"",
	       "\n\t",
               $nwebmod,
	       " webmodule",
	       ($nwebmod>1)?"s":"",
	       "\n\t",
               $nwebpage,
	       " webpage",
	       ($nwebpage>1)?"s":"",
	       "\n" ) ;
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

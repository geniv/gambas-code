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

PhpDocGen::Parser::CommentExtractor - A extracting parser for PHP comments

=head1 SYNOPSYS

use PhpDocGen::Parser::CommentExtractor ;

my $scan = PhpDocGen::Parser::CommentExtractor->new(
                          existing_content,
                          verbatim,
			  default_package ) ;

=head1 DESCRIPTION

PhpDocGen::Parser::CommentExtractor is a Perl module, which parses
comments and adds them inside a documentation description.

=head1 GETTING STARTED

=head2 Initialization

To start a parser, say something like this:

    use PhpDocGen::Parser::CommentExtractor;

    my $scan = PhpDocGen::Parser::CommentExtractor->new(
                         { 'packages' => {},
			   'classes' => {},
			 },
			 1,
			 "Pack",
                       ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * existing_content (hash ref)

is an associative array that contains a documentation
description in which this extractor must put the
comments it found.

=item * verbatim (boolean)

is true if all the comment must have by default the
verbatim flag set.

=item * default_package (string)

is the name of the package which will be used
when a tag @package will be not found.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in CommentExtractor.pm itself.

=over

=cut

package PhpDocGen::Parser::CommentExtractor;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp;

use PhpDocGen::General::Misc ;
use PhpDocGen::General::Token ;
use PhpDocGen::General::Error ;
use PhpDocGen::Parser::SourceExtractor ;
use PhpDocGen::Parser::CommentBuilder ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the parser
my $VERSION = "0.8" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$$)  {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $parent = ref($proto) && $proto ;

  my $self ;
  if ( $parent ) {
    %{$self} = %{$parent} ;
  }
  else {
    $self = { 'COMMENT_DESCRIPTION' => $_[0],
    	      'CONTEXT' => [],
	      'VERBATIM' => $_[1],
	      'DEFAULT_PACKAGE' => $_[2],
    	    } ;
  }
  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Extracting functions
#
#------------------------------------------------------

=pod

=item * extract()

Extracts a documentation description from
the specified comment and source code.
Takes 2 args:

=over

=item * blocks (array ref)

is the list of the blocks extracted
from the source file.

=item * filename (string)

is the name of the file from which the
comment was extracted.

=back

=cut
sub extract($$)  {
  my $self = shift ;
  my ( $blocks, $filename ) = ( $_[0], $_[1] ) ;

  # Counts the braces in the source codes
  foreach my $block (@{$blocks}) {
    $self->_countbraces( $block ) ;
  }

  # Parses the comments
  foreach my $block (@{$blocks}) {
    $self->parse_comment( $block, $filename ) ;
  }
}

=pod

=item * parse_comment()

PArses the specified comment and fills
the documentation content.
Takes 2 args:

=over

=item * block (hash ref)

is the description of a block to parse.

=item * filename (string)

is the name of the file where the block was found.

=back

=cut
sub parse_comment($$)  {
  my $self = shift ;
  my ( $block, $filename ) = ( $_[0],
			       $_[1] || '' ) ;

  confess( 'invalid extracted source block' ) unless ( ishash($block) ) ;

  # Extracts the parts of the comment
  my %comment = $self->_extract_comment_parts( $block, $filename ) ;

  # Adds the code for futher uses
  $comment{'@sourcecode'} = $block->{'code'} ;

  # Builds the documentation for the
  # parts of the comment
  $self->_build_comments( \%comment, $filename ) ;
}

=pod

=item * _build_comments()

Builds the comments from the specified comment parts.
Takes 2 args:

=over

=item * parts (hash ref)

is the description of the extracted parts.

=item * filename (string)

is the name of the file where the parts was found.

=back

=cut
sub _build_comments($$)  {
  my $self = shift ;
  my ( $parts, $filename ) = ( $_[0],
			       $_[1] || '' ) ;

  confess( 'invalid extracted comment' ) unless ( ishash($parts) ) ;

  my $builder = PhpDocGen::Parser::CommentBuilder->new( $self->{'COMMENT_DESCRIPTION'},
							$self->{'DEFAULT_PACKAGE'} ) ;
  $builder->build( $parts, $filename ) ;
}

=pod

=item * _extract_comment_parts()

Parses the specified comment and replies
an associative array that contains the
parts of the comment.
Takes 2 args:

=over

=item * block (hash ref)

is the description of a block to parse.

=item * filename (string)

is the name of the file where the block was found.

=back

=cut
sub _extract_comment_parts($$)  {
  my $self = shift ;
  my ( $block, $filename ) = ( $_[0],
			       $_[1] || '' ) ;
  my $currentline = $block->{'lineno'} || 0 ;

  confess( 'invalid extracted source block' ) unless ( ishash($block) ) ;

  # Removes trailing whitespaces
  $block->{'comment'} =~ s/[ \t]+$//gm ;

  #
  # Splits the comment
  #
  my $tgs = "" ;
  foreach my $t ( keys(%COMMON_SECTIONED_TAGS),
  	     	  @COMMON_TAGS,
		  @{get_all_comment_types()},
		  @OTHER_TAGS ) {
    if ( $tgs ) {
      $tgs .= "|" ;
    }
    $tgs .= "(?:\@$t)" ;
  }
  my @parts = split( /((?:\s+\@[a-zA-Z]+\s+)|(?:^\@[a-zA-Z]+\s+)|(?:^\@[a-zA-Z]+$)|(?:\s+\@[a-zA-Z]+$))/m, $block->{'comment'} ) ;
  #
  # Scan the comment parts
  #
  my $currenttag = "" ;
  my %comment = () ;

  foreach my $p (@parts) {
    if ( defined( $p ) ) {
      my $lineshift = 0 ;
      $lineshift++ while ( $p =~ /\n/g ) ;

      # Remove enclosing whitespaces
      $p =~ s/^\s+// ;
      $p =~ s/\s+$// ;
      if ( $p ) {
	if ( $p =~ /^\s*\@[a-zA-Z]+\s*$/ ) {
	  # This element is a tag
	  if ( ( $currenttag ) &&
	       ( ! exists $comment{$currenttag} ) ) {
	    $comment{$currenttag} = '' ;
	  }
	  $currenttag = get_real_tag( lc($p) ) ;
	} else {
	  # This element is a user text of the tag's parameters
	  if ( $currenttag ) {
	    if ( $currenttag !~ /$tgs/ ) {
	      # This element is not for a recognized tag
	      PhpDocGen::General::Error::warm( "the tag '$currenttag' is not supported. It will be ignored.",
					       $filename,
					       $currentline ) ;
	    }
	    $p = "($currentline)$p" ;
	    add_value_entry( \%comment, $currenttag, $p ) ;
	  } else {
	    $p =~ s/^\s+// ; # Be sure that
                             # begining white spaces
                             # are removed
	    $comment{'@explanation'} = "(".$block->{'lineno'}.")$p" ;
	  }
	}
      }
      $currentline += $lineshift ;
    }
  }
  if ( ( $currenttag ) &&
       ( ! exists $comment{$currenttag} ) ) {
    $comment{$currenttag} = "($currentline)" ;
  }
  $comment{'@lineno'} = $block->{'lineno'} ;

  #
  # Adds default tags
  #
  if ( ( $self->{'VERBATIM'} ) && ( ! $comment{'@verbatim'} ) ) {
    $comment{'@verbatim'} = "(".$block->{'lineno'}.")" ;
  }

  #
  # Scans the source code if no comment type given
  #
  my $comment_type = get_comment_type( \%comment ) ;
  if ( ! $comment_type ) {
    $self->_scan_sourcecode( \%comment, $block, $filename ) ;
    $comment_type = get_comment_type( \%comment ) ;
  }

  #
  # Be sure that the container tag was present
  #
  if ( ( $comment_type ) &&
       ( ( $comment_type eq 'attribute' ) ||
	 ( $comment_type eq 'variable' ) ||
	 ( $comment_type eq 'method' ) ) &&
       ( ! $comment{'@class'} ) ) {
    my $context = $self->getcontext() ;
    if ( $context ) {
      $comment{'@class'} = $context ;
    }
    elsif ( $comment_type ne 'variable' ) {
      err( "Unable to detect the current class context",
	   $filename, $currentline ) ;
    }
  }

  #
  # Changes the context
  # TODO: the detection of an context change
  # must be review
  #
  if ( ( $comment_type ) &&
       ( $comment_type eq "class" ) ) {
    $self->addcontext( $self->__nolineno($comment{'@class'}) ) ;
  }
  $self->changecontextbraces( $block->{'bracecount'} ) ;
  return %comment ;
}

=pod

=item * _scan_sourcecode()

Parses the specified source code to
extract a comment type.
Takes 3 args:

=over

=item * comment (hash ref)

is the already parsed comment result.

=item * block (hash ref)

is the description of a block to parse.

=item * filename (string)

is the name of the file where the block was found.

=back

=cut
sub _scan_sourcecode($$$)  {
  my $self = shift ;
  my ( $comment, $block, $filename ) = ( $_[0],
					 $_[1],
					 $_[2] || '' ) ;

  confess( 'invalid extracted comment' ) unless ( ishash($comment) ) ;
  confess( 'invalid extracted source block' ) unless ( ishash($block) ) ;

  my $context = $self->getcontext() ;

  my $src = PhpDocGen::Parser::SourceExtractor->new() ;
  $src->parse( $block->{'code'},
  	       $comment,
  	       $context,
	       $filename,
	       $block->{'lineno'} ) ;
}

#------------------------------------------------------
#
# Context functions
#
#------------------------------------------------------

=pod

=item * getcontext()

Replies the current context. A context is
the name of the class in which the parser
is.

=cut
sub getcontext()  {
  my $self = shift ;
  if ( @{$self->{'CONTEXT'}} > 0 ) {
    return $self->{'CONTEXT'}[$#{$self->{'CONTEXT'}}]{'name'} ;
  }
  else {
    return ;
  }
}

=pod

=item * addcontext()

Adds a context.
Takes 1 arg:

=over

=item * name (string)

is the name of the context to add.

=back

=cut
sub addcontext($)  {
  my $self = shift ;
  my %layer = ( 'name' => $_[0] || confess( 'invalid context name' ),
     	      	'braces' => 0, ) ;
  push( @{$self->{'CONTEXT'}}, \%layer ) ;
}

=pod

=item * changecontextbraces()

Changes the context according to the braces.
Takes 1 arg:

=over

=item * quantity (integer)

is the quantity of context to remove.

=back

=cut
sub changecontextbraces($)  {
  my $self = shift ;
  my $nbraces = $_[0] || 0 ;
  my $context = $self->{'CONTEXT'}[$#{$self->{'CONTEXT'}}] ;
  my $n ;
  if ( $context ) {
    $n = $context->{'braces'} + $nbraces ;
  }
  else {
    $n = $nbraces ;
  }
  if ( $n > 0 ) {
    $context->{'braces'} = $n ;
  }
  else {
    pop( @{$self->{'CONTEXT'}} ) ;
  }
}

#------------------------------------------------------
#
# Utility functions
#
#------------------------------------------------------

=pod

=item * _countbraces()

Counts the opened and closed braces inside
a block. This method adds the key 'bracecount'
inside the specified parameter.
Takes 1 arg:

=over

=item * block (hash ref)

is the associative array that contains
a block (the key 'code' is required).

=back

=cut
sub _countbraces($)  {
  my $self = shift ;
  my $block = $_[0] ;

  confess( 'invalid extracted source block' ) unless ( ishash($block) ) ;

  my $code = $block->{'code'} || '' ;

  # Remove the strings
  $self->replacePHPstrings( $code, 0 ) ;

  # Counts the braces
  my $count = 0 ;
  while ( $code =~ /(\{|\})/g ) {
    if ( $1 eq "{" ) {
      $count ++ ;
    }
    else {
      $count -- ;
    }
  }

  $block->{'bracecount'} = $count ;
}

=pod

=item * replacePHPstrings()

Removes the PHP strings and replaces them
by an index to an array that contains the
removed strings.
Takes 2 args:

=over

=item * string (string)

is the string to change.

=item * storage (array ref)

if is an array, the removed strings will be
stored inside it. Else, the removed strings
are simply removed and not replaced (caution:
the resulting string is no longer PHP syntax
compliant).

=back

=cut
sub replacePHPstrings($$)  {
  my $self = shift ;
  my $delims= "\\\"|\\'" ;
  my $index = (isarray($_[1])) ? $#{$_[1]} : 0 ;
  $_[0] = '' unless $_[0] ;
  while ( $_[0] =~ /($delims)/ ) {
    my $delim = $1 ;
    my $repstr = "" ;
    if ( isarray($_[1]) ) {
      if ( ! ( $_[0] =~ s/ ( $delim
      	       	     	     (\\$delim|[^$delim])*
			     $delim)/
			   $_[1][++$index]="$1";
			   "<<STRING".$index.">>";
			 /ex ) ) {
        if ( $delim =~ /\"/ ) {
	  $_[0] =~ s/$delim/<<DOUBLEQUOTE>>/ ;
        }
        else {
	  $_[0] =~ s/$delim/<<SIMPLEQUOTE>>/ ;
        }
      }
    }
    else {
      if ( ! ( $_[0] =~ s/ ( $delim
      	       	     	     (\\$delim|[^$delim])*
		    	     $delim)//x ) ) {
        if ( $delim =~ /\"/ ) {
	  $_[0] =~ s/$delim/<<DOUBLEQUOTE>>/ ;
        }
        else {
	  $_[0] =~ s/$delim/<<SIMPLEQUOTE>>/ ;
        }
      }
    }
  }
}

#------------------------------------------------------
#
# Private API
#
#------------------------------------------------------

=pod

=item * __nolineno()

Replies the specified string without the line number.
Takes 1 arg:

=over

=item * str (string)

is the string to parse.

=back

=cut
sub __nolineno($)  {
  my $self = shift ;
  $_[0] = '' unless $_[0] ;
  if ( $_[0] =~ /^\([0-9]+\)(.*)$/s ) {
    return $1 ;
  }
  else {
    return $_[0] ;
  }
}

=pod

=item * __lineno()

Replies the line number from the specified string.
Takes 1 arg:

=over

=item * str (string)

is the string to parse.

=back

=cut
sub __lineno($)  {
  my $self = shift ;
  $_[0] = '' unless $_[0] ;
  if ( $_[0] =~ /^\(([0-9]+)\).*$/s ) {
    return $1 ;
  }
  else {
    return 0 ;
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

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

PhpDocGen::Parser::SourceExtractor - A simple extracting parser for PHP source codes

=head1 SYNOPSYS

use PhpDocGen::Parser::SourceExtractor ;

my $scan = PhpDocGen::Parser::SourceExtractor->new() ;

=head1 DESCRIPTION

PhpDocGen::Parser::SourceExtractor is a Perl module, which parses
source codes and adds recognized tokens inside a documentation description.

=head1 GETTING STARTED

=head2 Initialization

To start a parser, say something like this:

    use PhpDocGen::Parser::SourceExtractor;

    my $scan = PhpDocGen::Parser::SourceExtractor->new() ;

...or something similar.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in SourceExtractor.pm itself.

=over

=cut

package PhpDocGen::Parser::SourceExtractor;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;

use PhpDocGen::General::Misc ;
use PhpDocGen::General::Token ;
use PhpDocGen::General::Error ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the parser
my $VERSION = "0.3" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new()  {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $parent = ref($proto) && $proto ;

  my $self ;
  if ( $parent ) {
    %{$self} = %{$parent} ;
  }
  else {
    $self = { } ;
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

=item * parse()

Parses the specified source code to
extract a comment type.
Takes 4 args:

=over

=item * block (string)

is the description of a block to parse.

=item * comment (hash ref)

is the already parsed comment result.

=item * context (string)

is the name of the current context, i.e.
the name of the class in which the document is.

=item * filename (string)

is the name of the file where the block was found.

=item * lineno (integer)

is the line number which must be added to
the entries added by this parser. It corresponds
to the begining of the current analyzed comment.

=back

=cut
sub parse($$$$$) {
  my $self = shift ;
  my ( $comment, $block ) = ( $_[1], $_[0] || '' ) ;

  confess( 'invalid already-parsed comment' ) unless ( ishash($comment) ) ;

  my ( $context, $filename ) = ( $_[2] || '',
				 $_[3] || '' ) ;
  my $lineno = $_[4] || 0 ;
  foreach my $type_tag (@{get_all_comment_types()}) {
    my $funcref = $self->can( 'extract_source_'.$type_tag ) ;
    if ( $funcref ) {
      if ( $self->$funcref( $block, $comment,
      	   		    $context, $filename,
			    $lineno ) ) {
        return ;
      }
    }
    else {
      PhpDocGen::General::Error::syserr( join( '',
			    	    "unable to find the function ",
				    ref($self),
				    "::extract_source_",
				    $type_tag,
				    "(), which permits to ",
		  		    "extract a comment type ",
				    "from the source code." ) ) ;
    }
  }
}

#------------------------------------------------------
#
# Overridable functions
#
#------------------------------------------------------

=pod

=item * extract_source_webmodule()

Tries to extract a webmodule definition
from the specified source code.
Takes 5 args:

=over

=item * block (hash ref)

is the description of a block to parse.

=item * comment (hash ref)

is the already parsed comment result.

=item * context (string)

is the name of the current context, i.e.
the name of the class in which the document is.

=item * filename (string)

is the name of the file where the block was found.

=item * lineno (integer)

is the line number which must be added to
the entries added by this parser. It corresponds
to the begining of the current analyzed comment.

=back

=cut
sub extract_source_webmodule($$$$$) {
  return undef ;
}

=pod

=item * extract_source_webpage()

Tries to extract a webpage definition
from the specified source code.
Takes 5 args:

=over

=item * block (hash ref)

is the description of a block to parse.

=item * comment (hash ref)

is the already parsed comment result.

=item * context (string)

is the name of the current context, i.e.
the name of the class in which the document is.

=item * filename (string)

is the name of the file where the block was found.

=item * lineno (integer)

is the line number which must be added to
the entries added by this parser. It corresponds
to the begining of the current analyzed comment.

=back

=cut
sub extract_source_webpage($$$$$) {
  return undef ;
}

=pod

=item * extract_source_constant()

Tries to extract a constant definition
from the specified source code.
Takes 5 args:

=over

=item * block (hash ref)

is the description of a block to parse.

=item * comment (hash ref)

is the already parsed comment result.

=item * context (string)

is the name of the current context, i.e.
the name of the class in which the document is.

=item * filename (string)

is the name of the file where the block was found.

=item * lineno (integer)

is the line number which must be added to
the entries added by this parser. It corresponds
to the begining of the current analyzed comment.

=back

=cut
sub extract_source_constant($$$$$) {
  my $self = shift ;
  my ( $comment, $block ) = ( $_[1], $_[0] || '' ) ;

  confess( 'invalid already-parsed comment' ) unless ( ishash($comment) ) ;

  my ( $context, $filename ) = ( $_[2] || '',
				 $_[3] || '' ) ;
  my $lineno = $_[4] || 0 ;

  $block =~ s/^[\s\n\r]+// ;

  # A constant could be a uppercased variable:
  # $CONSTANT = ...
  if ( ( ! $context ) &&
       ( $block =~ /^\s*\$(\w+)/s ) ) {
    my $name = $1 ;
    if ( $name eq uc( $name ) ) {
      if ( ! $comment->{'@constant'} ) {
        $comment->{'@constant'} = "($lineno)mixed $name" ;
      }
      return '@constant' ;
    }
  }
  # A constant could be a definition
  # define ( CONSTANT , ...
  if ( ( ! $context ) &&
       ( $block =~ /^\s*define\s*\(\s*(\w+)\s*/s ) ) {
    my $name = $1 ;
    if ( ! $comment->{'@constant'} ) {
      $comment->{'@constant'} = "($lineno)mixed $name" ;
    }
    return '@constant' ;
  }
  return undef ;
}

=pod

=item * extract_source_variable()

Tries to extract a variable definition
from the specified source code.
Takes 5 args:

=over

=item * block (hash ref)

is the description of a block to parse.

=item * comment (hash ref)

is the already parsed comment result.

=item * context (string)

is the name of the current context, i.e.
the name of the class in which the document is.

=item * filename (string)

is the name of the file where the block was found.

=item * lineno (integer)

is the line number which must be added to
the entries added by this parser. It corresponds
to the begining of the current analyzed comment.

=back

=cut
sub extract_source_variable($$$$$) {
  my $self = shift ;
  my ( $comment, $block ) = ( $_[1], $_[0] || '' ) ;

  confess( 'invalid already-parsed comment' ) unless ( ishash($comment) ) ;

  my ( $context, $filename ) = ( $_[2] || '',
				 $_[3] || '' ) ;
  my $lineno = $_[4] || 0 ;

  $block =~ s/^[\s\n\r]+// ;

  # A variable must not be all uppercased:
  # $Constant = ...
  if ( ( ! $context ) &&
       ( $block =~ /^\s*\$(\w+)/s ) ) {
    my $name = $1 ;

    if ( $name ne uc( $name ) ) {
      if ( ! $comment->{'@variable'} ) {
        $comment->{'@variable'} = "($lineno)mixed $name" ;
      }
      return '@variable' ;
    }
  }
  return undef ;
}

=pod

=item * extract_source_function()

Tries to extract a function definition
from the specified source code.
Takes 5 args:

=over

=item * block (hash ref)

is the description of a block to parse.

=item * comment (hash ref)

is the already parsed comment result.

=item * context (string)

is the name of the current context, i.e.
the name of the class in which the document is.

=item * filename (string)

is the name of the file where the block was found.

=item * lineno (integer)

is the line number which must be added to
the entries added by this parser. It corresponds
to the begining of the current analyzed comment.

=back

=cut
sub extract_source_function($$$$$) {
  my $self = shift ;
  my ( $comment, $block ) = ( $_[1], $_[0] || '' ) ;

  confess( 'invalid already-parsed comment' ) unless ( ishash($comment) ) ;

  my ( $context, $filename ) = ( $_[2] || '',
				 $_[3] || '' ) ;
  my $lineno = $_[4] || 0 ;

  $block =~ s/^[\s\n\r]+// ;

  # A function is outside a class context,
  # and must respect:
  # function [&]name
  if ( ( ! $context ) &&
       ( $block =~ /^\s*function\s+(&?)\s*(\w+)/s ) ) {
    my $byref = ( $1 eq '&' ) ;
    my $name = $2 ;
    if ( ! $comment->{'@function'} ) {
      $comment->{'@function'} = "($lineno)$name" ;
    }
    if ( $byref ) {
      if ( ( exists $comment->{'@return'} ) &&
	   ( $comment->{'@return'} =~ /^\(([0-9]+)\)\s*(.*)$/s ) ) {
	my $lineno = $1 ;
	my $text = $2 ;
	if ( ( $text !~ /^reference\s*$/s ) &&
	     ( $text !~ /^ref\s*$/s ) &&
	     ( $text !~ /^reference\s+/s ) &&
	     ( $text !~ /^ref\s+/s ) ) {
	  $comment->{'@return'} = "($lineno)reference $text" ;
	}
      }
      else {
	$comment->{'@return'} = "($lineno)reference" ;
      }
    }
    return '@function' ;
  }
  return undef ;
}

=pod

=item * extract_source_attribute()

Tries to extract an attribute definition
from the specified source code.
Takes 5 args:

=over

=item * block (hash ref)

is the description of a block to parse.

=item * comment (hash ref)

is the already parsed comment result.

=item * context (string)

is the name of the current context, i.e.
the name of the class in which the document is.

=item * filename (string)

is the name of the file where the block was found.

=item * lineno (integer)

is the line number which must be added to
the entries added by this parser. It corresponds
to the begining of the current analyzed comment.

=back

=cut
sub extract_source_attribute($$$$$) {
  my $self = shift ;
  my ( $comment, $block ) = ( $_[1], $_[0] || '') ;

  confess( 'invalid already-parsed comment' ) unless ( ishash($comment) ) ;

  my ( $context, $filename ) = ( $_[2] || '',
				 $_[3] || '' ) ;
  my $lineno = $_[4] || 0 ;

  $block =~ s/^[\s\n\r]+// ;

  # An attribute is inside a class context,
  # and must respect:
  # var $name
  if ( ( $context ) &&
       ( $block =~ /^\s*var\s+\$(\w+)/s ) ) {
    my $name = $1 ;
    if ( ! $comment->{'@attribute'} ) {
      $comment->{'@attribute'} = "($lineno)mixed $name" ;
    }
    if ( ! $comment->{'@class'} ) {
      $comment->{'@class'} = "($lineno)$context" ;
    }
    return '@attribute' ;
  }
  return undef ;
}

=pod

=item * extract_source_method()

Tries to extract a method definition
from the specified source code.
Takes 5 args:

=over

=item * block (hash ref)

is the description of a block to parse.

=item * comment (hash ref)

is the already parsed comment result.

=item * context (string)

is the name of the current context, i.e.
the name of the class in which the document is.

=item * filename (string)

is the name of the file where the block was found.

=item * lineno (integer)

is the line number which must be added to
the entries added by this parser. It corresponds
to the begining of the current analyzed comment.

=back

=cut
sub extract_source_method($$$$$) {
  my $self = shift ;
  my ( $comment, $block ) = ( $_[1], $_[0] || '' ) ;

  confess( 'invalid already-parsed comment' ) unless ( ishash($comment) ) ;

  my ( $context, $filename ) = ( $_[2] || '',
				 $_[3] || '') ;
  my $lineno = $_[4] || 0 ;

  $block =~ s/^[\s\n\r]+// ;

  # A method is inside a class context,
  # and must respect:
  # function [&]name
  if ( ( $context ) &&
       ( $block =~ /^\s*function\s+(&?)\s*(\w+)/s ) ) {
    my $byref = ( $1 eq '&' ) ;
    my $name = $2 ;
    if ( ! $comment->{'@method'} ) {
      $comment->{'@method'} = "($lineno)$name" ;
    }
    if ( ! $comment->{'@class'} ) {
      $comment->{'@class'} = "($lineno)$context" ;
    }
    if ( $byref ) {
      if ( ( exists $comment->{'@return'} ) &&
	   ( $comment->{'@return'} =~ /^\(([0-9]+)\)\s*(.*)$/s ) ) {
	my $lineno = $1 ;
	my $text = $2 ;
	if ( ( $text !~ /^reference\s*$/s ) &&
	     ( $text !~ /^ref\s*$/s ) &&
	     ( $text !~ /^reference\s+/s ) &&
	     ( $text !~ /^ref\s+/s ) ) {
	  $comment->{'@return'} = "($lineno)reference $text" ;
	}
      }
      else {
	$comment->{'@return'} = "($lineno)reference" ;
      }
    }
    return '@method' ;
  }
  return undef ;
}

=pod

=item * extract_source_constructor()

Tries to extract a constructor definition
from the specified source code.
Takes 5 args:

=over

=item * block (hash ref)

is the description of a block to parse.

=item * comment (hash ref)

is the already parsed comment result.

=item * context (string)

is the name of the current context, i.e.
the name of the class in which the document is.

=item * filename (string)

is the name of the file where the block was found.

=item * lineno (integer)

is the line number which must be added to
the entries added by this parser. It corresponds
to the begining of the current analyzed comment.

=back

=cut
sub extract_source_constructor($$$$$) {
  my $self = shift ;
  my ( $comment, $block ) = ( $_[1], $_[0] || '' ) ;

  confess( 'invalid already-parsed comment' ) unless ( ishash($comment) ) ;

  my ( $context, $filename ) = ( $_[2] || '',
				 $_[3] || '' ) ;
  my $lineno = $_[4] || 0 ;

  $block =~ s/^[\s\n\r]+// ;

  # A constructor is inside a class context,
  # must have the same name as the context,
  # and must respect:
  # function [&]name
  if ( ( $context ) &&
       ( $block =~ /^\s*function\s+(\w+)/s ) ) {
    my $name = $1 ;    
    if ( lc($name) eq lc($context) ) {
      if ( ! $comment->{'@constructor'} ) {
        $comment->{'@constructor'} = "($lineno)$name" ;
      }
      return '@constructor' ;
    }
  }
  return undef ;
}

=pod

=item * extract_source_class()

Tries to extract a class definition
from the specified source code.
Takes 5 args:

=over

=item * block (hash ref)

is the description of a block to parse.

=item * comment (hash ref)

is the already parsed comment result.

=item * context (string)

is the name of the current context, i.e.
the name of the class in which the document is.

=item * filename (string)

is the name of the file where the block was found.

=item * lineno (integer)

is the line number which must be added to
the entries added by this parser. It corresponds
to the begining of the current analyzed comment.

=back

=cut
sub extract_source_class($$$$$) {
  my $self = shift ;
  my ( $comment, $block ) = ( $_[1], $_[0] || '') ;

  confess( 'invalid already-parsed comment' ) unless ( ishash($comment) ) ;

  my ( $context, $filename ) = ( $_[2] || '',
				 $_[3] || '' ) ;
  my $lineno = $_[4] || 0 ;

  $block =~ s/^[\s\n\r]+// ;

  # A class must respect:
  # class name [extends inherited_class]
  if ( $block =~ /^\s*class\s+(\w+)(?:\s+extends\s+(\w+))?/s ) {
    my ( $classname, $inherited ) = ( $1, $2 ) ;

    if ( ! $comment->{'@class'} ) {
      $comment->{'@class'} = "($lineno)$classname" ;
    }

    if ( ( ! $comment->{'@extends'} ) &&
       	 ( ! $comment->{'@inherited'} ) &&
       	 ( $inherited ) ) {
      $comment->{'@extends'} = "($lineno)$inherited" ;
    }

    return '@class' ;
  }

  return undef ;
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

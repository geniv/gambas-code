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

PhpDocGen::Parser::CommentBuilder - A builder of a PHP documentation

=head1 SYNOPSYS

use PhpDocGen::Parser::CommentBuilder ;

my $scan = PhpDocGen::Parser::CommentBuilder->new(
                           content,
                           default_package ) ;

=head1 DESCRIPTION

PhpDocGen::Parser::CommentBuilder is a Perl module, which generates
a documentation tree from a set of extracted comments.

=head1 GETTING STARTED

=head2 Initialization

To start a parser, say something like this:

    use PhpDocGen::Parser::CommentBuilder;

    my $scan = PhpDocGen::Parser::CommentBuilder->new( \%content, "Pack" ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * content (hash ref)

is an associative array that contains a documentation
description in which this extractor must put the
comments it found.

=item * default_package (string)

is the name of the package which will be used
when a tag @package will be not found.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in CommentBuilder.pm itself.

=over

=cut

package PhpDocGen::Parser::CommentBuilder;

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
use PhpDocGen::General::Parsing ;
use PhpDocGen::General::HTML ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the builder
my $VERSION = "0.7" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$)  {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $parent = ref($proto) && $proto ;

  my $self ;
  if ( $parent ) {
    %{$self} = %{$parent} ;
  }
  else {
    $self = { 'CONTENT' => $_[0],
              'DEFAULT_PACKAGE' => $_[1],
            } ;
  }
  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Building functions
#
#------------------------------------------------------

=pod

=item * build()

Builds the documentation tree.
Takes 2 args:

=over

=item * parts (hash ref)

is the description of the extracted parts.

=item * filename (string)

is the name of the file where the parts was found.

=back

=cut
sub build($$) {
  my $self = shift ;
  my ( $parts, $filename, $taglist ) = ( $_[0],
					 $_[1] || '',
					 '' ) ;
  confess( 'invalid source code parts' ) unless ( $parts && ishash($parts) ) ;
  my @main_list = () ;

  #
  # Checks if all information are given
  #
  foreach my $type_tag ( @{get_all_comment_types()} ) {
    if ( $taglist ) {
      $taglist .= ", " ;
    }
    $taglist .= '@'.$type_tag ;
    if ( $parts->{'@'.$type_tag} ) {
      my $funcref = $self->can( 'parse_comment_'.$type_tag ) ;
      if ( $funcref ) {
	my $elts ;
	if ( isarray( $parts->{'@'.$type_tag} ) ) {
	  $elts = $parts->{'@'.$type_tag} ;
	}
	else {
	  $elts = [ $parts->{'@'.$type_tag} ] ;
	}
	delete( $parts->{'@'.$type_tag} ) ;
	# Search the comment type
	foreach my $a_part (@{$elts}) {
	  my $main = $self->$funcref( $a_part, $parts, $filename ) ;
	  # Adds the new elements
	  if ( $main ) {
	    push @main_list, { 'type' => '@'.$type_tag,
			       'location' => $main,
			     } ;
	  }
	}
      }
      else {
	PhpDocGen::General::Error::syserr( join( '',
						 "unable to find the function ",
						 ref($self),
						 "::parse_comment_",
						 $type_tag,
						 "(), which permits to ",
						 "parse a comment for the tag ",
						 "\@$type_tag.\n" ) ) ;
      }
    }
  }
  # Check if more than once tag was found
  if ( ! @main_list  ) {
    PhpDocGen::General::Error::warm( join( '',
					   "unable to detect the type ",
					   "of the commented object. ",
					   "Attempt to find one of the tags: ".
					   $taglist ),
				     $filename,
				     $parts->{'@lineno'} ) ;
  }
  elsif ( @main_list > 1 ) {
    my $msg = '' ;
    foreach my $t ( @main_list ) {
      $msg .= join( '',
		    "\t",
		    $t->{'type'},
		    " (",
		    extract_file_from_location($t->{'location'}) || $filename,
		    ":",
		    extract_line_from_location($t->{'location'}) || $parts->{'@lineno'},
		    ")\n" ) ;
    }
    PhpDocGen::General::Error::err( join( '',
					  "I found more than once tag that ",
					  "set the type of the comment. Please ",
					  "check your comment and select one ",
					  "tag from :\n",
					  $msg ),
				    $filename,
				    $parts->{'@lineno'} ) ;
  }
}

#------------------------------------------------------
#
# Overridable functions
#
#------------------------------------------------------

=pod

=item * parse_comment_variable()

Tries to extract a global variable definition
from the specified extracted comment.
Takes 3 args:

=over

=item * tag (string)

is the tag that is currently analyzed.

=item * comment (hash ref)

is the comment parts readed from the input stream.

=item * filename (string)

is the name of the file where the parts was found.

=back

=cut
sub parse_comment_variable($$$) {
  my $self = shift ;
  my ( $tag, $comment, $filename ) = ( $_[0], $_[1], $_[2] || '' ) ;

  confess( 'invalid extracted variable comment' )
    unless ( $comment && ishash($comment) ) ;

  # According to a Cal's remark, the tag
  # @variable could be used to comment attributes
  if ( exists $comment->{'@class'} ) {
    return $self->parse_comment_attribute($tag,$comment,$filename) ;
  }
  else {

    my ( $lineno, $vardesc ) =
      ( $self->__lineno( $tag ),
	$self->__nolineno( $tag ) ) ;
    my $type = $self->_type( 1, $vardesc, $filename, $lineno ) ;
    my $var = extract_param( 2, $vardesc, 0 ) ;
    my $varcomment = extract_param( 3, $vardesc, 1 ) ;
    if ( ! $var ) {
      PhpDocGen::General::Error::err( "a name was expected after \@variable.\n",
				      $filename,
				      $lineno ) ;
    }
    my $varkey = formatvarkeyname( $var ) ;
    $var = unformatvarname($var) ;

    my ( $plineno, $package, $packagekey ) = $self->_getpackage( $comment,
								 $filename,
								 $lineno ) ;

    if ( exists $self->{'CONTENT'}{'packages'}{$packagekey}{'variables'}{$varkey} ) {
      PhpDocGen::General::Error::warm( join( '',
					     "multi definition of the variable \$",
					     $var,
					     " inside the package ",
					     $package,
					     ".\n" ),
				       $filename,
				       $lineno ) ;
    }

    # Sets the package
    if ( ( exists $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} ) &&
	 ( ! ( $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} eq $package ) ) ) {
      PhpDocGen::General::Error::warm( join( '',
					     "The package of the variable ",
					     $var,
					     " have already a name: ",
					     $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} ),
				       $filename,
				       $plineno ) ;
    }

    # Sets the variable
    my %me = ( 'name' => $var,
	       'type' => $type,
	       'location' => $self->_location( $filename, $lineno ),
	     ) ;

    $self->_commontags( \%me, $comment, $filename ) ;
    $self->_build_explanation( \%me,
			       $varcomment,
			       $comment,
			       $filename ) ;

    # Update of the content
    $self->{'CONTENT'}{'packages'}{$packagekey}{'variables'}{$varkey} = \%me ;
    $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} = $package ;

    return $me{'location'} ;
  }
}

=pod

=item * parse_comment_constant()

Tries to extract a global constant definition
from the specified extracted comment.
Takes 3 args:

=over

=item * tag (string)

is the tag that is currently analyzed.

=item * comment (hash ref)

is the comment parts readed from the input stream.

=item * filename (string)

is the name of the file where the parts was found.

=back

=cut
sub parse_comment_constant($$$) {
  my $self = shift ;
  my ( $tag, $comment, $filename ) = ( $_[0] || '',
				       $_[1],
				       $_[2] || '' ) ;

  confess( 'invalid extracted constant comment' )
    unless ( $comment && ishash($comment) ) ;

  my ( $lineno, $cstdesc ) = ( $self->__lineno( $tag ),
			       $self->__nolineno( $tag ) ) ;
  my $type = $self->_optional_type( 1, $cstdesc ) ;
  my ($cst, $cstcomment) ;
  if ( $type ) {
    $cst = extract_param( 2, $cstdesc, 0 ) ;
    $cstcomment = extract_param( 3, $cstdesc, 1 ) ;
  }
  else {
    $cst = extract_param( 1, $cstdesc, 0 ) ;
    $cstcomment = extract_param( 2, $cstdesc, 1 ) ;
  }
  if ( ! $cst ) {
    PhpDocGen::General::Error::err( "a name was expected after \@constant.\n",
	      		 $filename,
			 $lineno ) ;
  }
  my $cstkey = formatvarkeyname( $cst ) ;
  $cst = unformatvarname($cst) ;
  my ( $plineno, $package, $packagekey ) = $self->_getpackage( $comment,
       		 	   	       	   		       $filename,
							       $lineno ) ;

  if ( ( exists $self->{'CONTENT'}{'packages'}{$packagekey} ) &&
       ( exists $self->{'CONTENT'}{'packages'}{$packagekey}{'constants'}{$cstkey} ) ) {
    PhpDocGen::General::Error::warm( join( '',
					   "multi definition of the constant \$",
					   $cst,
					   " inside the package ",
					   $package,
					   ".\n" ),
				     $filename,
				     $lineno ) ;
  }

  # Package archiving
  if ( ( exists $self->{'CONTENT'}{'packages'}{$packagekey} ) &&
       ( exists $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} ) &&
       ( ! ( $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} eq $package ) ) ) {
    PhpDocGen::General::Error::warm( join( '',
					   "The package of the constant ",
					   $cst,
					   " have already a name: ",
					   $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} ),
				     $filename,
				     $plineno ) ;
  }

  my %me = ( 'name' => $cst,
	     'type' => ($type) ? $type : "mixed",
	     'location' => $self->_location( $filename, $lineno ),
	   ) ;

  $self->_commontags( \%me, $comment, $filename ) ;
  $self->_build_explanation( \%me,
			     $cstcomment,
			     $comment,
			     $filename ) ;

  # Update of the content
  %{$self->{'CONTENT'}{'packages'}{$packagekey}{'constants'}{$cstkey}} = %me ;
  $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} = $package ;

  return $me{'location'} ;
}

=pod

=item * parse_comment_function()

Tries to extract a global function definition
from the specified extracted comment.
Takes 3 args:

=over

=item * tag (string)

is the tag that is currently analyzed.

=item * comment (hash ref)

is the comment parts readed from the input stream.

=item * filename (string)

is the name of the file where the parts was found.

=back

=cut
sub parse_comment_function($$$) {
  my $self = shift ;
  my ( $tag, $comment, $filename ) = ( $_[0], $_[1], $_[2] || '' ) ;

  confess( 'invalid extracted function comment' )
    unless ( $comment && ishash($comment) ) ;

  my ( $lineno, $func, $funckey, $funccomment) = $self->_gettagname( '@function',
								     $tag,
								     $filename ) ;
  $funckey = formatfctkeyname( $func ) ;
  my ( $plineno, $package, $packagekey ) = $self->_getpackage( $comment,
							       $filename,
							       $lineno ) ;

  if ( exists $self->{'CONTENT'}{'packages'}{$packagekey}{'functions'}{$funckey} ) {
    PhpDocGen::General::Error::warm( join( '',
    			  	"multi definition of the function ",
				$func,
				"() in the package ",
				$package,
				"." ),
	  		  $filename,
			  $lineno ) ;
  }

  # Sets the package
  if ( ( exists $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} ) &&
       ( ! ( $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} eq $package ) ) ) {
    PhpDocGen::General::Error::warm( join( '',
					   "The package of the func ",
					   $func,
					   " have already a name: ",
					   $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} ),
				     $filename,
				     $plineno ) ;
  }

  # Sets the function
  my %me = ( 'name' => $func,
	     'location' => $self->_location( $filename, $lineno ),
	   ) ;

  $self->_params( \%me, $comment, $filename ) ;
  $self->_return( \%me, $comment, $filename ) ;
  $self->_uses( \%me, $comment, $filename ) ;
  $self->_commontags( \%me, $comment, $filename ) ;
  $self->_build_explanation( \%me,
			     $funccomment,
			     $comment,
			     $filename ) ;

  # Update of the content
  $self->{'CONTENT'}{'packages'}{$packagekey}{'functions'}{$funckey} = \%me ;
  $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} = $package ;

  return $me{'location'} ;
}

=pod

=item * parse_comment_class()

Tries to extract a class definition
from the specified extracted comment.
Takes 3 args:

=over

=item * tag (string)

is the tag that is currently analyzed.

=item * comment (hash ref)

is the comment parts readed from the input stream.

=item * filename (string)

is the name of the file where the parts was found.

=back

=cut
sub parse_comment_class($$$) {
  my $self = shift ;
  my ( $tag, $comment, $filename ) = ( $_[0], $_[1], $_[2] || '' ) ;

  my ( $lineno, $class, $classkey, $classcomment ) = $self->_gettagname( '@class',
       				       			                 $tag,
           				       			         $filename ) ;
  my ( $plineno, $package, $packagekey ) = $self->_getpackage( $comment, $filename, $lineno ) ;

  if ( exists $self->{'CONTENT'}{'classes'}{$classkey}{'this'} ) {
    PhpDocGen::General::Error::warm( "multi definition of the class $class.",
	  		  $filename,
			  $lineno ) ;
  }

  # Sets the package
  if ( ( exists $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} ) &&
       ( ! ( $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} eq $package ) ) ) {
    PhpDocGen::General::Error::warm( join( '',
    			  	"The package of the class ",
				$class,
				" has already a name: ",
				$self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} ),
			  $filename,
			  $plineno ) ;
  }

  # Sets the class
  my %me = ( 'name' => $class,
	     'location' => $self->_location( $filename, $lineno ),
     	     'package' => $packagekey,
	     'extends' => $self->_classextends( $comment, $filename ),
	   ) ;

  $self->_commontags( \%me, $comment, $filename ) ;
  $self->_build_explanation( \%me,
			     $classcomment,
			     $comment,
			     $filename ) ;

  # Update of the content
  $self->{'CONTENT'}{'classes'}{$classkey}{'this'} = \%me ;
  $self->{'CONTENT'}{'packages'}{$packagekey}{'this'}{'name'} = $package ;
  if ( ( ! $self->{'CONTENT'}{'packages'}{$packagekey}{'classes'} ) ||
       ( ! isarray( $self->{'CONTENT'}{'packages'}{$packagekey}{'classes'} ) ) ||
       ( isemptyarray( $self->{'CONTENT'}{'packages'}{$packagekey}{'classes'} ) ) ) {
    $self->{'CONTENT'}{'packages'}{$packagekey}{'classes'} = [] ;
  }
  push @{$self->{'CONTENT'}{'packages'}{$packagekey}{'classes'}}, $classkey ;

  return $me{'location'} ;
}

=pod

=item * parse_comment_attribute()

Tries to extract a class attribute definition
from the specified extracted comment.
Takes 3 args:

=over

=item * tag (string)

is the tag that is currently analyzed.

=item * comment (hash ref)

is the comment parts readed from the input stream.

=item * filename (string)

is the name of the file where the parts was found.

=back

=cut
sub parse_comment_attribute($$$) {
  my $self = shift ;
  my ( $tag, $comment, $filename ) = ( $_[0], $_[1], $_[2] || '' ) ;
  confess( 'invalid extracted attribute comment' )
    unless ( $comment && ishash($comment) ) ;
  my ( $lineno, $attrdesc ) = ( $self->__lineno( $tag ),
				$self->__nolineno( $tag ) ) ;
  my ($public,$protected,$private) = $self->has_tokens($attrdesc,'public','protected','private') ;
  my $type = $self->_type( 1+$public+$protected+$private, $attrdesc, $filename, $lineno ) ;
  my $attr = extract_param( 2+$public+$protected+$private, $attrdesc, 0 ) ;
  my $attrcomment = extract_param( 3+$public+$protected+$private, $attrdesc, 1 ) ;
  if ( ! $attr ) {
    PhpDocGen::General::Error::err( "a name was expected after \@attribute.\n",
	      		 $filename,
			 $lineno ) ;
  }
  my $attrkey = formatvarkeyname( $attr ) ;
  $attr = unformatvarname($attr) ;
							
  my ( $clineno, $class, $classkey ) ;
  if ( exists $comment->{'@class'} ) {
    ( $clineno, $class, $classkey ) = $self->_gettagname( '@class',
       		       		    			  $comment->{'@class'},
							  $filename ) ;
    # Be sure that the @class will not be used any more
    delete ( $comment->{'@class'} ) ;
  }
  else {
    PhpDocGen::General::Error::err( join( '',
    			       "tag \@class expected for the attribute '",
			       $attr,
			       "'." ),
	      		 $filename,
	      		 $lineno ) ;
  }

  if ( exists $self->{'CONTENT'}{'classes'}{$classkey}{'attributes'}{$attrkey} ) {
    PhpDocGen::General::Error::warm( join( '',
    			  	"multi definition of the attribute ",
				$class,
				"::",
				$attr,
				"." ),
	  		  $filename,
			  $lineno ) ;
  }
  # Management of the tag @modifiers
  if ( ( exists $comment->{'@modifiers'} ) ||
       ( exists $comment->{'@access'} ) ) {
    my $m_desc = $self->__nolineno( $comment->{'@modifiers'} ||
				    $comment->{'@access'} ) ;
    ($public,$protected,$private) = $self->has_tokens($m_desc,'public','protected','private') ;
  }
  $self->_change_access_modifiers( $comment, $public, $protected, $private ) ;

  # Sets the attribute
  my %me = ( 'name' => $attr,
     	     'type' => $type,
     	     'private' => ( $private > 0 ),
     	     'protected' => ( ( $private <= 0 ) && ( $protected > 0 ) ),
     	     'public' => ( ( $private <= 0 ) && ( $protected <= 0 ) ),
	     'location' => $self->_location( $filename, $lineno ),
	   ) ;

  $self->_commontags( \%me, $comment, $filename ) ;
  $self->_build_explanation( \%me,
			     $attrcomment,
			     $comment,
			     $filename ) ;

  # Update of the content
  $self->{'CONTENT'}{'classes'}{$classkey}{'attributes'}{$attrkey} = \%me ;

  return $me{'location'} ;
}

=pod

=item * parse_comment_method()

Tries to extract a class method definition
from the specified extracted comment.
Takes 3 args:

=over

=item * tag (string)

is the tag that is currently analyzed.

=item * comment (hash ref)

is the comment parts readed from the input stream.

=item * filename (string)

is the name of the file where the parts was found.

=back

=cut
sub parse_comment_method($$$) {
  my $self = shift ;
  my ( $tag, $comment, $filename ) = ( $_[0], $_[1], $_[2] || '' ) ;

  confess( 'invalid extracted method comment' )
    unless ( $comment && ishash($comment) ) ;

  my ( $lineno, $methdesc ) =
    ( $self->__lineno( $tag ),
      $self->__nolineno( $tag ) ) ;
  my ($static,$public,$protected,$private) = $self->has_tokens($methdesc,'static','public','protected','private') ;
  my $meth = extract_param( 1+$static+$public+$protected+$private, $methdesc, 0 ) ;
  if ( ! $meth ) {
    PhpDocGen::General::Error::err( "a name was expected after \@method.\n",
	      		 $filename,
			 $lineno ) ;
  }
  my $methkey = formatfctkeyname( $meth ) ;
  my $methcomment = extract_param( 2+$static+$public+$protected+$private, $methdesc, 1 ) ;
							
  my ( $clineno, $class, $classkey ) ;
  if ( exists $comment->{'@class'} ) {
    ( $clineno, $class, $classkey ) = $self->_gettagname( '@class',
							  $comment->{'@class'},
							  $filename ) ;
    # Be sure that the @class will not be used any more
    delete ( $comment->{'@class'} ) ;
  }
  else {
    PhpDocGen::General::Error::err( join( '',
    			       "tag \@class expected for the method ",
			       $meth,
			       "()." ),
	      		 $filename,
	      		 $lineno ) ;
  }

  if ( exists $self->{'CONTENT'}{'classes'}{$classkey}{'methods'}{$methkey} ) {
    PhpDocGen::General::Error::warm( join( '',
    			  	"multi definition of the method ",
				$class,
				"::",
				$meth,
				"()." ),
	  		  $filename,
			  $lineno ) ;
  }
  # Management of the tag @modifiers
  if ( ( exists $comment->{'@modifiers'} ) ||
       ( exists $comment->{'@access'} ) ) {
    my $m_desc = $self->__nolineno( $comment->{'@modifiers'} ||
				    $comment->{'@access'} ) ;
    ($static,$public,$protected,$private) = $self->has_tokens($m_desc,'static','public','protected','private') ;
  }
  $self->_change_type_modifiers( $comment, $static ) ;
  $self->_change_access_modifiers( $comment, $public, $protected, $private ) ;

  # Sets the method
  my %me = ( 'name' => $meth,
     	     'static' => ( $static > 0 ),
     	     'private' => ( $private > 0 ),
     	     'protected' => ( ( $private <= 0 ) && ( $protected > 0 ) ),
     	     'public' => ( ( $private <= 0 ) && ( $protected <= 0 ) ),
	     'location' => $self->_location( $filename, $lineno ),
	   ) ;

  $self->_params( \%me, $comment, $filename ) ;
  $self->_return( \%me, $comment, $filename ) ;
  $self->_uses( \%me, $comment, $filename ) ;
  $self->_commontags( \%me, $comment, $filename ) ;
  $self->_build_explanation( \%me,
			     $methcomment,
			     $comment,
			     $filename ) ;

  # Update of the content
  $self->{'CONTENT'}{'classes'}{$classkey}{'methods'}{$methkey} = \%me ;

  return $me{'location'} ;
}

=pod

=item * parse_comment_constructor()

Tries to extract a class constructor definition
from the specified extracted comment.
Takes 3 args:

=over

=item * tag (string)

is the tag that is currently analyzed.

=item * comment (hash ref)

is the comment parts readed from the input stream.

=item * filename (string)

is the name of the file where the parts was found.

=back

=cut
sub parse_comment_constructor($$$) {
  my $self = shift ;
  my ( $tag, $comment, $filename ) = ( $_[0], $_[1], $_[2] || '' ) ;

  confess( 'invalid extracted constructor comment' )
    unless ( $comment && ishash($comment) ) ;

  my ( $lineno, $class, $classkey, $conscomment ) = $self->_gettagname( '@constructor',
									$tag,
									$filename ) ;

  if ( exists $self->{'CONTENT'}{'classes'}{$classkey}{'constructor'} ) {
    PhpDocGen::General::Error::warm( "multi definition of the constructor $class().",
	  		  $filename, $lineno ) ;
  }

  # Sets the constructor
  my %me = ( 'name' => $class,
	     'location' => $self->_location( $filename, $lineno ),
	   ) ;

  $self->_params( \%me, $comment, $filename ) ;
  $self->_return( \%me, $comment, $filename, 'object' ) ;
  $self->_uses( \%me, $comment, $filename ) ;
  $self->_commontags( \%me, $comment, $filename ) ;
  $self->_build_explanation( \%me,
			     $conscomment,
			     $comment,
			     $filename ) ;

  # Update of the content
  $self->{'CONTENT'}{'classes'}{$classkey}{'constructor'} = \%me ;

  return $me{'location'} ;
}

=pod

=item * parse_comment_webmodule()

Tries to extract a web module
from the specified extracted comment.
Takes 3 args:

=over

=item * tag (string)

is the tag that is currently analyzed.

=item * comment (hash ref)

is the comment parts readed from the input stream.

=item * filename (string)

is the name of the file where the parts was found.

=back

=cut
sub parse_comment_webmodule($$$) {
  my $self = shift ;
  my ( $tag, $comment, $filename ) = ( $_[0], $_[1], $_[2] || '' ) ;

  confess( 'invalid extracted webmodule comment' )
    unless ( $comment && ishash($comment) ) ;

  my ( $lineno, $mod, undef, $modcomment ) = $self->_gettagname( '@webmodule',
					                         $tag,
					                         $filename ) ;
  my $url = $mod ;
  $url =~ s/^\/// ;
  my $modname = htmlfilename($mod) ;

  my @modpath = () ;
  if ( ! $modname ) {
    $modname = "/" ;
  }
  else {
    @modpath = htmlsplit( htmldirname( $mod ) ) ;
    if ( isemptyarray(\@modpath) ) {
      push( @modpath, "/" ) ;
    }
    elsif ( ! $modpath[0] ) {
      $modpath[0] = "/" ;
    }
  }
  push( @modpath, $modname ) ;

  # Sets the module
  my %me = ( 'name' => $mod,
	     'url' => $url,
	     'location' => $self->_location( $filename, $lineno ),
	   ) ;

  $self->_commontags( \%me, $comment, $filename ) ;
  $self->_build_explanation( \%me,
			     $modcomment,
			     $comment,
			     $filename ) ;

  # Update of the content
  if ( ! exists $self->{'CONTENT'}{'webmodules'} ) {
    %{$self->{'CONTENT'}{'webmodules'}} = () ;
  }
  my $currentmod = undef ;
  my $currentsubs = \%{$self->{'CONTENT'}{'webmodules'}} ;
  foreach my $cmod (@modpath) {
    if ( ! exists $currentsubs->{$cmod} ) {
      %{$currentsubs->{$cmod}} = () ;
    }
    $currentmod = \%{$currentsubs->{$cmod}} ;
    if ( ! exists $currentmod->{'submodules'} ) {
      %{$currentmod->{'submodules'}} = () ;
    }
    $currentsubs = \%{$currentmod->{'submodules'}} ;
  }

  if ( ! $currentmod ) {
    PhpDocGen::General::Error::err( "unable to find the root module for $mod.",
				    $filename,
				    $lineno ) ;
  }
  elsif ( exists $currentmod->{'this'} ) {
    PhpDocGen::General::Error::warm( "multi definition of the webmodule $mod.",
				     $filename,
				     $lineno ) ;
  }
  $currentmod->{'this'} = \%me ;

  return $me{'location'} ;
}

=pod

=item * parse_comment_webpage()

Tries to extract a web page
from the specified extracted comment.
Takes 3 args:

=over

=item * tag (string)

is the tag that is currently analyzed.

=item * comment (hash ref)

is the comment parts readed from the input stream.

=item * filename (string)

is the name of the file where the parts was found.

=back

=cut
sub parse_comment_webpage($$$) {
  my $self = shift ;
  my ( $tag, $comment, $filename ) = ( $_[0], $_[1], $_[2] || '' ) ;

  confess( 'invalid extracted webpage comment' )
    unless ( $comment && ishash($comment) ) ;

  my ( $lineno, $page, undef, $pagecomment ) = $self->_gettagname( '@webpage',
					                           $tag,
					                           $filename ) ;
  my $url = $page ;
  $url =~ s/^\/// ;
  my $pagename = htmlfilename($page) ;
  if ( ! $pagename ) {
    PhpDocGen::General::Error::err( "you must specify a valid webpage name instead of '$page'.",
				    $filename,
				    $lineno ) ;
  }

  my @modpath = () ;
  my $path = htmldirname($page);
  if ( ! $path ) {
    push(@modpath,"/");
  }
  else {
    @modpath = htmlsplit($path) ;
    if ( isemptyarray(\@modpath) ) {
      push( @modpath, "/" ) ;
    }
    elsif ( ! $modpath[0] ) {
      $modpath[0] = "/" ;
    }
  }

  # Sets the page
  my %me = ( 'name' => $page,
	     'url' => $url,
	     'location' => $self->_location( $filename, $lineno ),
	   ) ;

  $self->_commontags( \%me, $comment, $filename ) ;
  $self->_build_explanation( \%me,
			     $pagecomment,
			     $comment,
			     $filename ) ;

  # Update of the content
  if ( ! exists $self->{'CONTENT'}{'webmodules'} ) {
    %{$self->{'CONTENT'}{'webmodules'}} = () ;
  }
  my $currentmod = undef ;
  my $currentsubs = \%{$self->{'CONTENT'}{'webmodules'}} ;
  foreach my $cmod (@modpath) {
    if ( ! exists $currentsubs->{$cmod} ) {
      %{$currentsubs->{$cmod}} = () ;
    }
    $currentmod = \%{$currentsubs->{$cmod}} ;
    if ( ! exists $currentmod->{'submodules'} ) {
      %{$currentmod->{'submodules'}} = () ;
    }
    $currentsubs = \%{$currentmod->{'submodules'}} ;
  }

  if ( ! $currentmod ) {
    PhpDocGen::General::Error::err( "unable to find the root module for $page.",
				    $filename,
				    $lineno ) ;
  }
  elsif ( exists $currentmod->{'pages'}{$pagename} ) {
    PhpDocGen::General::Error::warm( "multi definition of the webpage $page.",
				     $filename,
				     $lineno ) ;
  }
  $currentmod->{'pages'}{$pagename} = \%me ;

  return $me{'location'} ;
}

=pod

=item * parse_common_tag_verbatim()

Parses the tag @verbatim.
Takes 3 args:

=over

=item * result (hash ref)

is the variable in which the results 
must be put.

=item * tag (string)

is the value of the tag.

=item * filename (string)

is the name of the file where the tag was found.

=back

=cut
sub parse_common_tag_verbatim($$$) {
  my $self = shift ;

  confess( 'invalid extracted verbatim tag' )
    unless ( $_[0] && ishash($_[0]) ) ;

  $_[0]->{'explanation'}{'text'} = "<!-- VERBATIM -->".
  				   $_[0]->{'explanation'}{'text'} ;
}

=pod

=item * parse_common_tag_bug()

Parses the tag @bug.
Takes 3 args:

=over

=item * result (hash ref)

is the variable in which the results 
must be put.

=item * tag (string)

is the value of the tag.

=item * filename (string)

is the name of the file where the tag was found.

=back

=cut
sub parse_common_tag_bug($$$) {
  my $self = shift ;

  confess( 'invalid extracted bug tag' )
    unless ( $_[0] && ishash($_[0]) &&
	     $_[1] && isarray($_[1]) ) ;

  @{$_[0]{'bugs'}} = () ;
  foreach my $bug (@{$_[1]}) {
    my $lineno = $self->__lineno( $bug ) ;
    my $desc = $self->__nolineno( $bug ) ;
    my $fixed = $self->has_token( 'fixed', $desc ) ;
    my $comment = extract_param( $fixed + 1, $desc, 1 ) ;
    my %thebug = ( 'location' => $self->_location( $_[2] || '',
       	       	   	      	 		   $lineno ),
		   'text' => $comment,
		   'fixed' => ( $fixed > 0 ),
                 ) ;
    push( @{$_[0]->{'bugs'}}, \%thebug ) ;
  }
}

=pod

=item * parse_common_tag_log()

Parses the tag @log.
Takes 3 args:

=over

=item * result (hash ref)

is the variable in which the results 
must be put.

=item * tag (string)

is the value of the tag.

=item * filename (string)

is the name of the file where the tag was found.

=back

=cut
sub parse_common_tag_log($$$) {
  my $self = shift ;
  my $filename = $_[2] || '' ;

  confess( 'invalid extracted bug tag' )
    unless ( $_[0] && ishash($_[0]) &&
	     $_[1] ) ;
  if ( ! isarray( $_[1] ) ) {
    $_[1] = [ $_[1] ] ;
  }

  @{$_[0]->{'logs'}} = () ;
  foreach my $log (@{$_[1]}) {
    my $lineno = $self->__lineno( $log ) ;
    my $desc = $self->__nolineno( $log ) ;
    my $date = extract_param( 1, $desc, 0 ) ;
    my $comment = extract_param( 2, $desc, 1 ) ;
    if ( ! $date ) {
      PhpDocGen::General::Error::err( "a date was expected for a log.",
			   $filename,
			   $lineno ) ;
    }
    if ( ! $comment ) {
      PhpDocGen::General::Error::err( "a comment was expected for a log.",
			   $filename,
			   $lineno ) ;
    }
    my %thelog = ( 'location' => $self->_location( $filename,
       	       	   	      	 		   $lineno ),
		   'text' => $comment,
		   'date' => $date,
                 ) ;
    push( @{$_[0]->{'logs'}}, \%thelog ) ;
  }
}

#------------------------------------------------------
#
# Private API
#
#------------------------------------------------------

=pod

=item * has_token()

Replies the integer 1 if the specified
token is the first word of the specified
string. Otherwise, replies the integer 0.
Takes 2 args:

=over

=item * token (string)

is the token to seach inside the second parameter.

=item * string (string)

is the string to search inside.

=back

=cut
sub has_token($$) {
  my $self = shift ;
  return $self->has_token_at( $_[0], 1, $_[1] ) ;
}

=pod

=item * has_token_at()

Replies the integer 1 if the specified
token is the first word of the specified
string. Otherwise, replies the integer 0.
Takes 3 args:

=over

=item * token (string)

is the token to seach inside the second parameter.

=item * pos (integer)

is the requested position of the token.

=item * string (string)

is the string to search inside.

=back

=cut
sub has_token_at($$$) {
  my $self = shift ;
  my ( $token, $pos, $string ) = ( $_[0] || confess( 'invalid token' ),
				   $_[1] || 1,
				   $_[2] || '' ) ;
  my $opt = extract_param( $pos, $string, 0 ) ;
  return ( ( lc( $opt ) eq lc( $token ) ) ? 1 : 0 ) ;
}

=pod

=item * has_tokens()

Replies a list of integers which specify if the specified
tokens was found in the specified string
Takes at least 2 args:

=over

=item * text (string)

is the string to parse

=item * tokens (strings)

are the tokens to find.

=back

=cut
sub has_tokens {
  my $self = shift ;
  my $string = shift ;
  my @values = () ;
  my $index = 0 ;
  my %indexes = () ;
  # Scan the parameters to extract the
  # aliases
  # %indexes contains the indexes inside the
  # resulting array for each parameter
  foreach my $token (@_) {
    my $tok = $token ;
    if ( $token =~ /^-/ ) {
      $tok = substr($token,1) ;
    }
    else {
      $index++ ;
    }
    $indexes{$tok} = ($index-1) ;
    $values[$indexes{$tok}] = 0 ;
  }
  # Scan the given string to detect the tokens
  my $count = ($#values + 1) ;
  my $wordindex = 1 ;
  my $found ;
  do {
    $found = 0 ;
    my @keys = keys %indexes ;
    my $i = 0 ;
    while ( ( ! $found ) && ( $i <= $#keys ) ) {
      my $f = $self->has_token_at( $keys[$i], $wordindex, $string ) ;
      if ( $f > 0 ) {
	$values[$indexes{$keys[$i]}] = 1 ;
	undef $indexes{$keys[$i]} ;
	$found = 1 ;
      }
      $i++ ;
    }
    $wordindex ++ ;
  } while ( ( $found ) && ( $wordindex <= $count ) ) ;
  return @values ;
}

=pod

=item * _change_access_modifiers()

Changes the access modifier flags.
Takes at least 4 args:

=over

=item * comment (hash)

is the asscoiative array that contains the comment.

=item * public (boolean ref)

is the flag that indicates if the public flag was present

=item * protected (boolean ref)

is the flag that indicates if the protected flag was present

=item * private (boolean ref)

is the flag that indicates if the private flag was present

=back

=cut
sub _change_access_modifiers($$$$) {
  my $self = shift ;
  if ( ishash($_[0]) ) {
    if ( exists $_[0]->{'@public'} ) {
      $_[1] = 1 ;
      $_[2] = $_[3] = 0 ;
    }
    elsif ( exists $_[0]->{'@protected'} ) {
      $_[2] = 1 ;
      $_[1] = $_[3] = 0 ;
    }
    if ( exists $_[0]->{'@private'} ) {
      $_[3] = 1 ;
      $_[1] = $_[2] = 0 ;
    }
  }
}

=pod

=item * _change_type_modifiers()

Changes the type modifier flags.
Takes at least 4 args:

=over

=item * comment (hash)

is the asscoiative array that contains the comment.

=item * static (boolean ref)

is the flag that indicates if the static flag was present

=back

=cut
sub _change_type_modifiers($$) {
  my $self = shift ;
  if ( ( ishash($_[0]) ) && 
       ( exists $_[0]->{'@static'} ) ) {
    $_[1] = 1 ;
  }
}

=pod

=item * _type()

Replies the data type.
Takes 4 args:

=over

=item * index (integer)

is the location of the word to extract.

=item * string (string)

is the string from which the type must be extracted.

=item * filename (string)

is the name of the name from which the string was extracted.

=item * lineno (integer)

is the location inside the file.

=back

=cut
sub _type($$$$) {
  my $self = shift ;
  my ( $index, $string ) = ( $_[0],
			     $_[1] || '' ) ;
  my ( $filename, $lineno ) = ( $_[2] || '',
				$_[3] || 0 ) ;
  my $type = extract_param( $index, $string, 0 ) ;
  my $t = is_valid_type( $type ) ;
  if ( $t ) {
    return $t ;
  }
  PhpDocGen::General::Error::err( "unsupported type '$type'\n",
				  $filename, $lineno ) ;
}

=pod

=item * _optional_type()

Replies the data type if it exists, or undef.
Takes 2 args:

=over

=item * index (integer)

is the location of the word to extract.

=item * string (string)

is the string from which the type must be extracted.

=back

=cut
sub _optional_type($$) {
  my $self = shift ;
  my ( $index, $string ) = ( $_[0],
			     $_[1] || '' ) ;
  my $type = extract_param( $index, $string, 0 ) ;
  my $t = is_valid_type( $type ) ;
  if ( $t ) {
    return $t ;
  }
  else {
    return undef ;
  }
}

=pod

=item * _return()

Replies the tag @return.
Takes 3 args:

=over

=item * result (hash ref)

is the variable in which the results 
must be put.

=item * comment (hash rec)

is the comment.

=item * filename (string)

is the name of the file.

=item * defaulttype (optional string)

is the default type of the returned value

=back

=cut
sub _return($$$) {
  my $self = shift ;
  if ( ( ishash($_[1]) ) &&
       ( exists $_[1]->{'@return'} ) ) {

    confess( 'invalid target structure' ) unless ( ishash($_[0]) ) ;

    my $lineno = $self->__lineno( $_[1]->{'@return'} ) ;
    my $comment = $self->__nolineno( $_[1]->{'@return'} ) ;
    if ( $comment ) {
      my ($byref) = $self->has_tokens($comment,'reference','-ref') ;
      my $type = $self->_optional_type( 1+$byref, $comment ) ;
      if ( $type ) {
        $comment = extract_param( 2, $comment, 1 ) ;
      }
      else {
        $type = $_[3] || "mixed" ;
      }
      %{$_[0]->{'return'}} = ( 'comment' => $comment,
			       'type' => $type,
			       'byref' => ($byref > 0),
			       'location' => $self->_location( $_[2] || '',
			     		   		       $lineno ),
			     ) ;
    }
    else {
      delete $_[0]->{'return'} ;
    }
  }
}

=pod

=item * _params()

Replies the tags @param.
Takes 3 args:

=over

=item * result (hash ref)

is the variable in which the results 
must be put.

=item * comment (hash rec)

is the comment.

=item * filename (string)

is the name of the file.

=back

=cut
sub _params($$$) {
  my $self = shift ;
  if ( ( ishash($_[1]) ) &&
       ( exists $_[1]->{'@param'} ) ) {

    confess( 'invalid target structure' ) unless ( ishash($_[0]) ) ;

    my @params = () ;
    if ( ( isarray( $_[1]->{'@param'} ) ) &&
         ( ! isemptyarray( $_[1]->{'@param'} ) ) ) {
      foreach my $p (@{$_[1]->{'@param'}}) {
	my %param = ( 'text' => $self->__nolineno( $p ),
	   	      'line' => $self->__lineno( $p ),
		    ) ;
	push( @params, \%param ) ;
      }
    }
    else {
      my %param = ( 'text' => $self->__nolineno( $_[1]->{'@param'} ),
      	 	    'line' => $self->__lineno( $_[1]->{'@param'} )
		  ) ;
      push( @params, \%param ) ;
    }

    @{$_[0]->{'parameters'}} = () ;
    for(my $i=0; $i<=$#params; $i++) {
      my ($optional, $byref, $name, $type, $explanation) = (0,0,"",'mixed',"") ;
      my $multiparams = $self->has_token( '...', $params[$i]{'text'} ) ;
      if ( ! $multiparams ) {
	($optional,$byref) = $self->has_tokens( $params[$i]{'text'}, 'optional', 'reference', '-ref' ) ;
	$name = extract_param( 2 + $optional + $byref, $params[$i]{'text'}, 0 ) ;
	$name = unformatvarname($name);	
	if ( ! $name ) {
	  PhpDocGen::General::Error::err( "a name was expected for a parameter",
					  $_[2] || '',
					  $params[$i]{'line'} ) ;
	}
	$type = $self->_type( 1 + $optional + $byref,
			      $params[$i]{'text'},
			      $_[2] || '',
			      $params[$i]{'line'} ) ;
	$explanation = extract_param( 3 + $optional + $byref,
				      $params[$i]{'text'},
				      1 ) ;
      }
      else {
	$name = "..." ;
	$explanation = extract_param( 2,
				      $params[$i]{'text'},
				      1 ) ;
      }

      my $found = 0 ;
      foreach my $exparam (@{$_[0]->{'parameters'}}) {
	if ( ( $exparam->{'name'} ) && 
	     ( lc( $exparam->{'name'} ) eq lc( $name ) ) ) {
	  $found = 1 ;
	}
      }
      if ( ! $found ) {
	my %param = ( 'location' => $self->_location( $_[2] || '',
                                                      $params[$i]{'line'} ),
		      'name' => $name,
		      'optional' => ($optional>0),
		      'type' => ($type),
		      'varparam' => ($multiparams>0),
		      'byref' => ($byref>0),
		      'explanation' => $explanation,
		    ) ;
	push( @{$_[0]->{'parameters'}}, \%param ) ;
      }
      else {
	PhpDocGen::General::Error::warm( join( '',
					       "multi definition of the ",
					       "parameter \$",
					       $name,
					       ".\n" ),
					 $_[2] || '',
					 $params[$i]{'line'} ) ;
      }
    }
  }
}

=pod

=item * _uses()

Replies the tags @use.
Takes 3 args:

=over

=item * result (hash ref)

is the variable in which the results 
must be put.

=item * comment (hash rec)

is the comment.

=item * filename (string)

is the name of the file.

=back

=cut
sub _uses($$$) {
  my $self = shift ;
  $self->_uses_from_tag( $_[0], $_[1], $_[2], '@use' ) ;
  $self->_uses_from_tag( $_[0], $_[1], $_[2], '@global' ) ;
}

=pod

=item * _uses_from_tag()

Replies the specified tag.
Takes 4 args:

=over

=item * result (hash ref)

is the variable in which the results 
must be put.

=item * comment (hash rec)

is the comment.

=item * filename (string)

is the name of the file.

=item * tagname (string)

is the name of the tag to check.

=back

=cut
sub _uses_from_tag($$$$) {
  my $self = shift ;
  my $filename = $_[2] || '' ;
  if ( ( ishash($_[1]) ) &&
       ( exists $_[1]->{$_[3]} ) ) {

    confess( 'invalid target structure' ) unless ( ishash($_[0]) ) ;

    @{$_[0]->{'uses'}} = () ;
    if ( ( isarray( $_[1]->{$_[3]} ) ) &&
       	 ( ! isemptyarray( $_[1]->{$_[3]} ) ) ) {
      foreach my $var (@{$_[1]->{$_[3]}}) {
	my %use = ( 'name' => $self->__nolineno( $var ),
	   	    'location' => $self->_location( $filename,
		    	       	  		    $self->__lineno( $var ) ),
		  ) ;
	push( @{$_[0]->{'uses'}}, \%use ) ;
      }
    }
    else {
      my $var = $_[1]->{$_[3]} ;
      my %use = ( 'name' => $self->__nolineno( $var ),
      	      	  'location' => $self->_location( $filename,
		  	     			  $self->__lineno( $_[1]->{$_[3]} ) ),
		) ;
      push( @{$_[0]->{'uses'}}, \%use ) ;
    }
  }
}

=pod

=item * _commontags()

Replies the common tags.
Takes 3 args:

=over

=item * result (hash ref)

is the variable in which the results 
must be put.

=item * comment (hash rec)

is the comment.

=item * filename (string)

is the name of the file.

=back

=cut
sub _commontags($$$) {
  my $self = shift ;
  my $filename = $_[2] || '' ;

  confess( 'invalid target structure' ) unless ( ishash($_[0]) ) ;

  foreach my $tag (keys(%COMMON_SECTIONED_TAGS),@COMMON_TAGS) {
    if ( ( ishash($_[1]) ) &&
	 ( $_[1]->{"\@$tag"} ) ) {
      my $funcref = $self->can( 'parse_common_tag_'.$tag ) ;
      if ( $funcref ) {
	$self->$funcref( $_[0], $_[1]->{"\@$tag"}, $filename ) ;
      }
      else {
	@{$_[0]->{"$tag"}} = () ;
	if ( ( isarray( $_[1]->{"\@$tag"} ) ) &&
	     ( ! isemptyarray( $_[1]->{"\@$tag"} ) ) ) {
	  foreach my $name (@{$_[1]->{"\@$tag"}}) {
	    my %auth = ( 'text' => $self->__nolineno( $name ),
	       	       	 'location' => $self->_location( $filename,
			 	       			 $self->__lineno( $name ) ),
		       ) ;
	   push( @{$_[0]->{"$tag"}}, \%auth ) ;
	  }
	}
	else {
	  my %auth = ( 'text' => $self->__nolineno( $_[1]->{"\@$tag"} ),
	       	       'location' => $self->_location( $filename,
          	       		     		       $self->__lineno( $_[1]->{"\@$tag"} ) ),
		     ) ;
	  push( @{$_[0]->{"$tag"}}, \%auth ) ;
	}
      }
    }
  }
}

=pod

=item * _classextends()

Replies a class extend build from the
parameters.
Takes 2 args:

=over

=item * comment (hash rec)

is the comment.

=item * filename (string)

is the name of the file.

=back

=cut
sub _classextends($$) {
  my $self = shift ;
  my $filename = $_[1] || '' ;

  confess( 'invalid extracted comment structure' ) unless ( ishash($_[0]) ) ;

  my $extends = $_[0]->{'@extends'} || $_[0]->{'@inherited'} ;

  if ( $extends ) {
    my $lineno = $self->__lineno( $extends ) ;
    my $class = $self->__nolineno( $extends ) ;
    if ( ! $class ) {
      PhpDocGen::General::Error::err( join( '',
					    "a name was expected after",
					    "\@extend or \@inherited." ),
				      $filename,
				      $lineno ) ;
    }
    else {
      return { 'class' => formathashkeyname( $class ),
               'location' => $self->_location( $filename,
	       		     		       $lineno ),
	     } ;
    }
  }
  return undef ;
}

=pod

=item * _explanation()

Replies an explanation build from the
parameters.
Takes 2 args:

=over

=item * comment (hash rec)

is the comment.

=item * filename (string)

is the name of the file.

=back

=cut
sub _explanation($$) {
  my $self = shift ;

  confess( 'invalid extracted comment structure' ) unless ( ishash($_[0]) ) ;

  return { 'text' => $self->__nolineno( $_[0]->{'@explanation'} ),
  	   'location' => $self->_location( $_[1] || '',
	   	      	 		   $self->__lineno( $_[0]->{'@explanation'} ) ),
	 } ;
}

=pod

=item * _explanation()

Replies an explanation build from the
parameters.
Takes 2 args:

=over

=item * comment (hash rec)

is the comment.

=item * shortcomment (string)

=item * data (hash)

=item * filename (string)

is the name of the file.

=back

=cut
sub _build_explanation($$$$) {
  my $self = shift ;
  my $shortcomment = $_[1] || '' ;
  my $data = $_[2] || confess( 'you must supply data' ) ;
  my $filename = $_[3] || confess( 'you must supply a filename' ) ;
  my $explanation = $self->_explanation( $data, $filename ) ;
  # Sets the brief comment
  if ( ( ! $_[0]->{'brief'} ) && ( $shortcomment ) ) {
    $_[0]->{'brief'} = [ { 'location' => $_[0]->{'location'},
			   'text' => $shortcomment,
			 },
		       ] ;
  }
  if ( $explanation ) {
    $_[0]->{'explanation'} = $explanation ;
  }
}

=pod

=item * _location()

Replies a location build from the
parameters.
Takes 2 args:

=over

=item * filename (string)

is the name of the file.

=item * lineno (integer)

is the location inside the file.

=back

=cut
sub _location($$) {
  my $self = shift ;
  return( join( '',
  	  	$_[0] || '',
		":",
		( $_[1] || 0 ) ) ) ;		
}

=pod

=item * _gettagname()

Replies the name, the
corresponding associative array key,
 the line number and the inlined comment
from the specified readed comment.
Takes 3 args:

=over

=item * tag (string)

is the name of the tag to extract.

=item * comment (hash ref)

is the comment.

=item * filename (string)

is the name of the file in which is the comment.

=back

=cut
sub _gettagname($$$) {
  my $self = shift ;

  confess( 'invalid tag name' ) unless ( $_[0] ) ;
  confess( 'invalid tag value' ) unless ( $_[1] ) ;

  my $lineno = $self->__lineno( $_[1] ) ;
  my $def = $self->__nolineno( $_[1] ) ;
  my $name = extract_param( 1, $def, 0 ) ;
  my $inlinecomment = extract_param( 2, $def, 1 ) ;

  if ( ! $name ) {
    PhpDocGen::General::Error::err( "a name was expected after $_[0].\n",
				    $_[2] || '',
				    $lineno ) ;
  }
  return ( $lineno,
  	   $name,
	   formathashkeyname( $name ),
	   $inlinecomment ) ;
}

=pod

=item * _getpackage()

Replies the package name and the
corresponding associative array key
from the specified readed comment.
Takes 2 args:

=over

=item * comment (hash ref)

is the comment.

=item * filename (string)

is the name of the file in which is the comment.

=item * lineno (integer)

is a line number used to display an error message when the lineno
of the tag @package was not found

=back

=cut
sub _getpackage($$$) {
  my $self = shift ;

  confess( 'invalid extracted comment structure' ) unless ( ishash($_[0]) ) ;

  my $packagedef = $self->__nolineno( $_[0]->{'@package'} ) ;
  my $lineno = $self->__lineno( $_[0]->{'@package'} ) ;
  my $filename = $_[1] || '' ;
  if ( ! $lineno ) {
    $lineno = $_[2] || 0 ;
  }
  if ( ! $packagedef ) {
    PhpDocGen::General::Error::warm( join( '',
					   "the tag \@package was not ",
					   "found. Use default: ",
					   $self->{'DEFAULT_PACKAGE'} ),
				     $filename,
				     $lineno ) ;
    $packagedef = $self->{'DEFAULT_PACKAGE'} ;
  }
  if ( ! $packagedef ) {
    PhpDocGen::General::Error::err( "a name was expected after \@package.\n",
				    $filename,
				    $lineno ) ;
  }
  return ( $lineno, $packagedef, formathashkeyname( $packagedef ) ) ;
}

=pod

=item * __nolineno()

Replies the specified string without the line number.
Takes 1 arg:

=over

=item * str (string)

is the string to parse.

=back

=cut
sub __nolineno($) {
  my $self = shift ;
  if ( ( $_[0] ) && ( $_[0] =~ /^\([0-9]+\)(.*)$/s ) ) {
    return $1 ;
  }
  elsif ( $_[0] ) {
    return $_[0] ;
  }
  else {
    return "" ;
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
sub __lineno($) {
  my $self = shift ;
  if ( ( $_[0] ) && ( $_[0] =~ /^\(([0-9]+)\).*$/s ) ) {
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

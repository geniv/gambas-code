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

PhpDocGen::Parser::BlockScanner - A scanner for extracted source blocks

=head1 SYNOPSYS

use PhpDocGen::Parser::BlockScanner ;

my $scan = PhpDocGen::Parser::BlockScanner->new() ;

=head1 DESCRIPTION

PhpDocGen::Parser::BlockScanner is a Perl module, which scannes
a source file to recognize the PHP source blocks. This scanner
support only the PHP comments which are enclosed by /** and */
or starting with //*

=head1 GETTING STARTED

=head2 Initialization

To start a scanner, say something like this:

    use PhpDocGen::Parser::BlockScanner;

    my $scan = PhpDocGen::Parser::BlockScanner->new() ;

...or something similar.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in BlockScanner.pm itself.

=over

=cut

package PhpDocGen::Parser::BlockScanner;

@ISA = ('PhpDocGen::Parser::Scanner');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;
use File::Basename ;

use PhpDocGen::Parser::Scanner ;
use PhpDocGen::General::Misc ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the scanner
my $VERSION = "0.7" ;

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
    if ( $_[0] ) {
      if ( ! $_[1] ) {
	PhpDocGen::General::Error::syserr( "You must supply the initial state to the ".
					   "BlockScanner constructor" ) ;
      }
      if ( ! $_[2] ) {
	PhpDocGen::General::Error::syserr( "You must supply the final states to the ".
					   "BlockScanner constructor" ) ;
      }
      $self = $class->SUPER::new( $_[0], $_[1], $_[2] ) ;
    }
    else {
      $self = $class->SUPER::new(
              { 'htmlcode' => [ { state => 'code',
				  pattern => '<\\?(?:php)?',
				},
				{ state => 'htmlcode',
				  pattern => '<',
				  merge => 1,
				},
				{ state => 'htmlcode',
				  pattern => '[^<]+',
				  merge => 1,
				},
			      ],
		'code' => [ # end of PHP code
			   { state => 'htmlcode',
			     pattern => '\\?>',
			     merge => 1,
			     splitmerging => 1,
			   },
			   # comment support
			   { state => 'long_doc_comment',
			     pattern => '\/\*\*',
			     merge => 1,
			     splitmerging => 1,
			   },
			   { state => 'long_comment',
			     pattern => '\/\*',
			     merge => 1,
			     splitmerging => 1,
			   },
			   { state => 'short_doc_comment',
			     pattern => '\/\/\*',
			     merge => 1,
			     splitmerging => 1,
			   },
			   { state => 'short_doc_comment',
			     pattern => '\#\*',
			     merge => 1,
			     splitmerging => 1,
			   },
			   { state => 'short_comment',
			     pattern => '\/\/',
			     merge => 1,
			     splitmerging => 1,
			   },
			   { state => 'short_comment',
			     pattern => '\#',
			     merge => 1,
			     splitmerging => 1,
			   },
			   # inline string
			   { state => 'inline_string',
			     pattern => "\\<\\<+\\s*[a-zA-Z0-9_]+",
			   },
			   # string support
			   { state => 'qqstring',
			     pattern => '"',
			     merge => 1,
			   },
			   { state => 'qstring',
			     pattern => '\'',
			     merge => 1,
			   },
			   # other code elements
			   { state => 'code',
			     pattern => '\\/',
			     merge => 1,
			   },
			   { state => 'code',
			     pattern => '\\?',
			     merge => 1,
			   },
			   { state => 'code',
			     pattern => '\\<',
			     merge => 1,
			   },
			   { state => 'code',
			     pattern => '[^?/\'"<#]+',
			     merge => 1,
			   },
			  ],
		'inline_string' => [ { state => 'inline_string_shadow',
				       pattern => "^([a-zA-Z0-9_]+)(.*)\$",
				     },
				     { state => 'inline_string',
				       pattern => '.',
				       merge => 1,
				     },
				   ],
		'inline_string_shadow' => [], #only for callback
	        'long_doc_comment' => [ { state => 'code',
		                          pattern => '\*\/',
					},
					{ state => 'long_doc_comment',
					  pattern => '[^\*]+',
					  merge => 1,
					},
					{ state => 'long_doc_comment',
					  pattern => '\*',
					  merge => 1,
					},
				      ],
	        'short_doc_comment' => [ { state => 'code',
		                           pattern => "\n",
					 },
					 { state => 'short_doc_comment',
					   pattern => "[^\n]+",
					   merge => 1,
					 },
				       ],
	        'qstring' => [ { state => 'qstring',
		                 pattern => '\\\\.',
				 merge => 1,
			       },
	      		       { state => 'code',
		                 pattern => '\'',
				 merge => 1,
			       },
			       { state => 'qstring',
			         pattern => '[^\'\\\\]+',
				 merge => 1,
			       },
			     ],
	        'qqstring' => [ { state => 'qqstring',
		                  pattern => '\\\\.',
				  merge => 1,
			        },
			        { state => 'code',
		                  pattern => '"',
				  merge => 1,
				},
				{ state => 'qqstring',
			          pattern => '[^"\\\\]+',
				  merge => 1,
			        },
			     ],
	        'long_comment' => [ { state => 'code',
		                      pattern => '\*\/',
				    },
				    { state => 'long_comment',
				      pattern => '[^\*]+',
				      merge => 1,
				    },
				    { state => 'long_comment',
				      pattern => '\*',
				      merge => 1,
				    },
				  ],
	        'short_comment' => [ { state => 'code',
		                       pattern => "\n",
				     },
				     { state => 'short_comment',
				       pattern => "[^\n]+",
				       merge => 1,
				     },
				   ],
	      },
	      'htmlcode',
	      [ 'htmlcode', 'code', 'short_comment', 'short_doc_comment' ]
              ) ;
    }
    # Initializes the class attributes
    $self->clearblocks() ;
  }
  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Scanning API
#
#------------------------------------------------------

=pod

=item * scanblocks()

Replies an array that contains the source
parts readed from the source file.
A source part is a comment or a block of code.
Takes 1 arg:

=over

=item * filename (string)

is the name of the file from which the source parts must
be extracted.

=back

=cut
sub scanblocks($)  {
  my $self = shift ;

  $self->clearblocks() ;
  $self->{'BLOCKSCANNER_COMMENTLINENO'} = 0 ;

  if ( $_[0] ) {

    if ( ! $self->scan( $_[0] ) ) {
      PhpDocGen::General::Error::err( "Unexpected end of file (state: ".$self->{'SM_CURRENT_STATE'}.")",
				      $_[0],
				      $self->{'LINENO'} ) ;
    }

    PhpDocGen::General::Verbose::three( join( '',
					      "\t",
					      int(@{$self->{'BLOCKSCANNER_BLOCKS'}}),
					      " block",
					      (int(@{$self->{'BLOCKSCANNER_BLOCKS'}})>1)?
					      "s":"" ) ) ;
  }

  return $self->getblocks() ;
}

#------------------------------------------------------
#
# Callback functions
#
#------------------------------------------------------

=pod

=item * transition_callback_inline_string_inline_string_shadow()

This method is called each time a transition
from the state 'inline_string' to the state
'inline_string_shadow' was encountered.
Takes 1 arg:

=over

=item * str (string)

is the recognized string.

=back

=cut
sub transition_callback_inline_string_inline_string_shadow($) {
  my $self = shift ;
  my $str = $_[0] || '' ;
  if ( $str =~ /^\Q$self->{'BLOCKSCANNER_INLINE_STRING_KEY'}\E/ms ) {
    $self->{'SM_CURRENT_STATE'} = 'code' ;
    $self->{'BLOCKSCANNER_INLINE_STRING_KEY'} = '' ;
  }
  else {
    $self->{'SM_CURRENT_STATE'} = 'inline_string' ;
  }
  $self->addblock( 'CODE', $str, 0 ) ;
}

=pod

=item * transition_callback_code_inline_string()

This method is called each time a transition
from the state 'code' to the state
'inline_string' was encountered.
Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub transition_callback_code_inline_string($) {
  my $self = shift ;
  my $code = $_[0] || ''  ;
  $code =~ /\<\<+\s*([^\s]+)$/ ;
  $self->{'BLOCKSCANNER_INLINE_STRING_KEY'} = $1 ;
  $self->addblock( 'CODE', $code, 0 ) ;
}

=pod

=item * transition_callback_long_doc_comment_code()

This method is called each time a transition
from the state 'long_doc_comment' to the state
'code' was encountered.
Takes 1 arg:

=over

=item * comment (string)

is the recognized comment.

=back

=cut
sub transition_callback_long_doc_comment_code($) {
  my $self = shift ;
  my $comment = $_[0] || ''  ;
  $self->addblock( 'LONG_COMMENT',
  		   $comment,
		   $self->{'BLOCKSCANNER_COMMENTLINENO'} ) ;
  $self->{'BLOCKSCANNER_COMMENTLINENO'} = 0 ;
}

=pod

=item * transition_callback_short_doc_comment_code()

This method is called each time a transition
from the state 'short_doc_comment' to the state
'code' was encountered.
Takes 1 arg:

=over

=item * comment (string)

is the recognized comment.

=back

=cut
sub transition_callback_short_doc_comment_code($) {
  my $self = shift ;
  my $comment = $_[0] || ''  ;
  $self->addblock( 'SHORT_COMMENT',
  		   $comment,
		   $self->{'BLOCKSCANNER_COMMENTLINENO'} ) ;
  $self->{'BLOCKSCANNER_COMMENTLINENO'} = 0 ;
}

=pod

=item * transition_callback_code_long_doc_comment()

This method is called each time a transition
from the state 'code' to the state
'long_doc_comment' was encountered.
Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub transition_callback_code_long_doc_comment($) {
  my $self = shift ;
  my $code = $_[0] || '' ;
  $self->addblock( 'CODE', $code, 0 ) ;
  $self->{'BLOCKSCANNER_COMMENTLINENO'} = $self->{'LINENO'} ;
}

=pod

=item * transition_callback_code_long_comment()

This method is called each time a transition
from the state 'code' to the state
'long_comment' was encountered.
Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub transition_callback_code_long_comment($) {
  my $self = shift ;
  my $code = $_[0] || '' ;
  $self->addblock( 'CODE', $code , 0) ;
}

=pod

=item * transition_callback_code_short_comment()

This method is called each time a transition
from the state 'code' to the state
'short_comment' was encountered.
4Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub transition_callback_code_short_comment($) {
  my $self = shift ;
  my $code = $_[0] || '' ;
  $self->addblock( 'CODE', $code, 0 ) ;
}

=pod

=item * transition_callback_code_short_doc_comment()

This method is called each time a transition
from the state 'code' to the state
'short_doc_comment' was encountered.
Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub transition_callback_code_short_doc_comment($) {
  my $self = shift ;
  my $code = $_[0] || '' ;
  $self->addblock( 'CODE', $code, 0 ) ;
  $self->{'BLOCKSCANNER_COMMENTLINENO'} = $self->{'LINENO'} ;
}

=pod

=item * transition_callback_code_htmlcode()

This method is called each time a transition
from the state 'code' to the state
'htmlcode' was encountered.
Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub transition_callback_code_htmlcode($) {
  my $self = shift ;
  my $code = $_[0] || '' ;
  $self->addblock( 'CODE', $code, 0 ) ;
}

=pod 

=item * EOF_callback_function()

The methid is called each time the EOF was encountered
and a transition with pattern '$EOF' is not found from
the current state.

=over

=item * token (string)

is the token which is not already eaten by the machine.

=back

=cut
sub EOF_callback_function($)  {
  my $self = shift ;
  if( $self->getcurrentstate() eq 'code' ) {
    my $code = $_[0] || '' ;
    $self->addblock( 'CODE', $code, 0 ) ;
  }
}

#------------------------------------------------------
#
# Block functions
#
#------------------------------------------------------

=pod

=item * clearblocks()

Destroyes all recognized blocks.

=cut
sub clearblocks() {
  my $self = shift ;
  $self->{'BLOCKSCANNER_BLOCKS'} = [] ;
}

=pod

=item * getblocks()

Replies an array of all the recognized blocks.

=cut
sub getblocks() {
  my $self = shift ;
  my @blocks = () ;
  my $prev = "" ;
  my $lineno = 0 ;
  foreach my $b (@{$self->{'BLOCKSCANNER_BLOCKS'}}) {
    if ( $b->{'type'} eq 'CODE' ) {
      if ( $prev ) {
        my %block = ( 'comment' => $prev,
	   	      'code' => $b->{'content'} ) ;
	$block{'code'} =~ s/^\s+// ;
	$block{'code'} =~ s/\s+$// ;
	if ( $lineno > 0 ) {
	  $block{'lineno'} = $lineno ;
	}
        push( @blocks, \%block ) ;
      }
      $prev = "" ;
      $lineno = 0 ;
    }
    else {
      if ( $prev ) {
	my %block = ( 'comment' => $prev,
		      'code' => "" ) ;
	if ( $lineno > 0 ) {
	  $block{'lineno'} = $lineno ;
	}
	push( @blocks, \%block ) ;
      }
      $prev = $self->removecommentdelims( $b->{'content'} ) ;
      $lineno = $b->{'lineno'} || 0 ;
    }
  }
  if ( $prev ) {
    my %block = ( 'comment' => $prev,
       	      	  'code' => "", ) ;
    if ( $lineno > 0 ) {
      $block{'lineno'} = $lineno ;
    }
    push( @blocks, \%block ) ;
  }

  return @blocks ;
}

=pod

=item * removecommentdelims()

Replies a string which corresponds to the specified
comment string on which the delimiters are removed.

=over

=item * comment (string)

is the content of the comment (including delimiters).

=back

=cut
sub removecommentdelims($) {
  my $self = shift ;
  my $comment = $_[0] || '' ;

  # Removes the delimiters
  my $newcomment = '' ;
  while ( $comment =~ /^(.*?)(?:(?:\/\*(.*?)\*\/)|(?:\/\/(.*?)\n))(.*)$/s ) {
    my ($before,$cmt,$after) = ($1, $2 || $3, $4) ;
    $comment = $after ;
    $newcomment .= " $before $cmt" ;
  }
  if ( $comment ) {
    $newcomment .= " $comment" ;
  }

  # Removes the spaces before a star in the beginning
  # of each line
  $newcomment =~ s/^[ \t]*\*//gm ;

  # Removes the white spaces
  $newcomment =~ s/\s+$//s ;

  return $newcomment ;
}

=pod

=item * addblock()

Adds a block.
Takes 2 args:

=over

=item * type (string)

is the type of the block.

=item * content (string)

is the content of the block.

=item * lineno (integer)

is the line number where the block was found.
If it is equals to zero, it will be ignored.

=back

=cut
sub addblock($$$) {
  my $self = shift ;
  confess( 'invalid type block type' ) unless $_[0] ;
  my $lineno = $_[2] || 0 ;
  my $content = $_[1] || '' ;
  $content =~ s/^[ \n\r\t]+// ;
  $content =~ s/[ \n\r\t]+$// ;
  if ( $content ) {
    my $b = $self->lastblock() ;
    if ( ( ishash($b) ) &&
	 ( ! ( $_[0] eq 'LONG_COMMENT' ) ) &&
         ( $b->{'type'} eq $_[0] ) ) {
      # Merges to the previous block
      $b->{'content'} .= $content ;
    }
    else {
      # Adds a new block
      my %hb = ( 'type' => $_[0],
       	         'content' => $content,
	         'lineno' => ($lineno>0)?$lineno:0,
	       ) ;
      push( @{$self->{'BLOCKSCANNER_BLOCKS'}},
    	    \%hb ) ;
    }
  }
}

=pod

=item * lastblock()

Replies the last block or false.

=cut
sub lastblock() {
  my $self = shift ;
  if ( @{$self->{'BLOCKSCANNER_BLOCKS'}} > 0 ) {
    return $self->{'BLOCKSCANNER_BLOCKS'}->[$#{$self->{'BLOCKSCANNER_BLOCKS'}}] ;
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

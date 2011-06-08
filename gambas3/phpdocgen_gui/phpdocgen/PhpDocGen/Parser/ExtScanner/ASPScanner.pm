# Copyright (C) 2002-03-03  Stephane Galland <galland@arakhne.org>
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

PhpDocGen::Parser::ExtScanner::ASPScanner - A scanner for extracted source blocks

=head1 SYNOPSYS

use PhpDocGen::Parser::ExtScanner::ASPScanner ;

my $scan = PhpDocGen::Parser::ExtScanner::ASPScanner->new() ;

=head1 DESCRIPTION

PhpDocGen::Parser::ExtScanner::ASPScanner is a Perl module, which scannes
a source file to recognize the ASP source blocks. This scanner supports
the following ASP comments :
//**
// Long comment

//--
// Long comment

=head1 GETTING STARTED

=head2 Initialization

To start a scanner, say something like this:

    use PhpDocGen::Parser::ExtScanner::ASPScanner;

    my $scan = PhpDocGen::Parser::ExtScanner::ASPScanner->new() ;

...or something similar.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in ASPScanner.pm itself.

=over

=cut

package PhpDocGen::Parser::ExtScanner::ASPScanner;

@ISA = ('PhpDocGen::Parser::BlockScanner');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;
use File::Basename ;

use PhpDocGen::Parser::BlockScanner ;
use PhpDocGen::General::Misc ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the scanner
my $VERSION = "0.1" ;

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
    $self = $class->SUPER::new(
              { 'code' => [ { state => 'long_doc_comment',
	                      pattern => '\/\*\*',
			      merge => 1,
			      splitmerging => 1,
	                    },
			    { state => 'long_comment',
	                      pattern => '\/\*',
			      merge => 1,
			      splitmerging => 1,
	                    },
                            { state => 'qqstring',
	                      pattern => '"',
			      merge => 1,
	                    },
                            { state => 'qstring',
	                      pattern => '\'',
			      merge => 1,
	                    },
                            { state => 'short_doc_comment',
	                      pattern => '\/\/\*+',
			      merge => 1,
			      splitmerging => 1,
	                    },
                            { state => 'short_doc_comment',
	                      pattern => '\/\/\-+',
			      merge => 1,
			      splitmerging => 1,
	                    },
                            { state => 'short_comment',
	                      pattern => '\/\/',
			      merge => 1,
			      splitmerging => 1,
	                    },
			    { state => 'code',
			      pattern => '[^\/\'"]+',
			      merge => 1,
			    },
			    { state => 'code',
			      pattern => '\/',
			      merge => 1,
			    },
			  ],
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
	        'short_doc_comment' => [ { state => 'endline_short_doc_comment',
		                           pattern => "\n",
					   merge => 1,
					 },
					 { state => 'short_doc_comment',
					   pattern => "[^\n]+",
					   merge => 1,
					 },
				       ],
	        'endline_short_doc_comment' => [ { state => 'short_doc_comment',
	                                           pattern => '\/\/\*+',
			                           merge => 1,
	                                         },
                                                 { state => 'short_doc_comment',
	                                           pattern => '\/\/\-+',
			                           merge => 1,
	                                         },
                                                 { state => 'short_doc_comment',
	                                           pattern => '\/\/',
			                           merge => 1,
	                                         },
                                                 { state => 'endline_short_doc_comment',
	                                           pattern => '[\ \t]+',
			                           merge => 1,
	                                         },
                                                 { state => 'code',
	                                           pattern => '.',
			                           merge => 1,
						   splitmerging => 1,
	                                         },
				               ],
	        'qstring' => [ { state => 'code',
		                 pattern => '\'',
				 merge => 1,
			       },
			       { state => 'qstring',
		                 pattern => '\\.?',
				 merge => 1,
			       },
			       { state => 'qstring',
			         pattern => '[^\\\']+',
				 merge => 1,
			       },
			     ],
	        'qqstring' => [ { state => 'code',
		                  pattern => '"',
				  merge => 1,
				},
			        { state => 'qqstring',
		                  pattern => '\\.?',
				  merge => 1,
			        },
			        { state => 'qqstring',
			          pattern => '[^\\"]+',
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
	      'code',
	      [ 'code', 'short_comment', 'short_doc_comment' ]
              ) ;
  }
  bless( $self, $class );
  return $self;
}

=pod

=item * get_copyright()

Replies a copyright string for this scanner.

=cut
sub get_copyright() {
  my $self = shift ;
  return join( '',
	       "phpdocgen extended scanner ASPScanner.\n",
	       "Copyright (C) 2002-03-03  Stephane Galland <galland\@arakhne.org>\n\n",
	       "This scanner permits to supports the ASP-like comments.\n",
	       "It is provided as an experimental feature.\n" ) ;
}

#------------------------------------------------------
#
# Callback functions
#
#------------------------------------------------------

=pod

=item * transition_callback_endline_short_doc_comment_code()

This method is called each time a transition
from the state 'endline_short_doc_comment' to the state
'code' was encountered.
Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub transition_callback_endline_short_doc_comment_code($) {
  my $self = shift ;
  my $comment = $_[0] ;
  $self->addblock( 'SHORT_COMMENT', $comment,
		   $self->{'BLOCKSCANNER_COMMENTLINENO'} ) ;
  $self->{'BLOCKSCANNER_COMMENTLINENO'} = 0 ;
}

#------------------------------------------------------
#
# Block functions
#
#------------------------------------------------------

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
  my $comment = $_[0] ;

  # Remove the //* in the begining of each line
  $comment =~ s/^\s*\/\/\*+//gm ;

  # Remove the //- in the begining of each line
  $comment =~ s/^\s*\/\/\-+//gm ;

  # Remove the //- in the begining of each line
  $comment =~ s/^\s*\/\///gm ;

  return $self->SUPER::removecommentdelims( $comment ) ;
}

1;
__END__

=back

=head1 COPYRIGHT

(c) Copyright 2002-03 Stéphane Galland E<lt>galland@arakhne.orgE<gt>, under GPL.

=head1 AUTHORS

=over

=item *

Conceived and initially developed by Stéphane Galland E<lt>galland@arakhne.orgE<gt>.

=back

=head1 SEE ALSO

phpdocgen.pl

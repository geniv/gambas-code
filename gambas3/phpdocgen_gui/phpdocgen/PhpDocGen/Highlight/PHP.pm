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

PhpDocGen::Highlight::PHP - Object to highlight a PHP source code

=head1 DESCRIPTION

PhpDocGen::Highlight::PHP is a Perl module, which permits to highlight
the PHP source codes.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in PHP.pm itself.

=over

=cut

package PhpDocGen::Highlight::PHP;

@ISA = ('PhpDocGen::Parser::StateMachine');
@EXPORT = qw(&highlight_php);
@EXPORT_OK = qw(&new &highlight);

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Carp ;

use PhpDocGen::General::Error ;
use PhpDocGen::Parser::StateMachine ;
use PhpDocGen::General::Misc ;
use PhpDocGen::General::PHP ;
use PhpDocGen::General::HTML ;


#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the PHP support functions
my $VERSION = "0.4" ;

#------------------------------------------------------
#
# Predefined PHP variables support
#
#------------------------------------------------------

# PHP operators
my @PHP_OPERATORS = ( '+',      '(',      ')',
		      '{',      '}',      '.',
		      '-',      '/',      '*',
		      '%',      '<',      '>',
		      '=',      ';',      ',',
		      '[',      ']',      '?',
		      ':',      '!',      '~' ) ;

my @LIBRARY_FUNCTIONS = ( # package ARRAY
			 'array', 'array_count_values', 'array_flip',
			 'array_keys', 'array_merge', 'array_pad',
			 'array_pop', 'array_push', 'array_reverse',
			 'array_shift', 'array_slice','array_splice',
			 'array_unshift', 'array_values', 'array_walk',
			 'arsort', 'asort', 'compact', 'count', 'current',
			 'each', 'end', 'extract', 'in_array', 'key',
			 'krsort', 'ksort', 'list', 'next', 'pos', 'prev',
			 'range', 'reset', 'rsort', 'shuffle', 'sizeof',
			 'sort', 'uasort', 'uksort', 'usort',
			 # package DATE
			 'checkdate', 'date', 'getdate', 'gettimeofday',
			 'gmdate', 'gmmktime', 'gmstrftime', 'microtime',
			 'mktime', 'strftime', 'time',
			 # package DIRECTORY
			 'chdir', 'dir', 'closedir', 'opendir', 'readdir',
			 'rewinddir',
			 # package FILESYSTEM
			 'basename', 'chgrp', 'chmod', 'chown', 'clearstatcache',
			 'copy', 'dirname',  'diskfreespace', 'fclose', 'feof',
			 'fgetc', 'fgets', 'file', 'file_exists', 'fileatime',
			 'filectime', 'filegroup', 'fileinode', 'filemtime',
			 'fileowner', 'fileperms', 'filesize', 'filetype',
			 'flock', 'fopen', 'fpassthru', 'fputs', 'fread',
			 'fseek', 'ftell', 'fwrite', 'is_dir', 'is_executable',
			 'is_file', 'is_link', 'is_readable', 'is_writeable',
			 'link', 'linkinfo', 'mkdir', 'readfile', 'readlink',
			 'rename', 'rewind', 'rmdir', 'stat', 'lstat', 'symlink',
			 'tempnam', 'touch', 'umask', 'unlink',
			 # package VARIABLE
			 'doubleval', 'empty', 'gettype', 'intval', 'is_array',
			 'is_double', 'is_float', 'is_int', 'is_integer', 'is_long',
			 'is_object', 'is_real', 'is_string', 'isset', 'print_r',
			 'settype', 'strval', 'unset', 'var_dump',
			 # package URL
			 'base64_encode', 'parse_url', 'urldecode', 'urlencode',
			 # package STRING
			 'addcslashes', 'addslashes', 'bin2hex', 'chop', 'chr',
			 'chunk_split', 'count_chars', 'crypt', 'explode',
			 'flush', 'get_meta_tags', 'htmlentities', 'htmlspecialchars',
			 'implode', 'ltrim', 'md5', 'nl2br', 'ord', 'parse_str',
			 'printf', 'quoted_printable_decode', 'quotemeta', 'sprintf',
			 'strcasecmp', 'strchr', 'strcmp', 'strcspn', 'strip_tags',
			 'stripcslashes', 'stripslashes', 'stristr', 'strlen', 'strpos',
			 'strrchr', 'str_repeat', 'strrev', 'strrpos', 'strspn', 'strstr',
			 'strtok', 'strtolower', 'strtoupper', 'str_replace', 'strtr',
			 'substr', 'substr_replace', 'trim', 'ucfirst', 'ucwords',
			 # package REGULAR EXPRESSION
			 'ereg', 'ereg_replace', 'eregi', 'eregi_replace', 'split',
			 'preg_match', 'preg_match_all', 'preg_replace', 'preg_split',
			 'preg_quote', 'preg_grep',
			 # package SYSTEM
			 'escapeshellcmd', 'exec', 'passthru', 'system',
			 # package PHP
			 'error_log', 'error_reporting', 'extension_loaded', 'getenv',
			 'get_cfg_var', 'get_current_user', 'get_magic_quotes_gpc',
			 'get_magic_quotes_runtime', 'getlastmod', 'getmyinode',
			 'getmypid', 'getmyuid', 'getrusage', 'phpinfo', 'phpversion',
			 'php_logo_guid', 'putenv', 'set_magic_quotes_runtime',
			 'set_time_limit', 'zend_logo_guid',
			 'connection_aborted', 'connection_status', 'connection_timeout',
			 'defined', 'func_get_arg', 'func_get_args', 'func_num_args',
			 'function_exists', 'method_exists', 'get_browser', 
			 'ignore_user_abort', 'leak', 'pack', 'register_shutdown_function',
			 'serialize', 'sleep', 'uniqid', 'unpack', 'unserialize', 'usleep',
			 # package HTTP
			 'header', 'setcookie',
			) ;

my %STYLES = ( 'reserved' => '<FONT color="#006600">$$</FONT>',
               'string' => '<FONT color="#CC0000">$$</FONT>',
               'comment' => '<FONT color="#FF9900">$$</FONT>',
               'operator' => '<FONT color="#006600">$$</FONT>',
               'library' => '<I>$$</I>',
	       'html' => '<FONT color="#BBBBBB">$$</FONT>',
               'default' => '<FONT color="#0000CC">$$</FONT>' ) ;

#------------------------------------------------------
#
# Highlighting functions
#
#------------------------------------------------------

=pod

=item * highlight_php()

Replies the highlighted version of the specified source code
Takes 1 arg:

=over

=item * code (string)

is a I<string> which contains the code to highlight.

=back

=cut
sub highlight_php($) {
  my $sm ;
  eval "\$sm = ".__PACKAGE__."->new() ;" ;
  if ( $@ ) {
    confess($@) ;
  }
  return $sm->highlight( $_[0] ) ;
}

=pod

=item * highlight()

Replies the highlighted version of the specified source code
Takes 1 arg:

=over

=item * code (string)

is a I<string> which contains the code to highlight.

=back

=cut
sub highlight($)  {
  my $self = shift ;
  my $content = $_[0] || '' ;

  $self->resetstatemachine() ;
  $self->{'TRANSLATED_STRING'} = '' ;

   if ( $content !~ /^(\n|\r|\s)$/ ) {
     while ( $content ) {
       my $newcontent = $self->changestatefrom( $content ) ;
       if ( $newcontent eq $content ) {
	 PhpDocGen::General::Error::syserr( "the state machine does not find any rule ".
					    "that match the current content" ) ;
       }
       else {
	 $content = $newcontent ;
       }
     }
   }
  $self->changestateforEOF() ;
  my $style = $STYLES{'default'} ;
  $style =~ s/\$\$/$self->{'TRANSLATED_STRING'}/g ;
  return join( '',
	       "<PRE><CODE>\n",
	       $style,
	       "</CODE></PRE>" );
}

#------------------------------------------------------
#
# State machine constructor
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
              { 'file' => [ { state => 'code',
                              pattern => '<\\?(?:php)?',
			    },
			    { state => 'file',
                              pattern => '<',
			      merge => 1,
			    },
			    { state => 'file',
                              pattern => '[^<]+',
			      merge => 1,
			    },
			  ],
		'code' => [ { state => 'file',
                              pattern => '\\?>',
			      merge => 1,
			      splitmerging => 1,
                            },
                            { state => 'long_comment',
                              pattern => '\\/\\*',
			      merge => 1,
			      splitmerging => 1,
			    },
			    { state => 'short_comment',
                              pattern => '\\/\\/',
			      merge => 1,
			      splitmerging => 1,
			    },
			    { state => 'short_comment', # 'ignored_comment'
                              pattern => '#',
			      merge => 1,
			      splitmerging => 1,
			    },
			    { state => 'inline_string',
			      pattern => "\\<\\<+\\s*[a-zA-Z0-9_]+",
			    },
			    { state => 'qqstring',
                              pattern => '"',
			      merge => 1,
			      splitmerging => 1,
			    },
			    { state => 'qstring',
                              pattern => '\'',
			      merge => 1,
			      splitmerging => 1,
			    },
			    { state => 'code',
			      pattern => '\\$[a-zA-Z_][a-zA-Z0-9_]*',
			      merge => 1,
			    },
			    { state => 'code',
			      pattern => '&[a-zA-Z_][a-zA-Z0-9_]*',
			      merge => 1,
			    },
			    { state => 'code',
			      pattern => '@[a-zA-Z_][a-zA-Z0-9_]*',
			      merge => 1,
			    },
			    { state => 'code',
			      pattern => '%[a-zA-Z_][a-zA-Z0-9_]*',
			      merge => 1,
			    },
			    { state => 'keywords',
			      pattern => '[a-zA-Z_]',
			      merge => 1,
			      splitmerging => 1,
			    },
                            { state => 'code',
			      pattern => '.',
			      merge => 1,
			    },
			  ],
	        'keywords' => [ { state => 'keywords',
				  pattern => "[a-zA-Z0-9_]+",
				  merge => 1,
				},
				{ state => 'code',
				  pattern => ".",
				  merge => 1,
				  splitmerging => 1,
				},
			      ],
	        'long_comment' => [ { state => 'code',
				      pattern => '\\*\\/',
				    },
				    { state => 'long_comment',
				      pattern => '\\*',
				      merge => 1,
				    },
				    { state => 'long_comment',
				      pattern => '[^*]+',
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
	        'ignored_comment' => [ { state => 'code',
				         pattern => "\n",
				       },
				       { state => 'ignored_comment',
				         pattern => "[^\n]+",
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
	        'qqstring' => [ { state => 'qqstring',
				  pattern => '\\\\.',
				  merge => 1,
				},
				{ state => 'code',
				  pattern => '"',
				},
				{ state => 'qqstring',
				  pattern => '.',
				  merge => 1,
				},
			      ],
	        'qstring' => [ { state => 'qstring',
				 pattern => '\\\\.',
				 merge => 1,
			       },
			       { state => 'code',
				 pattern => '\'',
			       },
			       { state => 'qstring',
				 pattern => '.',
				 merge => 1,
			       },
			      ],
	      },
	      'file',
	      [ 'file', 'code', 'short_comment', 'ignored_comment', 'keywords' ]
              ) ;
    $self->{'TRANSLATED_STRING'} = "" ;
  }
  bless( $self, $class );
  return $self;
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
  if ( $str =~ /^\Q$self->{'INLINE_STRING_KEY'}\E/ms ) {
    $str =~ /^(.*)(\Q$self->{'INLINE_STRING_KEY'}\E)$/s ;
    my ($text,$code) = ($1,$2) ;
    $self->{'SM_CURRENT_STATE'} = 'code' ;
    $self->{'INLINE_STRING_KEY'} = '' ;
    $self->addStringConstant($text) ;
    $self->addSourceCode($code) ;
  }
  else {
    $self->{'SM_CURRENT_STATE'} = 'inline_string' ;
    $self->addStringConstant($str) ;
  }
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
  my $code = $_[0] || '' ;
  $code =~ /\<\<+\s*([^\s]+)$/ ;
  $self->{'INLINE_STRING_KEY'} = $1 ;
  $self->addSourceCode($code) ;
}

=pod

=item * transition_callback_file_code()

This method is called each time a transition
from the state 'file' to the state
'code' was encountered.
Takes 1 arg:

=over

=item * filecontent (string)

is the recognized filecontent.

=back

=cut
sub transition_callback_file_code($) {
  my $self = shift ;
  my $htmlcode = $_[0] || '' ;
  $self->addHTMLCode($htmlcode);
}

=pod

=item * transition_callback_code_file()

This method is called each time a transition
from the state 'file' to the state
'code' was encountered.
Takes 1 arg:

=over

=item * filecontent (string)

is the recognized filecontent.

=back

=cut
sub transition_callback_code_file($) {
  my $self = shift ;
  my $code = $_[0] || '' ;
  $self->addSourceCode($code) ;
}

=pod

=item * transition_callback_code_keywords()

This method is called each time a transition
from the state 'code' to the state
'keywords' was encountered.
Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub transition_callback_code_keywords($) {
  my $self = shift ;
  my $code = $_[0] || '' ;
  $self->addSourceCode($code) ;
}

=pod

=item * transition_callback_keywords_code()

This method is called each time a transition
from the state 'keywords' to the state
'code' was encountered.
Takes 1 arg:

=over

=item * keyword (string)

is the recognized keyword.

=back

=cut
sub transition_callback_keywords_code($) {
  my $self = shift ;
  my $kw = $_[0] || '' ;
  $self->addSourceKeyword($kw) ;
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
  $self->addSourceCode($code) ;
}

=pod

=item * transition_callback_code_ignored_comment()

This method is called each time a transition
from the state 'code' to the state
'ignored_comment' was encountered.
Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub transition_callback_code_ignored_comment($) {
  my $self = shift ;
  my $code = $_[0] || '' ;
  $self->addSourceCode($code) ;
}

=pod

=item * transition_callback_short_comment_code()

This method is called each time a transition
from the state 'short_comment' to the state
'code' was encountered.
Takes 1 arg:

=over

=item * comment (string)

is the recognized comment.

=back

=cut
sub transition_callback_short_comment_code($) {
  my $self = shift ;
  my $comment = $_[0] || '' ;
  $self->addComment($comment) ;
}

=pod

=item * transition_callback_code_short_comment()

This method is called each time a transition
from the state 'code' to the state
'short_comment' was encountered.
Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub transition_callback_code_short_comment($) {
  my $self = shift ;
  my $code = $_[0] || '' ;
  $self->addSourceCode($code) ;
}

=pod

=item * transition_callback_qqstring_code()

This method is called each time a transition
from the state 'qqstring' to the state
'code' was encountered.
Takes 1 arg:

=over

=item * text (string)

is the recognized text.

=back

=cut
sub transition_callback_qqstring_code($) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  $self->addStringConstant($text) ;
}

=pod

=item * transition_callback_code_qqstring()

This method is called each time a transition
from the state 'code' to the state
'qqstring' was encountered.
Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub transition_callback_code_qqstring($) {
  my $self = shift ;
  my $code = $_[0] || '' ;
  $self->addSourceCode($code) ;
}

=pod

=item * transition_callback_qstring_code()

This method is called each time a transition
from the state 'qstring' to the state
'code' was encountered.
Takes 1 arg:

=over

=item * text (string)

is the recognized text.

=back

=cut
sub transition_callback_qstring_code($) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  $self->addStringConstant($text) ;
}

=pod

=item * transition_callback_code_qstring()

This method is called each time a transition
from the state 'code' to the state
'qstring' was encountered.
Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub transition_callback_code_qstring($) {
  my $self = shift ;
  my $code = $_[0] || '' ;
  $self->addSourceCode($code) ;
}

=pod

=item * transition_callback_long_comment_code()

This method is called each time a transition
from the state 'long_comment' to the state
'code' was encountered.
Takes 1 arg:

=over

=item * comment (string)

is the recognized comment.

=back

=cut
sub transition_callback_long_comment_code($) {
  my $self = shift ;
  my $comment = $_[0] || '' ;
  $self->addComment($comment) ;
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
  my $param = $_[0] || '' ;
  if( $self->getcurrentstate() eq 'long_comment' ) {
    $self->addComment( $param ) ;
  }
  elsif( $self->getcurrentstate() eq 'short_comment' ) {
    $self->addComment( $param ) ;
  }
  elsif( $self->getcurrentstate() eq 'qqstring' ) {
    $self->addStringConstant( $param ) ;
  }
  elsif( $self->getcurrentstate() eq 'qstring' ) {
    $self->addStringConstant( $param ) ;
  }
  elsif( $self->getcurrentstate() eq 'file' ) {
    $self->addHTMLCode( $param ) ;
  }
  else {
    $self->addSourceCode( $param ) ;
  }
}

#------------------------------------------------------
#
# Content management
#
#------------------------------------------------------

=pod

=item * addComment()

This method adds a comment to the current content.
Takes 1 arg:

=over

=item * comment (string)

is the recognized comment.

=back

=cut
sub addComment($) {
  my $self = shift ;
  my $comment = get_html_entities( $_[0] || '' ) ;
  $self->{'TRANSLATED_STRING'} .= $self->applysimplestyle( $STYLES{'comment'}, $comment ) ;
}

=pod

=item * addSourceCode()

This method adds a source code to the current content.
Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub addSourceCode($) {
  my $self = shift ;
  my $code = $_[0] || '' ;
  # Replaces the operators
  $code = $self->applystyle( \@PHP_OPERATORS, $STYLES{'operator'}, $code ) ;
  # Replaces the $this variable
  my @SELF = ( '$this' ) ;
  $code = $self->applystyle( \@SELF, $STYLES{'reserved'}, $code ) ;
  $self->{'TRANSLATED_STRING'} .= $code ;
}

=pod

=item * addHTMLCode()

This method adds an HTML code to the current content.
Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub addHTMLCode($) {
  my $self = shift ;
  my $code = get_html_entities( $_[0] || '' ) ;
  $code =~ s/^(\?&gt;)/$self->applysimplestyle($STYLES{'reserved'},$1);/e ;
  $code =~ s/(&lt;\?(?:php)?)$/$self->applysimplestyle($STYLES{'reserved'},$1);/e ;
  $code = $self->applysimplestyle( $STYLES{'html'}, $code ) ;
  $self->{'TRANSLATED_STRING'} .= $code ;
}

=pod

=item * addSourceKeyword()

This method adds a source keyword to the current content.
Takes 1 arg:

=over

=item * code (string)

is the recognized code.

=back

=cut
sub addSourceKeyword($) {
  my $self = shift ;
  my $kw = $_[0] || '' ;
  if ( is_reserved_php_keyword( $kw ) ) {
    $self->{'TRANSLATED_STRING'} .= $self->applysimplestyle( $STYLES{'reserved'}, $kw ) ;
  }
  elsif ( strinarray( $kw, \@LIBRARY_FUNCTIONS ) ) {
    $self->{'TRANSLATED_STRING'} .= $self->applysimplestyle( $STYLES{'library'}, $kw ) ;
  }
  else {
    $self->{'TRANSLATED_STRING'} .= $self->applysimplestyle( $STYLES{'default'}, $kw ) ;
  }
}

=pod

=item * addStringConstant()

This method adds a string constant to the current content.
Takes 1 arg:

=over

=item * text (string)

is the recognized text.

=back

=cut
sub addStringConstant($) {
  my $self = shift ;
  my $text = get_html_entities( $_[0] || '' ) ;
  $self->{'TRANSLATED_STRING'} .=  $self->applysimplestyle( $STYLES{'string'}, $text ) ;
}




sub applysimplestyle($$) {
  my $self = shift ;
  my $tr = $_[0] || '' ;
  my $rep = $_[1] || '' ;
  $tr =~ s/\$\$/$rep/ ;
  return $tr ;
}

=pod

=item * applystyle()

This method applies the specified style on the specified code
Takes 3 arg:

=over

=item * elements (array)

is the syntactic elements to format.

=item * style (string)

is the style of the syntactic elements (in which $$
will be replaced by the syntactic element).

=item * code (string)

is the code to format.

=back

=cut
sub applystyle($$$) {
  my $self = shift ;
  my $code = $_[2] || '' ;
  my $style = $_[1] || '$$' ;
  my $cnt = "" ;
  my $tgs = "" ;
  return $code unless ( $_[0] && isarray($_[0]) ) ;
  foreach my $elt (@{$_[0]}) {
    if ( $tgs ) {
      $tgs .= "|" ;
    }
    $tgs .= "\Q$elt\E" ;
  }
  my @parts = split( /($tgs)/, $code ) ;
  foreach my $p (@parts) {
    if ( $p ) {
      if ( $p =~ /$tgs/ ) {
	$p =~ s/</&lt;/g ;
	$p =~ s/>/&gt;/g ;
	$cnt .= $self->applysimplestyle( $style, $p ) ;
      }
      else {
	$cnt .= $p ;
      }
    }
  }
  return $cnt ;
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

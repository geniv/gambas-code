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

PhpDocGen::General::Token - Token definitions

=head1 DESCRIPTION

PhpDocGen::General::Token is a Perl module, which permits to define
the tokens supported by phpdocgen.

=head1 CONSTANT DESCRIPTIONS

This section contains only the constants in Token.pm itself.

=over

=cut

package PhpDocGen::General::Token;

@ISA = ('Exporter');
@EXPORT = qw( &is_valid_type
              &get_comment_type
	      &get_real_tag
	      &get_all_comment_types
              %COMMON_SECTIONED_TAGS @COMMON_TAGS
	      %COMMENT_TYPE_TAGS @OTHER_TAGS
	      @INLINE_TAGS @INLINE_REENTRANT_TAGS
	      @TYPES %TRANSLATE_TYPES
	      %TRANSLATE_TAGS ) ;
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

use vars qw( %COMMON_SECTIONED_TAGS @COMMON_TAGS
	     %COMMENT_TYPE_TAGS @OTHER_TAGS
	     @INLINE_TAGS @INLINE_REENTRANT_TAGS
	     @TYPES %TRANSLATE_TYPES
	     %TRANSLATE_TAGS ) ;

use PhpDocGen::General::Misc ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the token definition
my $VERSION = "0.7" ;

#-------------
=pod

=item * %COMMON_SECTIONED_TAGS

Documentation tags that are common to all comments and
must appear in a section
The sections are ordered according to the order flag

=cut
%COMMON_SECTIONED_TAGS = ( 'todo' => { 'order' => 0,
				       'label' => 'I18N_LANG_TODO',
				       'separator' => '<li>',
				     },
			   'deprecated' => { 'order' => 1,
			                     'label' => 'I18N_LANG_DEPRECATED',
					     'separator' => '<br>',
			                   },
			   'author' => { 'order' => 2,
				         'label' => 'I18N_LANG_AUTHORS',
					 'separator' => ', ',
				       },
			   'since' => { 'order' => 3,
				       	'label' => 'I18N_LANG_SINCE',
				       	'separator' => '<br>',
				      },
			   'version' => { 'order' => 4,
					  'label' => 'I18N_LANG_VERSION',
					  'separator' => '<br>',
				       	},
			   'date' => { 'order' => 5,
				       'label' => 'I18N_LANG_DATE',
				       'separator' => '<br>',
				     },
			   'see' => { 'order' => 6,
				      'label' => 'I18N_LANG_SEE_ALSO',
				      'separator' => '<br>',
				    },
			   'copyright' => { 'order' => 7,
					    'label' => 'I18N_LANG_COPYRIGHT',
					    'separator' => '<br>',
					  },
			 ) ;

#-------------
=pod

=item * @COMMON_TAGS

Documentation tags that are common to all comments and
must not appear in a section.

=cut
@COMMON_TAGS = ( 'brief', 'verbatim', 'bug', 'log' ) ;

#-------------
=pod

=item * %COMMENT_TYPE_TAGS

Documentation tags that are specify the type of
the comment. 'class' MUST be in the last.

=cut
%COMMENT_TYPE_TAGS = ( 'constant' => [],
		       'variable' => [],
		       'function' => [],
		       'class' => [ 'attribute', 'constructor',
				    'method',
				  ],
		       'webmodule' => [],
		       'webpage' => [],
		     ) ;

#-------------
=pod

=item * @OTHER_TAGS

Other documentation tags.

=cut
@OTHER_TAGS = ( 'extends', 'param', 'package',
		'return', 'use',
		'access', 'public', 'protected', 'private',
		'static' ) ;

#-------------
=pod

=item * @INLINE_TAGS

Inlined documentation tags that are not reentrant.

=cut
@INLINE_TAGS = ( 'link', 'block', 'example' ) ;

#-------------
=pod

=item * @INLINE_REENTRANT_TAGS

Inlined documentation tags that are reentrant.

=cut
@INLINE_REENTRANT_TAGS = ( 'hash' ) ;

#-------------
=pod

=item * %TRANSLATE_TAGS

Translation table for tags
(permits to support aliases for some tags).

=cut
%TRANSLATE_TAGS = ( 'inherited' => 'extends',
		    'modifiers' => 'access',
		    'var' => 'variable',
		    'const' => 'constant',
		    'func' => 'function',
		    'attr' => 'attribute',
		    'meth' => 'method',
		    'global' => 'use',
		  ) ;

#-------------
=pod

=item * @TYPES

Types supported by phpdocgen.

=cut
@TYPES = ( 'array',
	   'boolean', 'bool',
	   'float', 'flt',
	   'hash', 'hashtable',
	   'integer', 'int',
	   'number', 'num',
	   'resource',
	   'callback',
	   'mixed', 'mix',
	   'object', 'obj',
	   'string', 'str',
	   'timestamp', 'time', 'date' ) ;

#-------------
=pod

=item * %TRANSLATE_TYPES

Translation table for types
(permits to support aliases for some types).

=cut
%TRANSLATE_TYPES = ( 'hashtable' => 'hash',
		     'int' => 'integer',
		     'obj' => 'object',
		     'str' => 'string',
		     'time' => 'timestamp',
		     'date' => 'timestamp',
		     'mix' => 'mixed',
		     'flt' => 'float',
		     'num' => 'number',
		     'bool' => 'boolean' ) ;

#------------------------------------------------------
#
# Coherence functions
#
#------------------------------------------------------

=pod

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Token.pm itself.

=over

=item * is_valid_type()

Replies if the specified type was recognized by phpdocgen.
Takes 1 arg:

=over

=item * type_name (string)

is a I<string> which correspond to the type name to test.

=back

=cut
sub is_valid_type($) {
  return '' unless $_[0] ;
  my $type = lc( $_[0] ) ;
  foreach my $t (@TYPES) {
    if ( $t eq $type ) {
      if ( $TRANSLATE_TYPES{$type} ) {
	return $TRANSLATE_TYPES{$type} ;
      }
      else {
	return $type ;
      }
    }
  }
  return '' ;
}

=pod

=item * get_comment_type()

Replies the comment type of the specified
comment.
Takes 1 arg:

=over

=item * hash (hash ref)

is the associative array to check.

=back

=cut
sub get_comment_type($) {
  return undef unless ( $_[0] && ishash($_[0]) ) ;
  # First, try to found a sub type
  # which must be prior to main types
  foreach my $type ( keys %COMMENT_TYPE_TAGS ) {
    if ( ( $COMMENT_TYPE_TAGS{$type} ) &&
	 ( ! isemptyarray( $COMMENT_TYPE_TAGS{$type} ) ) ) {
      foreach my $subtype ( @{$COMMENT_TYPE_TAGS{$type}} ) {
	if ( exists $_[0]{"@".$subtype} ) {
	  return $subtype ;
	}
      }
    }
  }
  foreach my $type ( keys %COMMENT_TYPE_TAGS ) {
    if ( exists $_[0]{"@".$type} ) {
      return $type ;
    }
  }
  return undef ;
}

=pod

=item * get_all_comment_types()

Replies all the comment type tags.

=cut
sub get_all_comment_types() {
  my @t = () ;
  foreach my $v ( values %COMMENT_TYPE_TAGS ) {
    if ( $v && ( ! isemptyarray($v) ) ) {
      push @t, @{$v} ;
    }
  }
  foreach my $k ( keys %COMMENT_TYPE_TAGS ) {
    if ( $k ) {
      push @t, $k ;
    }
  }
  return \@t ;
}

=pod

=item * get_real_tag()

Replies the real tag. It means that tag aliases
are replaced by the real tags.
Takes 1 arg:

=over

=item * tag (string)

is the name of the tag to translate.

=back

=cut
sub get_real_tag($) {
  my $tag = $_[0] || '' ;
  my $at = 0 ;
  if ( $tag =~ /^\@(.*)$/ ) {
    $tag = $1 ;
    $at = 1 ;
  }
  foreach my $alias (keys %TRANSLATE_TAGS) {
    if ( $alias eq $tag ) {
      return ($at?'@':'').$TRANSLATE_TAGS{$alias} ;
    }
  }
  return ($at?'@':'').$tag ;
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

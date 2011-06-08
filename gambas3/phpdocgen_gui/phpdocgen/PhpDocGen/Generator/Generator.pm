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

PhpDocGen::Generator::Generator - An abstract generator

=head1 SYNOPSYS

use PhpDocGen::Generator::Generator ;

my $gen = PhpDocGen::Generator::Generator->new(
                      documentation_content,
                      long_title,
                      short_title,
                      output_path ) ;

=head1 DESCRIPTION

PhpDocGen::Generator::Generator is a Perl module, which proposes
an abstract definition of a documentation generation.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use PhpDocGen::Generator::Generator;

    my $gen = PhpDocGen::Generator::Generator->new(
                $content,
		"This is the documentation",
		"Documentation",
		"/tmp/phpdoc/" ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * content (hash ref)

The content of the documentation inside an hashtable.

=item * long_title (string)

The title of the documentation in a long format.

=item * short_title (string)

The title of the documentation in brief format.

=item * output (string)

The directory or the file in which the documentation
must be put.

=item * lang (string)

is the name of the language to use

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Generator.pm itself.

=over

=cut

package PhpDocGen::Generator::Generator;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;
use File::Spec ;

use PhpDocGen::General::Token ;
use PhpDocGen::General::Misc ;
use PhpDocGen::General::Error ;
use PhpDocGen::General::Parsing ;
use PhpDocGen::General::HTML ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of abstract generator
my $VERSION = "0.5" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$$$$)  {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = () ;

  %{$self->{'CONTENT'}} = %{$_[0]} ;
  $self->{'TITLE'} = $_[1] || '' ;
  $self->{'SHORT_TITLE'} = $_[2] || '' ;
  $self->{'TARGET'} = $_[3] || confess( 'invalid output path' ) ;
  # Language management
  my $lang = $_[4] || 'English' ;
  if ( ( $lang ) &&
       ( $lang !~ /::/ ) ) {
    $lang = "PhpDocGen::Generator::Html::Lang::".$lang ;
  }
  eval "require ".$lang.";" ;
  if ( $@ ) {
    PhpDocGen::General::Error::syserr( "Unable to load the HTML language $lang:\n$@" ) ;
  }
  $self->{'LANG'} = ($lang)->new() ;
  # Title
  if ( ! $self->{'TITLE'} ) {
    if ( $self->{'SHORT_TITLE'} ) {
      $self->{'TITLE'} = $self->{'SHORT_TITLE'} ;
    }
    else {
      $self->{'TITLE'} = $self->{'LANG'}->get('I18N_LANG_DEFAULT_TITLE') ;
    }
  }
  if ( ! $self->{'SHORT_TITLE'} ) {
    $self->{'SHORT_TITLE'} = $self->{'LANG'}->get('I18N_LANG_DEFAULT_TITLE') ;
  }

  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Extract some information from the documentation tree
#
#------------------------------------------------------

=pod

=item * get_class_ancestor()

Replies an array that contains all the ancestors
of the specified class.
Takes 1 arg:

=over

=item * name (string)

is the name of the class from which we want
the ancestors.

=back

=cut
sub get_class_ancestors($)  {
  my $self = shift ;
  confess( 'empty class key' ) unless $_[0] ;
  my @tree = () ;
  my $kclass = formathashkeyname( $_[0] ) ;
  my $extends = formathashkeyname( $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'extends'}{'class'} ) ;
  while ( $extends ) {
    push( @tree, $extends ) ;
    if ( exists $self->{'CONTENT'}{'classes'}{$extends} ) {
      $extends = formathashkeyname( $self->{'CONTENT'}{'classes'}{$extends}{'this'}{'extends'}{'class'} ) ;
    }
    else {
      $extends = "" ;
    }
  }
  return reverse @tree ;
}

=pod

=item * get_class_children()

Replies an array that contains all the children
of the specified class
Takes 1 arg:

=over

=item * name (string)

is the name of the class from which we want
the children.

=back

=cut
sub get_class_children($)  {
  my $self = shift ;
  confess( 'empty class key' ) unless $_[0] ;
  my @list = () ;
  my $desired = formathashkeyname( $_[0] ) ;
  foreach my $class (keys %{$self->{'CONTENT'}{'classes'}}) {
    my $ext = formathashkeyname( $self->{'CONTENT'}{'classes'}{$class}{'this'}{'extends'}{'class'} ) ;
    if ( ( $ext ) && ( $ext eq $desired ) ) {
      push( @list, $class ) ;
    }
  }
  return sort @list ;
}

=pod

=item * is_classmember_name()

Replies if the specified string is the name of
a class member.
Takes 1 arg:

=over

=item * name (string)

is the name to test.

=back

=cut
sub is_classmember_name($)  {
  my $self = shift ;
  my $name = $_[0] || '' ;
  return $name =~ /\:\:/ ;
}

=pod

=item * is_class()

Replies if the specified string is the name of a class.
Takes 1 arg:

=over

=item * name (string)

is the name of the class.

=back

=cut
sub is_class($)  {
  my $self = shift ;
  if ( $_[0] ) {
    my $name = formathashkeyname( $_[0] ) ;
    return exists $self->{'CONTENT'}{'classes'}{$name} ;
  }
  else {
    return undef ;
  }
}

=pod

=item * is_globalelement()

Replies if the specified string is the name
of a global element.
Takes 1 arg:

=over

=item * name (string)

is the name of the element.

=back

=cut
sub is_globalelement($)  {
  my $self = shift ;
  if ( $_[0] ) {
    my $key = formatvarkeyname( $_[0] ) ;
    my $fkey = formatfctkeyname( $_[0] ) ;
    foreach my $kpack (keys %{$self->{'CONTENT'}{packages}}) {
      if ( ( exists( $self->{'CONTENT'}{packages}{$kpack}{constants} ) ) &&
	   ( exists( $self->{'CONTENT'}{packages}{$kpack}{constants}{$key} ) ) ) {
	return $self->{'CONTENT'}{packages}{$kpack}{constants}{$key}{'name'} ;
      }
      elsif( ( exists( $self->{'CONTENT'}{packages}{$kpack}{variables} ) ) &&
	     ( exists( $self->{'CONTENT'}{packages}{$kpack}{variables}{$key} ) ) ) {
	return $self->{'CONTENT'}{packages}{$kpack}{variables}{$key}{'name'} ;
      }
      elsif( ( exists( $self->{'CONTENT'}{packages}{$kpack}{functions} ) ) &&
	     ( exists( $self->{'CONTENT'}{packages}{$kpack}{functions}{$fkey} ) ) ) {
	return $self->{'CONTENT'}{packages}{$kpack}{functions}{$fkey}{'name'} ;
      }
    }
  }
  return "" ;
}

=pod

=item * is_webmodule()

Replies if the specified string is the name
of a webmodule.
Takes 1 arg:

=over

=item * name (string)

is the name of the element.

=back

=cut
sub is_webmodule($)  {
  my $self = shift ;
  if ( $_[0] ) {
    my $name = $_[0] ;
    if ( $_[0] =~ /^web:(.+)$/i ) {
      $name = $1 ;
    }
    my %allmods = $self->get_all_notempty_webmodules() ;
    if ( exists $allmods{$name} ) {
      return ( $allmods{$name}{'name'} ) ? $allmods{$name}{'name'} : $name ;
    }
  }
  return "" ;
}

=pod

=item * is_webpage()

Replies if the specified string is the name
of a webpage.
Takes 1 arg:

=over

=item * name (string)

is the name of the element.

=back

=cut
sub is_webpage($)  {
  my $self = shift ;
  if ( $_[0] ) {
    my $name = $_[0] ;
    if ( $_[0] =~ /^web:(.+)$/i ) {
      $name = $1 ;
    }
    my %allpages = $self->get_all_webpages() ;
    if ( exists $allpages{$name} ) {
      return ( $allpages{$name}{'name'} ) ? $allpages{$name}{'name'} : $name ;
    }
  }
  return "" ;
}

=pod

=item * is_webelement()

Replies if the specified string is the name
of a web element.
Takes 1 arg:

=over

=item * name (string)

is the name of the element.

=back

=cut
sub is_webelement($)  {
  my $self = shift ;
  return ( ( $self->is_webmodule($_[0]) ) ||
           ( $self->is_webpage($_[0]) ) ) ;
}

=pod

=item * is_overridden_method()

Replies the name of the ancestor class in which the
specified method already defined.
Takes 2 args:

=over

=item * name (string)

is the name of the method.

=item * class (string)

is the name of the class from which we want
scan the ancestors.

=back

=cut
sub is_overridden_method($$)  {
  my $self = shift ;
  if ( ( $_[0] ) && ( $_[1] ) ) {
    my $kmeth = formatfctkeyname( $_[0] ) ;
    my $kclass = formathashkeyname( $_[1] ) ;
    my @ancestors = $self->get_class_ancestors( $kclass ) ;
    foreach my $ancestor (@ancestors) {
      my $kanc = formathashkeyname( $ancestor ) ;
      if ( ( exists( $self->{'CONTENT'}{classes}{$kanc}{methods} ) ) &&
	   ( exists( $self->{'CONTENT'}{classes}{$kanc}{methods}{$kmeth} ) ) ) {
	return $kanc ;
      }
    }
  }
  return "" ;
}


#------------------------------------------------------
#
# Inlined tag expand
#
#------------------------------------------------------

=pod

=item * expand_inlinedtag_link()

Translates a tag {@link}.
Takes 3 args:

=over

=item * tag (string)

is the content of the tag.

=item * root (string)

is the root directory.

=item * location (string)

is the location of the tag inside the input stream.

=back

=cut
sub expand_inlinedtag_link($$$)  {
  my $self = shift ;
  return '' unless $_[0] ;
  my $object = extract_param(1,$_[0],0) ;
  my $comment = extract_param(2,$_[0],1) ;
  return $self->get_hyperref( $object,
  	 		      $_[1],
			      $comment,
			      $_[2] ) ;
}

=pod

=item * expand_inlinedtag_hash()

Translates a tag {@hash}.
Takes 3 args:

=over

=item * tag (string)

is the content of the tag.

=item * root (string)

is the root directory.

=item * location (string)

is the location of the tag inside the input stream.

=back

=cut
sub expand_inlinedtag_hash($$$)  {
  my $self = shift ;
  return '<!-- @HASH -->' ;
}

=pod

=item * expand_inlinedtag_example()

Translates a tag {@example}.
Takes 3 args:

=over

=item * tag (string)

is the content of the tag.

=item * root (string)

is the root directory.

=item * location (string)

is the location of the tag inside the input stream.

=back

=cut
sub expand_inlinedtag_example($$$)  {
  my $self = shift ;
  my $text = $_[0] || '' ;
  my $rootdir = $_[1] || confess( 'you must provide the rootdir' ) ;
  my $file = '' ;
  # Try to detect the option
  my $option = lc( extract_param(1,$text,0) ) ;
  if ( ( $option eq 'noframe' ) ||
       ( $option eq 'frame' ) ) {
    $file = extract_param(2,$text,0) ;
    $text = extract_param(2,$text,1) ;
  }
  else {
    $option = 'noframe' ;
    $file = extract_param(1,$text,0) ;
  }
  my $pagefile = extract_file_from_location($_[2]) ;
  if ( $pagefile ) {
    my ($volume, $dirs, undef) = File::Spec->splitpath($pagefile) ;
    $pagefile = File::Spec->catpath($volume,$dirs,$file) ;
  }
  my $funcname = 'expand_inlinedtag_example_code' ;
  if ( ( $pagefile ) &&
       ( -f $pagefile ) ) {
    # Read the file
    local *INPUTSTREAM ;
    open( *INPUTSTREAM, "< $pagefile" )
      or PhpDocGen::General::Error::err( join( '',
					       "unable to open the example file '",
					       $pagefile,
					       "': ",
					       $! ),
					 extract_file_from_location($_[2]),
					 extract_line_from_location($_[2]) ) ;
    $text = '' ;
    while ( my $line = <INPUTSTREAM> ) {
      $text .= $line ;
    }
    close( *INPUTSTREAM ) ;
  }
  # Calls the formating function
  my $funcref = $self->can( $funcname ) ;
  if ( $funcref ) {
    return  $self->$funcref( ( $option eq 'frame' ),
			     $text,
			     $rootdir,
			     $_[2] ) ;
  }
  else {
    PhpDocGen::General::Error::err( join( '',
					  "Unable to find the function ",
					  $funcname,
					  '($$$$), which permits to ',
					  "translate a {\@example} tag.\n" ),
				    extract_file_from_location($_[2]),
				    extract_line_from_location($_[2]) ) ;
  }
}

#------------------------------------------------------
#
# Sentence functions
#
#------------------------------------------------------

=pod

=item * expand()

Replies the specified string in which the inlined
tags are translated (supports the verbatim mode).
Takes 3 args:

=over

=item * sentence (string)

is the sentence to expand.

=item * root (string)

is the root directory.

=item * location (string)

is the location of the tag inside the input stream.

=back

=cut
sub expand($$$)  {
  my $self = shift ;
  return '' unless $_[0] ;
  my $str = $self->expand_without_verb( $_[0], $_[1], $_[2] ) ;
  if ( $str =~ /^<!-- VERBATIM -->/ ) {
    $str = "<PRE><DIV>$str</DIV></PRE>" ;
  }
  return $str ;
}

=pod

=item * split_sentence()

Replies an array of the parts of a sentence.
Takes 1 arg:

=over

=item * sentence (string)

is the sentence to split.

=back

=cut
sub split_sentence($)  {
  my $self = shift ;
  return @{( '' )} unless $_[0] ;
  my $tgs = "" ;
  foreach my $t (@INLINE_TAGS,@INLINE_REENTRANT_TAGS) {
    if ( $tgs ) {
      $tgs .= "|" ;
    }
    $tgs .= "\\\{\\\@$t\\s+" ;
  }
  my ($first, @reste) = split( /($tgs)/, $_[0] ) ;
  my @parts = ( $first ) ;
  my $content = "" ;
  my $inlinedtag = "" ;
  foreach my $p (@reste) {
    if ( $p ) {
      if ( $p =~ /$tgs/ ) {
	$inlinedtag = $p ;
	$inlinedtag =~ s/^\{\@// ;
	$inlinedtag =~ s/\s+$// ;
      }
      elsif ( $inlinedtag ) {
        my ( $tagcontent, $aftertag ) = $self->__scan_for_inlined_tag_end( $p ) ;
        if ( $content ) {
          push( @parts, $content );
        }
	my %thetag ;
	if ( strinarray( $inlinedtag, \@INLINE_REENTRANT_TAGS ) ) {
	  my @subparts = $self->split_sentence( $tagcontent ) ;
	  %thetag = ( "$inlinedtag" => \@subparts ) ;
	}
	else {
	  %thetag = ( "$inlinedtag" => $tagcontent ) ;
	}
        push( @parts, \%thetag ) ;
        $inlinedtag = "" ;
        $content = $aftertag ;
      }
      else {
        $content .= $p ;
      }
    }
  }
  if ( $content ) {
     push(@parts, $content);
  }
  return @parts ;
}

=pod

=item * __scan_for_inlined_tag_end()

Used by split_sentence(). Replies the content of an just-opened inline tag AND the text after.
Takes 1 arg:

=over

=item * sentence (string)

is the sentence to scan.

=back

=cut
sub __scan_for_inlined_tag_end($)  {
  my $self = shift ;
  my ( $content, $reste ) = ( "", "" ) ;
  return ( $content, $reste ) unless $_[0] ;
  my @parts = split( /(\{|\})/, $_[0] ) ;
  my $openedbrace = 1 ;
  foreach my $p (@parts) {
    if ( $p ) {
      if ( $openedbrace >= 1 ) {
        if ( $p eq "{" ) {
          $openedbrace ++ ;
          $content .= $p ;
        }
        elsif ( $p eq "}" ) {
          $openedbrace -- ;
          if ( $openedbrace >= 1 ) {
            $content .= $p ;
          }
        }
        else {
          $content .= $p ;
        }
      }
      else {
        $reste .= $p ;
      }
    }
  }
  return ( $content, $reste ) ;
}

=pod

=item * expand_without_verb()

Replies the specified string in which the inlined
tags are translated (ignores the verbatim mode).
Takes 3 arg:

=over

=item * sentence (string)

is the sentence to expand.

=item * root (string)

is the root directory.

=item * location (string)

is the location of the tag inside the input stream.

=back

=cut
sub expand_without_verb($$$)  {
  my $self = shift ;
  return '' unless $_[0] ;
  my $rootdir = $_[1] || confess( 'you must provide the rootdir' ) ;
  my @parts = $self->split_sentence( $_[0] ) ;
  for( my $i=0; $i<=$#parts; $i++ ) {
    foreach my $t (@INLINE_TAGS, @INLINE_REENTRANT_TAGS) {
      if ( ( ishash( $parts[$i] ) ) &&
           ( exists $parts[$i]{$t} ) ) {
	my $funcname = 'expand_inlinedtag_'.$t ;
	my $funcref = $self->can( $funcname ) ;
	if ( $funcref ) {
	  $parts[$i] = $self->$funcref( $parts[$i]{$t},
				  	$rootdir,
				  	$_[2] ) ;
	}
	else {
	  PhpDocGen::General::Error::err( join( '',
						"Unable to find the function ",
						$funcname,
						"(), which permits to ",
						"translate a {\@$t} tag.\n" ),
					  extract_file_from_location($_[2]),
					  extract_line_from_location($_[2]) ) ;
	}
      }
    }
  }
  return join( '', @parts ) ;
}


=pod

=item * removestrings()

Removes the strings from a text.
Takes 2 args:

=over

=item * sentence (string)

is the sentence to parse.

=item * strings (array ref)

is the array that will contain the strings of the sentence.

=back

=cut
sub removestrings($$)  {
  my $self = shift ;
  return unless $_[0] ;
  @{$_[1]} = () unless isarray($_[1]) ;
  my $delims= "\\\"|\\'" ;
  my $count = $#{$_[1]} ;
  while ( $_[0] =~ /($delims)/ ) {
    my $delim = $1 ;
    if ( ! ( $_[0] =~ s/($delim(\\$delim|[^$delim])*$delim)/$_[1][++$count]="$1";"<<STRING".$count.">>"/e ) ) {
      if ( $delim =~ /\"/ ) {
	$_[0] =~ s/$delim/<<DOUBLEQUOTE>>/ ;
      }
      else {
	$_[0] =~ s/$delim/<<SIMPLEQUOTE>>/ ;
      }
    }
  }
}

=pod

=item * restorestrings()

Restores the strings inside a text.
Takes 2 args:

=over

=item * sentence (string)

is the sentence to parse.

=item * strings (array ref)

is the array that will contain the strings of the sentence.

=back

=cut
sub restorestrings($$)  {
  my $self = shift ;
  return unless ( ( $_[0] ) && ( isarray($_[1]) ) ) ;
  $_[0] =~ s/<<STRING([0-9]+)>>/$_[1][$1]/eg ;
  $_[0] =~ s/<<SIMPLEQUOTE>>/\'/g ;
  $_[0] =~ s/<<DOUBLEQUOTE>>/\"/g ;
}

=pod

=item * removeblocks()

Removes the blocks from a text.
Takes 2 args:

=over

=item * sentence (string)

is the sentence to parse.

=item * blocks (array ref)

is the array that will contain the blocks of the sentence.

=back

=cut
sub removeblocks($$)  {
  my $self = shift ;
  return unless $_[0] ;
  @{$_[1]} = () unless isarray($_[1]) ;
  my $count = $#{$_[1]} ;
  while ( $_[0] =~ /<SPAN>/ ) {
    $_[0] =~ s/(<SPAN>.*?<\/SPAN>)/$_[1][++$count]="$1";"<<BLOCK".$count.">>"/gse;
  }
}

=pod

=item * restoreblocks()

Restores the blocks inside a text.
Takes 2 args:

=over

=item * sentence (string)

is the sentence to parse.

=item * blocks (array ref)

is the array that will contain the blocks of the sentence.

=back

=cut
sub restoreblocks($$)  {
  my $self = shift ;
  return unless ( ( $_[0] ) && ( isarray($_[1]) ) ) ;
  $_[0] =~ s/<<BLOCK([0-9]+)>>/$_[1][$1]/eg ;
}


=pod

=item * firstsentence()

Replies the first sentence of a string.
Takes 3 args:

=over

=item * sentence (string)

is the sentence to expand.

=item * root (string)

is the root directory.

=item * location (string)

is the location of the tag inside the input stream.

=back

=cut
sub firstsentence($$$)  {
  my $self = shift ;
  return '' unless $_[0] ;
  my $rootdir = $_[1] || confess( 'you must spully the rootdir' ) ;
  my $str = $_[0] ;
  if ( $_[0] ) {
    my $str = $self->expand_without_verb( $str, $rootdir, $_[2] ) ;
    my @strings = () ;
    my @blocks = () ;
    my $sentence = "" ;
    $self->removestrings( $str, \@strings ) ;
    $self->removeblocks( $str, \@blocks ) ;
    $str =~ s/^([^\.\?\!]*)((\.|\?|\!)?)/$sentence="$1$2";/e ;
    $self->restorestrings( $sentence, \@strings ) ;
    $self->restoreblocks( $sentence, \@blocks ) ;
    return $sentence ;
  }
  else {
    return "&nbsp;" ;
  }
}


=pod

=item * briefcomment()

Replies the brief comment of the specified object.
Takes 2 args:

=over

=item * object (hash ref)

is the object from which the brief comment must be extracted.

=item * root (string)

is the root directory.

=back

=cut
sub briefcomment($$)  {
  my $self = shift ;
  return '' unless ( ($_[0]) && (ishash($_[0])) ) ;
  my $rootdir = $_[1] || confess( 'you must supply the rootdir' ) ;
  if ( exists $_[0]{'brief'} ) {
    my $text = "" ;
    my $location = "" ;
    if ( isarray( $_[0]{'brief'} ) ) {
      foreach my $brief (@{$_[0]{'brief'}}) {
	$text .= $brief->{'text'} ;
	if ( ! $location ) {
	  $location = $brief->{'location'} ;
	}
      }
    }
    else {
      $text = $_[0]{'brief'}{'text'} ;
      $location = $_[0]{'brief'}{'location'} ;
    }
    return $self->expand( $text, $rootdir, $location ) ;
  }
  else {
    return $self->firstsentence( $_[0]{'explanation'}{'text'},
    	   			 $rootdir,
				 $_[0]{'explanation'}{'location'} ) ;
  }
}

#------------------------------------------------------
#
# Hyper-referencing
#
#------------------------------------------------------

=pod

=item * format_ext_hyperref()

Replies an hyper-reference formatted according
to the generator.
Takes 6 args:

=over

=item * root (string)

is the root directory.

=item * pack (string)

is the name of the package.

=item * class (string)

is the name of the class.

=item * classmember (string)

is the class member that must be linked.

=item * comment (string)

is the comment attached to the returned reference.

=back

=cut
sub format_ext_hyperref($$$$$$)  {
  my $self = shift ;
  die( "You must override PhpDocGen::Generator::PhpDocGen::Generator::format_ext_hyperref()\n" ) ;
}

=pod

=item * format_ext_hyperref_web()

Replies an hyper-reference formatted according
to the generator.
Takes 4 args:

=over

=item * root (string)

is the root directory.

=item * mod (string)

is the name of the module.

=item * page (string)

is the name of the page.

=item * comment (string)

is the comment attached to the returned reference.

=back

=cut
sub format_ext_hyperref_web($$$$)  {
  my $self = shift ;
  die( "You must override PhpDocGen::Generator::PhpDocGen::Generator::format_ext_hyperref_web()\n" ) ;
}

=pod

=item * format_hyperref()

Replies an hyper-reference formatted according
to the generator.
Takes 2 args:

=over

=item * addr (string)

is the address of the reference.

=item * comment (string)

is the comment attached to the returned reference.

=back

=cut
sub format_hyperref($$)  {
  my $self = shift ;
  die( "You must override PhpDocGen::Generator::PhpDocGen::Generator::format_hyperref()\n" ) ;
}

=pod

=item * get_hyperref_class()

Replies a hyper-reference that corresponds to the
specified class.
Takes 4 args:

=over

=item * name (string)

is the name of the class.

=item * root (string)

is the root directory of the documentation.

=item * comment (string)

is the comment attached to the returned reference.

=item * location (string)

is the location of the link inside the input stream.

=back

=cut
sub get_hyperref_class($$$$)  {
  my $self = shift ;
  my $location = $_[3] || '' ;
  my $rootdir = $_[1] || confess( "the rootdir must be supplied" ) ;
  my $kclass = formathashkeyname( $_[0] ) ;
  if ( exists $self->{'CONTENT'}{'classes'}{$kclass} ) {
    my $class = $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'name'} ;
    my $comment = ( $_[2] ) ? $_[2] : $class ;
    my $kpack = formathashkeyname( $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'package'} ) ;
    my $pack = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
    return $self->format_ext_hyperref( $rootdir, $pack, $class, "", $comment ) ;
  }
  else {
    my $comment = ( $_[2] ) ? $_[2] : $_[0] ;
    return PhpDocGen::General::Error::invalidlink( $_[0],
						   $comment,
						   "unable to find the class $_[0].",
						   0,
						   $location ) ;
  }
}

=pod

=item * get_hyperref_webmodule()

Replies a hyper-reference that corresponds to the
specified webmodule.
Takes 4 args:

=over

=item * name (string)

is the name of the class.

=item * root (string)

is the root directory of the documentation.

=item * comment (string)

is the comment attached to the returned reference.

=item * location (string)

is the location of the link inside the input stream.

=back

=cut
sub get_hyperref_webmodule($$$$)  {
  my $self = shift ;
  my $location = $_[3] ;
  my $rootdir = $_[1] || confess( "the rootdir must be supplied" ) ;
  my $mod = $_[0] ;
  if ( $mod =~ /^web:(.+)$/i ) {
    $mod = $1 ;
  }
  $mod = htmlcanonpath($mod) ;
  my %allmods = $self->get_all_notempty_webmodules() ;
  if ( exists $allmods{$mod} ) {
    my $comment = ( $_[2] ) ? $_[2] : $allmods{$mod}{'name'} ;
    return $self->format_ext_hyperref_web( $rootdir, $mod, "", $comment ) ;
  }
  else {
    my $comment = ( $_[2] ) ? $_[2] : $_[0] ;
    return PhpDocGen::General::Error::invalidlink( $_[0],
						   $comment,
						   "unable to find the webmodule $_[0].",
						   0,
						   $location ) ;
  }
}

=pod

=item * get_hyperref_webpage()

Replies a hyper-reference that corresponds to the
specified webpage.
Takes 4 args:

=over

=item * name (string)

is the name of the class.

=item * root (string)

is the root directory of the documentation.

=item * comment (string)

is the comment attached to the returned reference.

=item * location (string)

is the location of the link inside the input stream.

=back

=cut
sub get_hyperref_webpage($$$$)  {
  my $self = shift ;
  my $location = $_[3] ;
  my $rootdir = $_[1] || confess( "the rootdir must be supplied" ) ;
  my $page = $_[0] ;
  if ( $page =~ /^web:(.+)$/i ) {
    $page = $1 ;
  }
  $page = htmlcanonpath($page) ;
  my %allpages = $self->get_all_webpages() ;
  if ( exists $allpages{$page} ) {
    my $comment = ( $_[2] ) ? $_[2] : $allpages{$page}{'name'} ;
    return $self->format_ext_hyperref_web( $rootdir, "", $page, $comment ) ;
  }
  else {
    my $comment = ( $_[2] ) ? $_[2] : $_[0] ;
    return PhpDocGen::General::Error::invalidlink( $_[0],
						   $comment,
						   "unable to find the webpage $_[0].",
						   0,
						   $location ) ;
  }
}

=pod

=item * get_hyperref_webelement()

Replies a hyper-reference that corresponds to the
specified web element.
Takes 4 args:

=over

=item * name (string)

is the name of the class.

=item * root (string)

is the root directory of the documentation.

=item * comment (string)

is the comment attached to the returned reference.

=item * location (string)

is the location of the link inside the input stream.

=back

=cut
sub get_hyperref_webelement($$$$)  {
  my $self = shift ;
  if ( $self->is_webmodule($_[0])) {
    return $self->get_hyperref_webmodule($_[0],$_[1],$_[2],$_[3]) ;
  }
  elsif ( $self->is_webpage($_[0])) {
    return $self->get_hyperref_webpage($_[0],$_[1],$_[2],$_[3]) ;
  }
  else {
    my $comment = ( $_[2] ) ? $_[2] : $_[0] ;
    return PhpDocGen::General::Error::invalidlink( $_[0],
						   $comment,
						   "unable to find the webelement $_[0].",
						   0,
						   $_[3] ) ;
  }
}

=pod

=item * get_hyperref_globalelement()

Replies a hyper-refernece that corresponds to the
specified global element
Takes 4 args:

=over

=item * name (string)

is the name of the global element.

=item * root (string)

is the root directory of the documentation.

=item * comment (string)

is the comment attached to the returned reference.

=item * location (string)

is the location of the link inside the input stream.

=back

=cut
sub get_hyperref_globalelement($$$$)  {
  my $self = shift ;
  my $location = $_[3] ;
  my $rootdir = $_[1] || confess( "the rootdir must be supplied" ) ;
  my $global = $_[0] ;
  my $comment = $_[2] ;
  my $packofglobal = "" ;
  my $page = "" ;
  my $anchor = "" ;
  my $kfglobal = formatfctkeyname($global) ;
  my $kglobal = formatvarkeyname($global) ;
  foreach my $kpack ( keys %{$self->{'CONTENT'}{'packages'}} ) {
    my $pack = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
    if ( ( exists $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kglobal} ) ||
	 ( exists $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kglobal} ) ||
	 ( exists $self->{'CONTENT'}{'packages'}{$kpack}{'functions'}{$kfglobal} ) ) {
      if ( $packofglobal ) {
	warm( "the global element \$$global was declared in the packages " .
	      "$packofglobal and $pack. The second declaration was ignored.",
	      extract_file_from_location($location),
	      extract_line_from_location($location)
	    ) ;
      }
      else {
	$packofglobal = $pack ;
	if ( ( exists $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kglobal} ) ) {
	  $page = "package-constants" ;
	  $anchor = $kglobal ;
	  if ( ! $comment ) {
	    $comment = $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kglobal}{'name'} ;
	  }
	}
	elsif ( exists $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kglobal} ) {
	  $page = "package-variables" ;
	  $anchor = $kglobal ;
	  if ( ! $comment ) {
	    $comment = $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kglobal}{'name'} ;
	  }
	}
	else {
	  $page = "package-functions" ;
	  $anchor = $kfglobal ;
	  if ( ! $comment ) {
	    $comment = $self->{'CONTENT'}{'packages'}{$kpack}{'functions'}{$kfglobal}{'name'} ; ;
	  }
	}
      }
    }
  }
  if ( ! $packofglobal ) {
    if ( ! $comment ) {
      $comment = "$global" ;
    }
    return PhpDocGen::General::Error::invalidlink( $global,
						   $comment,
						   "unable to find the definition ".
						   "of the global element $global.",
						   1,
						   $location ) ;
  }
  else {
    return $self->format_ext_hyperref( $rootdir,
    	   			       $packofglobal,
				       $page,
				       $anchor,
				       $comment ) ;
  }
}

=pod

=item * get_hyperref_classmember()

Replies a hyper-refernece that corresponds to the
specified class member.
Takes 4 args:

=over

=item * name (string)

is the name of the class member.

=item * root (string)

is the root directory of the documentation.

=item * comment (string)

is the comment attached to the returned reference.

=item * location (string)

is the location of the link inside the input stream.

=back

=cut
sub get_hyperref_classmember($$$$)  {
  my $self = shift ;
  my $location = $_[3] ;
  my $rootdir = $_[1] || confess( "the rootdir must be supplied" ) ;
  my $comment = $_[2] ;
  my ( $class, $member ) = split( /\:\:/, $_[0] ) ;
  my $errormsg = "" ;
  if ( $self->is_class( $class ) ) {
    # Is it the constructor ?
    my $kclass = formathashkeyname( $class ) ;
    $class = $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'name'} ;
    my $cons = formathashkeyname(removefctbraces($member)) ;
    if ( $kclass eq $cons ) {
      if ( ! $comment ) {
	$comment = $class."::".addfctbraces($class) ;
      }
      if ( $self->{'CONTENT'}{'classes'}{$kclass}{'constructor'} ) {
	my $kpack = formathashkeyname( $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'package'} ) ;
	my $pack = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
	return $self->format_ext_hyperref( $rootdir,
	       			       	   $pack,
				       	   $class,
				       	   formatfctkeyname($cons),
				       	   $comment ) ;
      }
      else {
	return PhpDocGen::General::Error::invalidlink( $class."::$cons",
	       				    $comment,
			    		    "the constructor of ".
					    "$class was not found.",
			    		    0, $location ) ;
      }
    }
    # Not the constructor
    my $kmember = formatvarkeyname( $member ) ;
    my $kfmember = formatfctkeyname( $member ) ;
    # Gets the ancestors for the class
    my @classes = $self->get_class_ancestors( $class ) ;
    push( @classes, $kclass ) ;
    # Try to found the member is the class hierarchy
    foreach my $kclass (reverse @classes) {
      if ( exists $self->{'CONTENT'}{'classes'}{$kclass} ) {
	my $class = $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'name'} ;
	if ( exists $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kmember} ) {
	  my $mname = $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kmember}{'name'} ;
	  if ( ! $comment ) {
	    $comment = $class."::$mname" ;
	  }
	  my $kpack = formathashkeyname( $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'package'} ) ;
	  my $pack = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
	  return $self->format_ext_hyperref( $rootdir,
	  	 			     $pack,
					     $class,
					     $kmember,
					     $comment ) ;
	}
	elsif ( exists $self->{'CONTENT'}{'classes'}{$kclass}{'methods'}{$kfmember} ) {
	  my $mname = $self->{'CONTENT'}{'classes'}{$kclass}{'methods'}{$kfmember}{'name'} ;
	  if ( ! $comment ) {
	    $comment = $class."::$mname" ;
	  }
	  my $kpack = formathashkeyname( $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'package'} ) ;
	  my $pack = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
	  return $self->format_ext_hyperref( $rootdir,
	  	 			     $pack,
					     $class,
					     $kfmember,
					     $comment ) ;
	}
      }
      else {
	warm( "unable to find the class $kclass.",
	      extract_file_from_location($location),
	      extract_line_from_location($location)
	    ) ;
      }
    }
    $errormsg = "$member is not a valid member of $class and of its ancestors." ;
  }
  else {
    $errormsg = "unable to find the class in $_[0].\n" ;
  }
  if ( ! $comment ) {
    $comment = $_[0] ;
  }
  return $self->invalidlink( $class."::$member", 
  	 		     $comment, 
			     $errormsg, 0, $location ) ;
}

=pod

=item * get_hyperref()

Replies a hyper-refernece that corresponds to the
specified element.
Takes 4 args:

=over

=item * name (string)

is the name of the element.

=item * root (string)

is the root directory of the documentation.

=item * comment (string)

is the comment attached to the returned reference.

=item * location (string)

is the location of the link inside the input stream.

=back

=cut
sub get_hyperref($$$$)  {
  my $self = shift ;
  my $location = $_[3] ;
  my $object = $_[0] ;
  my $comment = $_[2] ;
  if ( ( $object =~ /^http\:/i ) ||
       ( $object =~ /^ftp\:/i ) ||
       ( $object =~ /^file\:/i ) ) {
    if ( ! $comment ) {
      $comment = $object ;
    }
    return $self->format_hyperref( $object, $comment ) ;
  }
  elsif ( $self->is_classmember_name( $object ) ) {
    return $self->get_hyperref_classmember( $object, 
    	   				    $_[1], 
					    $comment, 
					    $location ) ;
  }
  elsif ( $self->is_class( $object ) ) {
    return $self->get_hyperref_class( $object, 
    	   			      $_[1], 
				      $comment, 
				      $location ) ;
  }
  elsif ( $self->is_globalelement( $object ) ) {
    return $self->get_hyperref_globalelement( $object, 
    	   				      $_[1], 
					      $comment, 
					      $location ) ;
  }
  elsif ( $self->is_webmodule( $object ) ) {
    return $self->get_hyperref_webmodule( $object,
					  $_[1],
					  $comment,
					  $location ) ;
  }
  elsif ( $self->is_webpage( $object ) ) {
    return $self->get_hyperref_webpage( $object,
					$_[1],
					$comment,
					$location ) ;
  }
  else {
    if ( ! $comment ) {
      $comment = $object ;
    }
    return PhpDocGen::General::Error::invalidlink( $object, $comment,
			       		"unable to find the ".
					"definition of $object.",
			       		1, $location ) ;
  }
}

=pod

=item * get_all_notempty_webmodules()

Replies all the webmodules which are not empty.

=cut
sub get_all_notempty_webmodules {
  my $self = shift ;
  my %allmods = () ;
  my $current = $_[0] || \%{$self->{'CONTENT'}{'webmodules'}} ;
  my $path = $_[1] || '' ;
  foreach my $mod (keys %{$current}) {
    my $realname ;
    if ( $mod eq "/" ) {
      $realname = $mod ;
    }
    else {
      $realname = htmlcanonpath(htmlcatfile($path,$mod)) ;
    }
    if ( exists $current->{$mod}{'this'} ) {
      %{$allmods{$realname}} = %{$current->{$mod}{'this'}} ;
      @{$allmods{$realname}{'submodules'}} = () ;
      @{$allmods{$realname}{'pages'}} = () ;
    }
    if ( exists $current->{$mod}{'submodules'} ) {
      my %submods = $self->get_all_notempty_webmodules($current->{$mod}{'submodules'},
						       $realname) ;
      foreach my $sub (keys %submods) {
	$allmods{$sub} = $submods{$sub} ;
	if ( exists $current->{$mod}{'this'} ) {
	  push @{$allmods{$realname}{'submodules'}}, $sub ;
	}
      }
    }
    if ( ( exists $current->{$mod}{'pages'} ) &&
	 ( exists $current->{$mod}{'this'} ) ) {
      foreach my $page ( keys %{$current->{$mod}{'pages'}} ) {
	push @{$allmods{$realname}{'pages'}}, $page ;
      }
    }
  }
  return %allmods ;
}

=pod

=item * get_all_webpages()

Replies all the webpages.

=cut
sub get_all_webpages {
  my $self = shift ;
  my %allpages = () ;
  my $current = $_[0] ;
  $current = \%{$self->{'CONTENT'}{'webmodules'}} unless $current ;
  my $path = $_[1] ;
  $path = "" unless $path ;
  foreach my $mod (keys %{$current}) {
    my $realname ;
    if ( $mod eq "/" ) {
      $realname = $mod ;
    }
    else {
      $realname = htmlcanonpath(htmlcatfile($path,$mod)) ;
    }
    if ( exists $current->{$mod}{'pages'} ) {
      foreach my $page (keys %{$current->{$mod}{'pages'}}) {
	%{$allpages{htmlcanonpath(htmlcatfile($realname,$page))}} = %{$current->{$mod}{'pages'}{$page}} ;
      }
    }
    if ( exists $current->{$mod}{'submodules'} ) {
      my %submods = $self->get_all_webpages($current->{$mod}{'submodules'},
					    $realname) ;
      foreach my $sub (keys %submods) {
	$allpages{$sub} = $submods{$sub} ;
      }
    }
  }
  return %allpages ;
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

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

PhpDocGen::Generator::Html::Html - A HTML generator

=head1 SYNOPSYS

use PhpDocGen::Generator::Html::Html ;

my $gen = PhpDocGen::Generator::Html::Html->new(
                      documentation_content,
                      long_title,
                      short_title,
                      output_path,
                      theme_name,
                      lang,
                      php_definition ) ;

=head1 DESCRIPTION

PhpDocGen::Generator::Html::Html is a Perl module, which proposes
a documentation generator for HTML pages.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use PhpDocGen::Generator::Html::Html;

    my $gen = PhpDocGen::Generator::Html::Html->new(
                $content,
		"This is the documentation",
		"Documentation",
		"/tmp/phpdoc/",
                { 'version' => "0.5.2",
                  'date' => "2002-08-12",
                  'author' => "Somebody",
                  'email' => "somebody@somewhere",
                  'url' => "http://somewhere/",
                  'bug' => "http://somewhere/",
                },
                { 'sources' => 0,
                  'php' => 1,
		  'web' => 0,
		},
		"JavaDoc",
                "english",
                "/usr/lib/phpdocgen" ) ;

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

=item * phpdef (hash ref)

An hashtable that contains the description of
the phpdocgen script.

=item * generation_behavior (hash)

Indicates what kind of generation must be do. Each key corresponds to
a boolean value :

=over

=item I<sources> generation of the highligthed source files

=item I<php> generation of the documentation about the PHP functions, classes...

=item I<web> generation of the documentation about the web modules and web pages

=back

=item * theme (string)

is the name of the theme to use

=item * lang (string)

is the name of the language to use

=item * PHPdir (string)

this is the absolute path to the directory where the root of the
modules is

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Html.pm itself.

=over

=cut

package PhpDocGen::Generator::Html::Html;

@ISA = ('PhpDocGen::Generator::Generator');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;

use Carp ;
use File::Copy ;
use File::Basename ;
use File::Spec ;

use PhpDocGen::General::Token ;
use PhpDocGen::Generator::Generator ;
use PhpDocGen::General::Verbose ;
use PhpDocGen::General::Misc ;
use PhpDocGen::General::HTML ;
use PhpDocGen::General::Error ;
use PhpDocGen::Highlight::PHP ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of HTML generator
my $VERSION = "0.11" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$$$$$$$$)  {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = $class->SUPER::new($_[0],$_[1],$_[2],$_[3],$_[7]) ;

  # PHPDOCGEN infos
  $self->{'PHPDOCGEN'}{'VERSION'} = $_[4]{'version'} ;
  $self->{'PHPDOCGEN'}{'DATE'} = $_[4]{'date'} ;
  $self->{'PHPDOCGEN'}{'AUTHOR'} = $_[4]{'author'} ;
  $self->{'PHPDOCGEN'}{'AUTHOR_EMAIL'} = $_[4]{'email'} ;
  $self->{'PHPDOCGEN'}{'URL'} = $_[4]{'url'} ;
  $self->{'PHPDOCGEN'}{'BUG_URL'} = $_[4]{'bug'} ;
  # Directories
  $self->{'WEBDOC_DIR'} = 'webdoc' ;
  $self->{'WEBTARGET'} = htmlcatdir($self->{'TARGET'},$self->{'WEBDOC_DIR'}) ;
  # Generation behaviour
  $self->{'GENERATE_PHP_DOC'} = $_[5]{'php'} ;
  $self->{'GENERATE_WEB_DOC'} = $_[5]{'web'} ;
  $self->{'SHOWSOURCES'} = ( $_[5]{'sources'} && $self->{'GENERATE_PHP_DOC'} ) ;
  if ( ( ! $self->{'GENERATE_PHP_DOC'} ) &&
       ( ! $self->{'GENERATE_WEB_DOC'} ) ) {
    PhpDocGen::General::Error::syserr( "We don't want to generate the PHP documentation ".
				       "nor the web documentation." ) ;
  }
  $self->{'SOURCEFILENAMES'} = () ;
  # Theme management
  my $themename = $_[6] || 'JavaDoc' ;
  if ( ( $themename ) &&
       ( $themename !~ /::/ ) ) {
    $themename = "PhpDocGen::Generator::Html::Theme::".$themename."Theme" ;
  }
  eval "require ".$themename.";" ;
  if ( $@ ) {
    PhpDocGen::General::Error::syserr( "Unable to load the HTML theme $themename:\n$@" ) ;
  }
  $self->{'THEME'} = ($themename)->new( $self->{'PHPDOCGEN'},
					$self->{'TARGET'},
					$self->{'SHORT_TITLE'},
					$self->{'GENERATE_PHP_DOC'},
					$self->{'GENERATE_WEB_DOC'},
					$self->{'LANG'} ) ;
  # Computes the directory where this class is
  if ( $_[8] ) {
    my @pack = split /\:\:/, __PACKAGE__ ;
    pop @pack ;
    $self->{'PERLSCRIPTDIR'} = File::Spec->canonpath( $_[8] ) ;
    $self->{'PERLSCRIPTDIR'} = File::Spec->catdir( $self->{'PERLSCRIPTDIR'}, @pack ) ;
  }
  else {
    $self->{'PERLSCRIPTDIR'} = "" ;
  }
  # Includes the source highlighter
  if ( $self->{'SHOWSOURCES'} ) {
    eval "require PhpDocGen::Highlight::PHP ;" ;
  }

  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Sorted lists
#
#------------------------------------------------------

=pod

=item * create_sorted_lists()

Creates the sorted lists of classes and packages.

=cut
sub create_sorted_lists()  {
  my $self = shift ;
  @{$self->{'SORTED_LISTS'}{'packages'}} = sort keys %{$self->{'CONTENT'}{'packages'}} ;
  @{$self->{'SORTED_LISTS'}{'classes'}} = sort keys %{$self->{'CONTENT'}{'classes'}} ;
  my %allmods = $self->get_all_notempty_webmodules() ;
  @{$self->{'SORTED_LISTS'}{'modules'}} = sort keys %allmods ;
  my %allpages = $self->get_all_webpages() ;
  @{$self->{'SORTED_LISTS'}{'pages'}} = sort keys %allpages ;
}

#------------------------------------------------------
#
# HTML helpers
#
#------------------------------------------------------

=pod

=item * get_translator_copyright()

Replies a string that represents the copyright of this translator.

=over

=item * rootdir (string)

is the path to the root directory

=back

=cut
sub get_translator_copyright($)  {
  my $self = shift ;
  my $rootdir = $_[0] ;
  my $valid = "" ;
  if ( $rootdir ) {
    $valid = $self->{'THEME'}->get_html_validation_link($rootdir) ;
  }
  return join( '',
	       $self->{'THEME'}->par( $self->{'THEME'}->small(
				      $self->{'THEME'}->href( $self->{'PHPDOCGEN'}{'BUG_URL'},
							      $self->{'LANG'}->get( 'I18N_LANG_SUBMIT_BUG'), "_top" ) ) ),
	       $self->{'THEME'}->par( $self->{'THEME'}->small(
				      $self->{'LANG'}->get( 'I18N_LANG_PHPDOCGEN_COPYRIGHT',
							    $self->{'THEME'}->href( $self->{'PHPDOCGEN'}{'URL'},
										    "phpdocgen " .
										    $self->{'PHPDOCGEN'}{'VERSION'},
										    "_top" ),
							    $self->{'THEME'}->href( "mailto:".$self->{'PHPDOCGEN'}{'AUTHOR_EMAIL'},
										    $self->{'PHPDOCGEN'}{'AUTHOR'} ),
							    $self->{'THEME'}->href( "http://www.gnu.org/copyleft/gpl.html",
										    "GNU General Public License",
										    "_top" ) ) ) ),
	       $valid
	     ) ;
}


sub __add_class_link_to_tree__($$) {
  my $self = shift ;
  my $tree = {} ;
  foreach my $key (keys %{$_[0]}) {
    my $subtree = $self->__add_class_link_to_tree__($_[0]->{$key},$_[1]) ;
    my $link = $self->get_hyperref_class( $key,
					  $_[1],
					  "",
					  "" ) ;
    $tree->{$link} = $subtree ;
  }
  return $tree ;
}

=pod

=item * build_a_class_tree()

Replies a HTML list that represents the
specified class hierarchy.
Takes 2 args:

=over

=item * hash (hash ref)

is the hierarchy

=item * root (string)

is the root directory of the generated document.

=item * tree_name (optional string)

=back

=cut
sub build_a_class_tree($$)  {
  my $self = shift ;
  my $rootdir = $_[1] || confess( "the rootdir must be supplied" ) ;
  my $content = "" ;
  my $themefct = $self->{'THEME'}->can('get_tree') ;
  if ( ! isemptyhash( $_[0] ) ) {

    if ( $themefct ) {

      return $self->{'THEME'}->get_tree( $self->__add_class_link_to_tree__($_[0],$rootdir),
					 $rootdir) ;

    }
    else {
      foreach my $class ( sort keys %{$_[0]} ) {
	my $node = $self->get_hyperref_class( $class,
					      $rootdir,
					      "",
					      "" ) ;
	my $subtree = $self->build_a_class_tree( $_[0]{$class},
						 $rootdir,
						 $node ) ;
	if ( $subtree ) {
	  $node = $self->{'THEME'}->get_tree_node( $node, $subtree, $rootdir ) ;
	}
	else {
	  $node = $self->{'THEME'}->get_tree_leaf( $node, $rootdir ) ;
	}
	$content .= $node ;
      }
    }
  }
  if ( ( ! $themefct ) && ( ! $_[2] ) ) {
    $content = $self->{'THEME'}->get_tree_node( '', $content, $rootdir ) ;
  }
  return $content ;
}

=pod

=item * build_a_web_tree()

Replies a HTML list that represents the
specified web hierarchy.
Takes 2 args:

=over

=item * hash (hash ref)

is the hierarchy

=item * root (string)

is the root directory of the generated document.

=back

=cut
sub build_a_web_tree($$)  {
  my $self = shift ;
  my $rootdir = $_[1] || confess( "the rootdir must be supplied" ) ;
  my $content = "" ;
  my $path = $_[2] ? $_[2] : "" ;
  if ( ! isemptyhash( $_[0] ) ) {
    foreach my $elt ( sort keys %{$_[0]} ) {
      my $name = htmlcatfile($path,$elt) ;
      my $node = $self->get_hyperref_webelement( "web:$name",
						 $rootdir,
						 $elt,
						 "" ) ;
      my $subtree = $self->build_a_web_tree( $_[0]{$elt},
					     $rootdir,
					     $name,
					     $node ) ;
      if ( $subtree ) {
	$node = $self->{'THEME'}->get_tree_node( $node, $subtree, $rootdir ) ;
      }
      else {
	$node = $self->{'THEME'}->get_tree_leaf( $node, $rootdir ) ;
      }
      $content .= $node ;
    }
  }
  if ( ! $_[3] ) {
    $content = $self->{'THEME'}->get_tree_node( '', $content, $rootdir ) ;
  }
  return $content ;
}

=pod

=item * build_function_summary()

Replies the summary for a function.
Takes 3 args:

=over

=item * name (string)

is the name of the function.

=item * description (hash ref)

is the description of the function.

=item * root (string)

is the root directory of the generated documentation.

=item * currentfile (string)

is the current filename of the generated documentation.

=item * outdir (string)

is the directory where the file must be put

=back

=cut
sub build_function_summary($$$$)  {
  my $self = shift ;
  my $kname = formatfctkeyname( $_[0] ) ;
  my $rootdir = $_[2] || confess( "the rootdir must be supplied" ) ;
  my $currentfile = $_[3] || confess( "the current filename must be supplied" ) ;
  my $outdir = $_[4] ;

  my %hash = (
	      'type' => "",
	      'name' => "",
	      'explanation' => "",
	     ) ;

  if ( $_[1]{'static'} ) {
     $hash{type} = $self->{'THEME'}->keyword($self->{'LANG'}->get('I18N_LANG_STATIC'))." " ;
  }
  if ( $_[1]{'private'} ) {
    $hash{type} .= $self->{'THEME'}->keyword($self->{'LANG'}->get('I18N_LANG_PRIVATE'))." " ;
  }
  elsif ( $_[1]{'protected'} ) {
    $hash{type} .= $self->{'THEME'}->keyword($self->{'LANG'}->get('I18N_LANG_PROTECTED'))." " ;
  }
  if ( exists $_[1]{'return'} ) {
    $hash{type} .= $self->{'THEME'}->keyword($_[1]{'return'}{'type'}) ;
    if ( $_[1]{'return'}{'byref'} ) {
      $hash{type} .= '&amp;' ;
    }
    $hash{type} .= " " ;
  }
  else {
    $hash{type} .= $self->{'THEME'}->keyword($self->{'LANG'}->get('I18N_LANG_VOID'))." " ;
  }
  $hash{name} = $self->{'THEME'}->strong( $self->{'THEME'}->href( "#$kname",
								  $_[1]{'name'} ) ) .
								    "(" ;
  if ( exists $_[1]{'parameters'} ) {
    $hash{name} .= $self->format_parameters( $_[1]{'parameters'} ) ;
  }
  $hash{name} .= ")" ;
  $hash{explanation} = $self->briefcomment( $_[1], $rootdir ) ;
  $self->addsourcelink( $hash{'explanation'}, $rootdir, $currentfile, $_[1]{'location'} ) ;
  return %hash ;
}

=pod

=item * format_parameters()

Replies a string that is the formated version of the parameters
Takes 1 args:

=over

=item * params (array)

is the set of parameters.

=back

=cut
sub format_parameters($)  {
  my $self = shift ;
  my $params = "" ;
  for( my $i=0; $i<=$#{$_[0]}; $i++ ) {
    my $str = "" ;
    if ( $i > 0 ) {
      $str = ", " ;
    }
    my $s ;
    if ( $_[0][$i]{'varparam'} ) {
      $s = "<strong>...</strong>" ;
    }
    else {
      $s = $_[0][$i]{'type'} ;
      if ( $_[0][$i]{'byref'} ) {
        $s = "$s&amp;" ;
      }
      $s = join( '', $s , " ",
		 formatvarname($_[0][$i]{'name'}) ) ;
      if ( $_[0][$i]{'optional'} ) {
        $s = "[$s]" ;
      }
    }
    $params .= "$str$s" ;
  }
  return $params ;
}

=pod

=item * build_function_detail()

Replies the detail for a function.
Takes 3 args:

=over

=item * name (string)

is the name of the function.

=item * description (hash ref)

is the description of the function.

=item * root (string)

is the root directory of the generated documentation.

=item * currentfile (string)

is the currentfile of the generated documentation.

=item * outdir (string)

is the directory where the generated documentation must be put

=back

=cut
sub build_function_detail($$$$)  {
  my $self = shift ;
  my $name = $_[1]{'name'} ;
  my $kname = formatfctkeyname($_[0]) ;
  my $rootdir = $_[2] || confess( "the rootdir must be supplied" ) ;
  my $currentfile = $_[3] || confess( "the currentfile must be supplied" ) ;
  my $outdir = $_[4] ;


  # Build the signature
  my $signature = '' ;
  if ( $_[1]{'static'} ) {
    $signature .= $self->{'THEME'}->keyword($self->{'LANG'}->get('I18N_LANG_STATIC'))." " ;
  }
  if ( $_[1]{'private'} ) {
    $signature .= $self->{'THEME'}->keyword($self->{'LANG'}->get('I18N_LANG_PRIVATE'))." " ;
  }
  elsif ( $_[1]{'protected'} ) {
    $signature .= $self->{'THEME'}->keyword($self->{'LANG'}->get('I18N_LANG_PROTECTED'))." " ;
  }
  if ( exists $_[1]{'return'} ) {
    $signature .= $_[1]{'return'}{'type'} ;
    if ( $_[1]{'return'}{'byref'} ) {
      $signature .= "&amp;" ;
    }
    $signature .= " " ;
  }
  else {
    $signature .= $self->{'THEME'}->keyword($self->{'LANG'}->get('I18N_LANG_VOID'))." " ;
  }
  $signature .= $self->{'THEME'}->strong( $name )."(" ;
  if ( exists $_[1]{'parameters'} ) {
    $signature .= $self->format_parameters( $_[1]{'parameters'} ) ;
  }
  $signature .= ")" ;


  # Adds the detail parts
  my $detailparts = '' ;
  if ( exists $_[1]{'parameters'} ) {
    my @acontent = () ;
    for( my $i=0; $i<=$#{$_[1]{'parameters'}}; $i++ ) {
      if ( ( ! $_[1]{'parameters'}[$i]{'varparam'} ) ||
	   ( $_[1]{'parameters'}[$i]{'explanation'} ) ) {
	push( @acontent, join( '',
			       $self->{'THEME'}->code($_[1]{'parameters'}[$i]{'name'})." - ",
			       $self->expand( $_[1]{'parameters'}[$i]{'explanation'},
					      $rootdir,
					      $_[1]{'parameters'}[$i]{'location'} )
			     ) ) ;
      }
    }
    $detailparts .= $self->{'THEME'}->build_detail_part( $self->{'LANG'}->get('I18N_LANG_PARAMETERS'),
							 "<BR>\n", \@acontent ) ;
  }

  if ( exists $_[1]{'return'} ) {
    my @acontent = ( $self->expand( $_[1]{'return'}{'comment'},
       		     		    $rootdir,
				    $_[1]{'return'}{'location'} ) ) ;
    $detailparts .= $self->{'THEME'}->build_detail_part( $self->{'LANG'}->get('I18N_LANG_RETURNS'),
							 ", ", \@acontent ) ;
  }

  if ( exists $_[1]{'uses'} ) {
    my @acontent = () ;
    foreach my $u (sort @{$_[1]{'uses'}}) {
      push( @acontent, $self->get_hyperref( $u->{'name'},
      	    	       			    $rootdir,
					    "",
				 	    $u->{'location'} ) ) ;
    }
    $detailparts .= $self->{'THEME'}->build_detail_part( $self->{'LANG'}->get('I18N_LANG_GLOBAL_VARS'),
							 ', ',
							 \@acontent ) ;
  }
  $detailparts .= $self->build_common_tag_parts($_[1],$rootdir) ;

  # Generates the detailed part
  my $explanation = $_[1]{'explanation'}{'text'} ;
  $self->addsourcelink( $explanation, $rootdir, $currentfile, $_[1]{'location'} ) ;

  return $self->{'THEME'}->build_function_detail( $kname,
						  addfctbraces($name),
						  $signature,
						  $self->expand( $explanation,
								 $rootdir,
								 $_[1]{'explanation'}{'location'} ),
						  $detailparts ) ;
}


=pod

=item * build_common_tag_parts()

Replies the common tag HTML code.
Takes 2 args:

=over

=item * hash (hash ref)

is the content of the documented object.

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub build_common_tag_parts($$)  {
  my $self = shift ;
  my $content = "" ;
  # Generates the tags which must appear
  # inside sections
  my @k = keys %COMMON_SECTIONED_TAGS ;
  @k = sort {
    if ( $COMMON_SECTIONED_TAGS{$a}{'order'} < $COMMON_SECTIONED_TAGS{$b}{'order'} ) {
      return -1 ;
    }
    elsif ( $COMMON_SECTIONED_TAGS{$a}{'order'} > $COMMON_SECTIONED_TAGS{$b}{'order'} ) {
      return 1 ;
    }
    else {
      return 0 ;
    }
  } @k ;
  foreach my $t (@k) {
    if ( exists $_[0]{$t} ) {

      my @acontent = () ;
      if ( isarray( $_[0]{$t} ) ) {
	push( @acontent, @{$_[0]{$t}} ) ;
      }
      else {
	if ( $_[0]{$t}{'text'} ) {
	  push( @acontent, \%{$_[0]{$t}} ) ;
	}
      }
      # Be sure that the comments are translated
      for( my $i=0; $i<=$#acontent; $i++ ) {
	$acontent[$i] = $self->expand( $acontent[$i]{'text'},
				       $_[1],
				       $acontent[$i]{'location'} ) ;
      }
      $content .= $self->{'THEME'}->build_detail_part( $self->{'LANG'}->get($COMMON_SECTIONED_TAGS{$t}{'label'}),
						       $COMMON_SECTIONED_TAGS{$t}{'separator'},
						       \@acontent ) ;
    }
  }
  # Generates the changelogs
  if ( exists $_[0]{'logs'} ) {
    my @arraycnt = () ;
    foreach my $log (@{$_[0]{'logs'}}) {
      my $text = $self->expand( $log->{'text'},
				$_[1],
				$log->{'location'} ) ;
      push( @arraycnt, join( '&nbsp;',
			     $self->{'THEME'}->strong($log->{'date'}),
			     $text ) ) ;
    }
    $content .= $self->{'THEME'}->build_tiny_array( $self->{'LANG'}->get('I18N_LANG_CHANGELOGS'), \@arraycnt ) ;
  }
  # Generates the bugs
  if ( exists $_[0]{'bugs'} ) {
    my @arraycnt = () ;
    foreach my $bug (@{$_[0]{'bugs'}}) {
      my $text = $self->expand( $bug->{'text'},
				$_[1],
				$bug->{'location'} ) ;
      if ( $bug->{'fixed'} ) {
	$text = $self->{'THEME'}->format_fixed_bug($text) ;
      }
      push( @arraycnt, $text ) ;
    }
    $content .= $self->{'THEME'}->build_tiny_array( $self->{'LANG'}->get('I18N_LANG_BUGS'), \@arraycnt ) ;
  }
  return $content ;
}

=pod

=item * build_inheritance_tree()

Creates the documentation for the specified class.
Takes 2 args:

=over

=item * class (string)

is the name of the class.

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub build_inheritance_tree($$)  {
  my $self = shift ;
  my $kclass = formathashkeyname( $_[0] ) ;
  my $rootdir = $_[1] || confess( "the rootdir must be supplied" ) ;
  my @tree = $self->get_class_ancestors($kclass) ;
  if ( $#tree >= 0 ) {
    push( @tree, $kclass ) ;
    for(my $i=0; $i<=$#tree; $i++ ) {
      $tree[$i] = $self->get_hyperref_class( $tree[$i],
					     $rootdir,
					     "",
					     "" );
    }
  }
  return $self->{'THEME'}->build_linked_tree( \@tree, $rootdir ) ;
}


=pod

=item * get_children_list()

Output the children of the specified class.
Takes 2 args:

=over

=item * class (string)

is the name of the class.

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub get_children_list($$)  {
  my $self = shift ;
  my $kclass = formathashkeyname( $_[0] ) ;
  my $rootdir = $_[1] || confess( "the rootdir must be supplied" ) ;
  my $content = "" ;
  my @tree = $self->get_class_children( $kclass ) ;
  if ( $#tree >= 0 ) {
    for(my $i=0; $i<=$#tree; $i++) {
      $tree[$i] = $self->{'THEME'}->code( $self->get_hyperref_class( $tree[$i],
								     $rootdir,
								     "", "") ) ;
    }
    $content = $self->{'THEME'}->build_detail_part( $self->{'LANG'}->get('I18N_LANG_DIRECT_SUBCLASSES'),
						    ", ", \@tree ) ;
  }
  return $content ;
}


=pod

=item * build_inherited_methods()

Replies the HTML arrays that list the <inherited methods.
Takes 2 args:

=over

=item * class (string)

is the name of the class.

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub build_inherited_methods($$)  {
  my $self = shift ;
  my $kclass = formathashkeyname( $_[0] ) ;
  my $rootdir = $_[1] || confess( "the rootdir must be supplied" ) ;

  my $content = "" ;

  # Saves the methods of the current class
  my @functions ;
  if ( exists $self->{'CONTENT'}{'classes'}{$kclass}{'methods'} ) {
    @functions = keys %{$self->{'CONTENT'}{'classes'}{$kclass}{'methods'}} ;
  }
  else {
    @functions = () ;
  }

  foreach my $ancestor ( reverse ($self->get_class_ancestors( $kclass )) ) {
    $ancestor = formathashkeyname( $ancestor ) ;
    my $list = "" ;
    # Builds the list
    if ( ( exists $self->{'CONTENT'}{'classes'}{$ancestor} ) &&
	 ( exists $self->{'CONTENT'}{'classes'}{$ancestor}{'methods'} ) ) {
      foreach my $meth (sort keys %{$self->{'CONTENT'}{'classes'}{$ancestor}{'methods'}}) {
	$meth = formatfctkeyname( $meth ) ;
	my $mname = $self->{'CONTENT'}{'classes'}{$ancestor}{'methods'}{$meth}{'name'} ;
	if ( ! strinarray( $meth, \@functions ) ) {
	  push( @functions, $meth ) ;
	  if ( $list ) {
	    $list .= ", " ;
	  }
	  $list .= $self->{'THEME'}->code( $self->get_hyperref_classmember( $ancestor."::$mname",
									    $rootdir,
									    $mname,
									    "" ) ) ;
	}
      }
    }
    # Display the list
    if ( $list ) {
      $content .= $self->{'THEME'}->build_small_array( $self->{'LANG'}->get('I18N_LANG_INHERITED_METHODS',
									    $self->get_hyperref_class($ancestor,$rootdir,"","")),
						       [ $list ] ) ;
    }
  }

  return $content ;
}

#------------------------------------------------------
#
# Generation of the document
#
#------------------------------------------------------

=pod

=item * output_file_index()

Outputs the general index.

=cut
sub output_file_index()  {
  my $self = shift ;
  my $rootdir = "." ;
  $self->{'THEME'}->create_html_page( $self->{'THEME'}->filename('main'),
				      $self->{'THEME'}->get_html_index($rootdir),
				      $self->{'SHORT_TITLE'},
				      $rootdir,
				      1 ) ;
}

=pod

=item * output_file_overview_frame()

Outputs the general overview frame.

=cut
sub output_file_overview_frame()  {
  my $self = shift ;
  my $rootdir = "." ;
  my $content =  $self->{'THEME'}->ext_href( 'all-elements',
					     $self->{'LANG'}->get('I18N_LANG_ALL_ELEMENTS'),
					     "." ) ;

  # Generate the PHP documentation
  if ( $self->{'GENERATE_PHP_DOC'} ) {
    my @scontent = () ;
    foreach my $kpack ( @{$self->{'SORTED_LISTS'}{'packages'}} ) {
      my $href = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
      push @scontent, $self->{'THEME'}->href( htmlcatfile($href,
							  $self->{'THEME'}->filename('package-frame')),
					      $href,
					      $self->{'THEME'}->browserframe('package-frame') ) ;
    }
    if ( @scontent ) {
      $content .= $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_PACKAGES'),
						   \@scontent,
						   $rootdir ) ;
    }
  }

  # Generate the WEB documentation
  if ( $self->{'GENERATE_WEB_DOC'} ) {
    my @scontent = () ;
    my $outdir = $self->{'WEBTARGET'} ;
    mkdir_rec($outdir) or
      PhpDocGen::General::Error::syserr( join( '',
					       "Unable to create the directory '",
					       $outdir,
					       "': ",
					       $! ) ) ;

    my %allmods = $self->get_all_notempty_webmodules() ;
    foreach my $mod ( @{$self->{'SORTED_LISTS'}{'modules'}} ) {
      push @scontent, $self->{'THEME'}->ext_href( 'module-frame',
						  $allmods{$mod}{'name'},
						  htmlcatdir($rootdir,
							     $self->{'WEBDOC_DIR'},
							     $allmods{$mod}{'url'} ) ),
    }
    if ( @scontent ) {
      $content .= $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_WEBMODULES'),
						   \@scontent,
						   $rootdir ) ;
    }
  }

  my $title ;
  if ( $self->{'GENERATE_PHP_DOC'} && $self->{'GENERATE_WEB_DOC'} ) {
    $title = $self->{'LANG'}->get('I18N_LANG_OVERVIEW_TITLE_PHP_WEB') ;
  }
  elsif ( $self->{'GENERATE_PHP_DOC'} ) {
    $title = $self->{'LANG'}->get('I18N_LANG_OVERVIEW_TITLE_PHP') ;
  }
  else {
    $title = $self->{'LANG'}->get('I18N_LANG_OVERVIEW_TITLE_WEB') ;
  }

  $content = $self->{'THEME'}->frame_window( $self->{'SHORT_TITLE'},
					     $content ) ;
  $self->{'THEME'}->create_html_body_page( $self->{'THEME'}->filename('overview-frame'),
					   $content,
					   $title,
					   $rootdir ) ;
}

=pod

=item * output_file_allelements_frame()

Outputs the all-element frame.

=cut
sub output_file_allelements_frame()  {
  my $self = shift ;
  my $content = "" ;
  my $rootdir = "." ;

  # Generates the PHP documentation
  if ( $self->{'GENERATE_PHP_DOC'} ) {
    if ( ! isemptyhash( $self->{'CONTENT'}{'classes'} ) ) {
      my @scontent = () ;
      foreach my $kclass ( @{$self->{'SORTED_LISTS'}{'classes'}} ) {
	my $classname = $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'name'} ;
	my $kpack = $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'package'} ;
	if ( exists $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ) {
	  my $href = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
	  push @scontent, $self->{'THEME'}->ext_href( 'class',
						      $classname,
						      $href,
						      $classname ) ;
	}
      }

      $content .= $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_ALL_CLASSES'),
						   \@scontent, $rootdir ) ;
    }

    my %hash = () ;
    foreach my $kpack ( @{$self->{'SORTED_LISTS'}{'packages'}} ) {
      foreach my $fct (keys %{$self->{'CONTENT'}{'packages'}{$kpack}{'functions'}}) {
	$hash{'functions'}{$fct} = $kpack ;
      }
      foreach my $cst (keys %{$self->{'CONTENT'}{'packages'}{$kpack}{'constants'}}) {
	$hash{'constants'}{$cst} = $kpack ;
      }
      foreach my $var (keys %{$self->{'CONTENT'}{'packages'}{$kpack}{'variables'}}) {
	$hash{'variables'}{$var} = $kpack ;
      }
    }

    if ( ! isemptyhash( $hash{'functions'} ) ) {
      my @scontent = () ;
      foreach my $fct ( sort keys(%{$hash{'functions'}}) ) {
	my $kpack = $hash{'functions'}{$fct} ;
	my $href = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
	my $fname = $self->{'CONTENT'}{'packages'}{$kpack}{'functions'}{$fct}{'name'} ;
	push @scontent, $self->{'THEME'}->href( htmlcatfile($href,
							    $self->{'THEME'}->filename('package-functions')).
						"#".addfctbraces( $fct ),
						removefctbraces( $fname ),
						$self->{'THEME'}->browserframe('package-functions') ) ;
      }

      $content .= $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_ALL_FUNCTIONS'),
						   \@scontent, $rootdir ) ;
    }

    if ( ! isemptyhash( $hash{'constants'} ) ) {
      my @scontent = () ;
      foreach my $cst ( sort keys(%{$hash{'constants'}}) ) {
	my $kpack = $hash{'constants'}{$cst} ;
	my $href = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
	my $cname = $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$cst}{'name'} ;
	push @scontent, $self->{'THEME'}->href( htmlcatfile($href,
							    $self->{'THEME'}->filename('package-constants')).
						"#".$cst,
						$cname,
						$self->{'THEME'}->browserframe('package-constants') ) ;
      }

      $content .= $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_ALL_CONSTANTS'),
						   \@scontent, $rootdir ) ;
    }

    if ( ! isemptyhash( $hash{'variables'} ) ) {
      my @scontent = () ;
      foreach my $var ( sort keys(%{$hash{'variables'}}) ) {
	my $kpack = $hash{'variables'}{$var} ;
	my $href = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
	my $vname = $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$var}{'name'} ;
	push @scontent, $self->{'THEME'}->href( htmlcatfile( $href,
							     $self->{'THEME'}->filename('package-variables')).
						"#".$var,
						$vname,
						$self->{'THEME'}->browserframe('package-variables') ) ;
      }

      $content .= $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_ALL_VARIABLES'),
						   \@scontent, $rootdir ) ;
    }
  } # if PHP documentation generation

  if ( $self->{'GENERATE_WEB_DOC'} ) {
    if ( ! isemptyhash( $self->{'CONTENT'}{'webmodules'} ) ) {
      my %allpages = $self->get_all_webpages() ;
      my @scontent = () ;
      foreach my $page ( @{$self->{'SORTED_LISTS'}{'pages'}} ) {
	if ( exists $allpages{$page}{'name'} ) {
	  push @scontent, $self->{'THEME'}->ext_href( 'webpage',
						      $allpages{$page}{name},
						      htmlcatdir( $rootdir,$self->{'WEBDOC_DIR'} ),
						      $allpages{$page}{'url'} ) ;
	}
      }

      $content .= $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_ALL_WEBPAGES'),
						   \@scontent, $rootdir ) ;
    }
  } # if WEB documentation generation

  $content = $self->{'THEME'}->frame_window( '', $content ) ;
  $self->{'THEME'}->create_html_body_page( $self->{'THEME'}->filename('all-elements'),
					   $content,
					   $self->{'LANG'}->get('I18N_LANG_ALL_ELEMENTS'),
					   $rootdir ) ;
}

=pod

=item * output_file_overview_summary()

Outputs the overview summary file.

=cut
sub output_file_overview_summary()  {
  my $self = shift ;
  my @phpcontent = () ;
  my @webcontent = () ;
  my $notree = 0 ;
  my $rootdir = "." ;
  my $firstelt = '' ;

  if ( $self->{'GENERATE_PHP_DOC'} ) {
    foreach my $kpack ( @{$self->{'SORTED_LISTS'}{'packages'}} ) {
      my $packname = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
      my $href = htmlcatfile($rootdir,$packname,
			     $self->{'THEME'}->filename('package')) ;
      $firstelt = $href unless $firstelt ;
      push( @phpcontent, $self->{'THEME'}->ext_wt_href( 'package',
							$packname,
							$packname ) ) ;
    }
    $notree = ( isemptyhash( $self->{'CONTENT'}{'classes'} ) ) ;
  }

  if ( $self->{'GENERATE_WEB_DOC'} ) {
    my %allmods = $self->get_all_notempty_webmodules() ;
    foreach my $mod ( @{$self->{'SORTED_LISTS'}{'modules'}} ) {
      my $comment = $self->briefcomment( $allmods{$mod},
					 $rootdir ) ;
      my $href = htmlcatdir($rootdir,
			    $self->{'WEBDOC_DIR'},
			    $allmods{$mod}{'url'}) ;
      $firstelt = htmlcatfile($href,
			      $self->{'THEME'}->filename('webmodule')) unless $firstelt ;
      push( @webcontent, { 'name' => $self->{'THEME'}->ext_wt_href( 'webmodule',
								    $allmods{$mod}{'name'},
								    $href ),
			   'explanation' => $comment,
			 } ) ;
    }
    $notree = ( $notree || ( isemptyhash( $self->{'CONTENT'}{'webmodules'} ) ) ) ;
  }

  my $nav = $self->{'THEME'}->get_navigation_bar( $self->{'THEME'}->filename('overview'),
						  { 'overview' => 1,
						    'notree' => $notree,
						    'index' => $self->{'HAS_INDEXES'},
						    'next' => $firstelt,
						  },
						  $rootdir ) ;

  my $content = join( '',
		      $nav,
		      $self->{'THEME'}->partseparator(),
		      $self->{'THEME'}->title($self->{'TITLE'}),
		      ( ( $self->{'GENERATE_PHP_DOC'} && @phpcontent ) ?
			$self->{'THEME'}->build_onecolumn_array( $self->{'LANG'}->get('I18N_LANG_PACKAGES'),
								 \@phpcontent )
			: '' ),
		      ( ( $self->{'GENERATE_WEB_DOC'} && @webcontent ) ?
			$self->{'THEME'}->build_twocolumn_array( $self->{'LANG'}->get('I18N_LANG_WEBMODULES'),
								 \@webcontent )
			: '' ),
		      $self->{'THEME'}->partseparator(),
		      $nav,
		      $self->{'THEME'}->partseparator(),
                      $self->get_translator_copyright($rootdir) ) ;

  $self->{'THEME'}->create_html_body_page( $self->{'THEME'}->filename('overview'),
					   $content,
					   $self->{'SHORT_TITLE'},
					   $rootdir ) ;
}

=pod

=item * output_file_overview_tree()

Outputs the overview class tree.

=cut
sub output_file_overview_tree()  {
  my $self = shift ;
  my $content = "" ;
  my $rootdir = "." ;

  my $title ;
  if ( $self->{'GENERATE_PHP_DOC'} && $self->{'GENERATE_WEB_DOC'} ) {
    $title = $self->{'LANG'}->get('I18N_LANG_OVERVIEWTREE_TITLE_PHP_WEB') ;
  }
  elsif ( $self->{'GENERATE_PHP_DOC'} ) {
    $title = $self->{'LANG'}->get('I18N_LANG_OVERVIEWTREE_TITLE_PHP') ;
  }
  else {
    $title = $self->{'LANG'}->get('I18N_LANG_OVERVIEWTREE_TITLE_WEB') ;
  }

  my $nav = $self->{'THEME'}->get_navigation_bar( $self->{'THEME'}->filename('tree'),
						  { 'tree' => 1,
						    'index' => $self->{'HAS_INDEXES'},
						  },
						  $rootdir ) ;

  # PHP documentation
  if ( ( $self->{'GENERATE_PHP_DOC'} ) &&
       ( ! isemptyhash( $self->{'CONTENT'}{'classes'} ) ) ) {

      PhpDocGen::General::Verbose::two("Generating the class hierarchy tree..\n") ;
      my @acontent = () ;

      $content .= $self->{'THEME'}->title( $title ) ;

      my @classes = @{$self->{'SORTED_LISTS'}{'classes'}} ;

      if ( $#classes >= 0 ) {

	my @acontent = () ;
	my %tree = () ;

	foreach my $kclass (@classes) {
	  if ( ! isemptyhash( $self->{'CONTENT'}{'classes'}{$kclass}{'this'} ) ) {
	    # Builds the list of classes
	    push( @acontent, $self->get_hyperref_class( $kclass,
							$rootdir,
							"",
							"" ) ) ;
	    # Builds the class hierarchy
	    my @ancestors = $self->get_class_ancestors( $kclass ) ;
	    buildtree( \%tree, \@ancestors, $kclass ) ;	
	  }
	  else {
	    warm( "the class $kclass was not defined.\n",
		  $self->{'THEME'}->filename('tree'), 0 ) ;
	  }
	}

	# Ouputs the list of classes
	$content .= $self->{'THEME'}->build_detail_part( $self->{'LANG'}->get('I18N_LANG_CLASS_LIST'),
							 ", ",
							 \@acontent ) ;

	# Generates the tree
	$content .= join( '',
			  $self->{'THEME'}->subtitle( $self->{'LANG'}->get('I18N_LANG_CLASS_HIERARCHY'),
						      1 ),
			  "<p>",
			  $self->build_a_class_tree( \%tree, $rootdir ),
			  "</p>" ) ;
      }
    } # If PHP documentation generation

  # WEB documentation
  if ( ( $self->{'GENERATE_WEB_DOC'} ) &&
       ( ! isemptyhash( $self->{'CONTENT'}{'webmodules'} ) ) ) {

      PhpDocGen::General::Verbose::two("Generating the webmodule hierarchy tree..\n") ;
      my @acontent = () ;
      my %tree = () ;

      $content .= $self->{'THEME'}->title( $self->{'LANG'}->get('I18N_LANG_WEB_HIERARCHY'),
					   1 ) ;

      my %allpages = $self->get_all_webpages() ;
      push( @acontent, $self->get_hyperref_webmodule( "/",
						      $rootdir,
						      "",
						      "" ) ) ;

      foreach my $page ( @{$self->{'SORTED_LISTS'}{'pages'}} ) {
	my @ancestors = htmlsplit( $allpages{$page}{'url'} ) ;
	pop @ancestors ;
	@ancestors = ( '/', @ancestors ) ;
	push( @acontent, $self->get_hyperref( "web:$page",
					      $rootdir,
					      "",
					      "" ) ) ;
	buildtree( \%tree, \@ancestors, htmlfilename($allpages{$page}{'name'}) ) ;	
      }

      # Ouputs the list of web elements
      $content .= $self->{'THEME'}->build_detail_part( $self->{'LANG'}->get('I18N_LANG_WEB_ELEMENT_LIST'),
						       ", ",
						       \@acontent ),

      # Generates the tree
      $content .= join( '',
			$self->{'THEME'}->subtitle( $self->{'LANG'}->get('I18N_LANG_WEB_ELEMENT_HIERARCHY'),
						    1 ),
			"<p>",
			$self->build_a_web_tree( \%tree, $rootdir ),
			"</p>" ) ;
    } # If WEB documentation generation

  if ( $content ) {
    $self->{'THEME'}->create_html_body_page( $self->{'THEME'}->filename('tree'),
					     join( '',
						   $nav,
						   $self->{'THEME'}->partseparator(),
						   $content,
						   $self->{'THEME'}->partseparator(),
						   $nav,
						   $self->{'THEME'}->partseparator(),
						   $self->get_translator_copyright($rootdir) ),
					     $title,
					     $rootdir ) ;
  }
}

=pod

=item * output_file_indexes()

Outputs the index files.

=cut
sub output_file_indexes()  {
  my $self = shift ;
  # Gets all the objects
  my %all = () ;
  my $rootdir = "." ;

  PhpDocGen::General::Verbose::two( "Generating the indexes..." ) ;

  if ( ( $self->{'GENERATE_PHP_DOC'} ) &&
       ( ! isemptyhash( $self->{'CONTENT'}{'classes'} ) ) ) {

    # Adds the classes
    foreach my $kclass ( @{$self->{'SORTED_LISTS'}{'classes'}} ) {

      PhpDocGen::General::Verbose::three( "\tincludes the class $kclass\n" ) ;

      my $classlink = $self->get_hyperref( $kclass, $rootdir, "", "" ) ;

      if ( ! isemptyhash( $self->{'CONTENT'}{'classes'}{$kclass}{'this'} ) ) {
	my %desc = ( 'explanation' => $self->firstsentence( $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'explanation'}{'text'},
							    $rootdir,
							    $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'explanation'}{'location'}
							  ),
		     'link' => $classlink,
		     'type' => $self->{'LANG'}->get('I18N_LANG_INDEX_TYPE_CLASS'),
		   ) ;
	push( @{$all{$kclass}}, \%desc ) ;
      }
      else {
	PhpDocGen::General::Error::warm( "the class $kclass was not defined.\n", "", 0 ) ;
      }

      # Adds the attributes
      PhpDocGen::General::Verbose::three( "\t\tattributes...\n" ) ;
      foreach my $attr (keys %{$self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}}) {
	my $aname = unformatvarname($self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$attr}{'name'}) ;
	my %desc = ( 'explanation' => $self->firstsentence( $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$attr}{'explanation'}{'text'},
							    $rootdir,
							    $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$attr}{'explanation'}{'location'} ),
		     'link' => $self->get_hyperref_classmember( $kclass."::$aname",
						     	    	$rootdir,
						     	    	"$aname",
						     	    	"" ),
		     'type' => $self->{'LANG'}->get('I18N_LANG_INDEX_TYPE_ATTRIBUTE', $classlink),
		   ) ;
	push( @{$all{$aname}}, \%desc ) ;
      }

      # Adds the methods
      PhpDocGen::General::Verbose::three( "\t\tmethods...\n" ) ;
      foreach my $meth (keys %{$self->{'CONTENT'}{'classes'}{$kclass}{'methods'}}) {
	my $mname = addfctbraces( $self->{'CONTENT'}{'classes'}{$kclass}{'methods'}{$meth}{'name'} ) ;
	my %desc = ( 'explanation' => $self->firstsentence( $self->{'CONTENT'}{'classes'}{$kclass}{'methods'}{$meth}{'explanation'}{'text'},
						     	    $rootdir,
						     	    $self->{'CONTENT'}{'classes'}{$kclass}{'methods'}{$meth}{'explanation'}{'location'} ),
		     'link' => $self->get_hyperref_classmember( $kclass."::".addfctbraces($meth),
		     	       					$rootdir,
								$mname,
								"" ),
		     'type' => $self->{'LANG'}->get('I18N_LANG_INDEX_TYPE_METHOD', $classlink),
		     ) ;
	push( @{$all{$mname}}, \%desc ) ;
      }

    } # CLASS

  }

  if ( ( $self->{'GENERATE_PHP_DOC'} ) &&
       ( ! isemptyhash( $self->{'CONTENT'}{'packages'} ) ) ) {

    # Adds the packages
    foreach my $kpack (keys %{$self->{'CONTENT'}{'packages'}}) {
      my $pack = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
      my $packlink = $self->format_hyperref( htmlcatfile($rootdir,$pack,
							 $self->{'THEME'}->filename('package')),
      	 	     			     $pack ) ;

      # Adds the constants
      PhpDocGen::General::Verbose::three( "\tincludes the package $pack\n" ) ;
      PhpDocGen::General::Verbose::three( "\t\tconstants...\n" ) ;
      foreach my $cst (keys %{$self->{'CONTENT'}{'packages'}{$kpack}{'constants'}}) {
	my $cname = unformatvarname($self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$cst}{'name'}) ;
	my %desc = ( 'explanation' => $self->firstsentence( $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$cst}{'explanation'}{'text'},
							    $rootdir,
							    $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$cst}{'explanation'}{'location'} ),
		     'link' => $self->get_hyperref_globalelement( $cname,
		     	       				      	  $rootdir,
							      	  "$cname",
							      	  "" ),
		     'type' => $self->{'LANG'}->get('I18N_LANG_INDEX_TYPE_CONSTANT',$packlink),
		     ) ;
	push( @{$all{$cname}}, \%desc ) ;
      }

      # Adds the variables
      PhpDocGen::General::Verbose::three( "\t\tvariables...\n" ) ;
      foreach my $var (keys %{$self->{'CONTENT'}{'packages'}{$kpack}{'variables'}}) {
	my $vname = unformatvarname($self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$var}{'name'}) ;
	my %desc = ( 'explanation' => $self->firstsentence( $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$var}{'explanation'}{'text'},
							    $rootdir,
							    $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$var}{'explanation'}{'location'} ),
		     'link' => $self->get_hyperref_globalelement( $vname,
		     	       				      	  $rootdir,
							      	  "$vname",
							      	  "" ),
		     'type' => $self->{'LANG'}->get('I18N_LANG_INDEX_TYPE_VARIABLE',$packlink),
		     ) ;
	push( @{$all{$vname}}, \%desc ) ;
      }

      # Adds the functions
      PhpDocGen::General::Verbose::three( "\t\tfunctions...\n" ) ;
      foreach my $fct (keys %{$self->{'CONTENT'}{'packages'}{$kpack}{'functions'}}) {
	my $fname = addfctbraces( $self->{'CONTENT'}{'packages'}{$kpack}{'functions'}{$fct}{'name'} ) ;
	my %desc = ( 'explanation' => $self->firstsentence( $self->{'CONTENT'}{'packages'}{$kpack}{'functions'}{$fct}{'explanation'}{'text'},
							    $rootdir,
							    $self->{'CONTENT'}{'packages'}{$kpack}{'functions'}{$fct}{'explanation'}{'location'} ),
		     'link' => $self->get_hyperref_globalelement( $fct,
		     	       				      	  $rootdir,
							      	  "$fname",
							      	  "" ),
		     'type' => $self->{'LANG'}->get('I18N_LANG_INDEX_TYPE_FUNCTION',$packlink),
		     ) ;
	push( @{$all{$fname}}, \%desc ) ;
      }

    } # PACKAGE
  }

  if ( $self->{'GENERATE_WEB_DOC'} ) {
    my %pages = $self->get_all_webpages() ;

    # Adds the web pages
    foreach my $page ( @{$self->{'SORTED_LISTS'}{'pages'}} ) {
      my $name = $pages{$page}{'name'} ;
      PhpDocGen::General::Verbose::three( "\tincludes the webpage $name...\n" ) ;
      my $simplename = htmlfilename($name) ;
      my $href = $self->get_hyperref_webpage( "web:$name",
					      $rootdir,
					      $simplename,
					      "" ) ;
      my $mod = htmldirname($name) ;
      $mod = $self->get_hyperref_webmodule( "web:$mod",
					    $rootdir,
					    "$mod",
					    "" ) ;

      my %desc = ( 'explanation' => $self->firstsentence( $pages{$page}{'explanation'}{'text'},
							  $rootdir,
							  $pages{$page}{'explanation'}{'location'} ),
		   'link' => $href,
		   'type' => $self->{'LANG'}->get('I18N_LANG_INDEX_TYPE_WEBPAGE',$mod),
		 ) ;
      push( @{$all{$simplename}}, \%desc ) ;

    } # WEBPAGE
  }

  # Builds the list of letters
  PhpDocGen::General::Verbose::three( "\tgets the index letters\n" ) ;
  my @words = (sort { lc($a) cmp lc($b) } keys %all ) ;
  my $letterlist = "" ;
  my $lastletter = "" ;
  my $maxcount = 0 ;

  foreach my $word (@words) {
    $word =~ /^(.)/ ;
    my $letter = lc($1) ;
    if ( ! ( $letter eq $lastletter ) ) {
      $lastletter = $letter ;
      $letterlist .= $self->format_hyperref( htmlcatfile($rootdir,
							 $self->{'THEME'}->filename('indexes',$maxcount)),
			   		     uc( $letter ) ) ;
      $maxcount ++ ;
    }
  }

  if ( isemptyhash(\%all) ) {
    return 0 ;
  }
  $self->{'HAS_INDEXES'} = 1 ;

  # Ouputs the indexes
  my $nav = "" ;
  my $content = '' ;
  my @letterentries = () ;
  my $count = 0 ;
  my $currentfile = "" ;
  $lastletter = "" ;

  foreach my $word (@words) {
    $word =~ /^(.)/ ;
    my $letter = lc($1) ;
    if ( $letter ne $lastletter ) {
      if ( $currentfile ) {
	# finish to write the file
	$content = join( '',
			 $nav,
			 $self->{'THEME'}->partseparator(),
			 $self->{'THEME'}->format_index_page( $letterlist,
							      $lastletter,
							      \@letterentries ),
			 $self->{'THEME'}->partseparator(),
			 $nav,
			 $self->{'THEME'}->partseparator(),
			 $self->get_translator_copyright($rootdir) ) ;
	$self->{'THEME'}->create_html_body_page( $currentfile,
						 $content,
						 $self->{'SHORT_TITLE'},
						 $rootdir ) ;
      }
      PhpDocGen::General::Verbose::three( "\tgenerates the index content for '$letter'\n" ) ;
      $lastletter = $letter ;
      # begin to write the file
      $currentfile = $self->{'THEME'}->filename('indexes',$count) ;
      $nav = $self->{'THEME'}->get_navigation_bar( $currentfile,
						   { 'index' => (($count > 0) && ($self->{'HAS_INDEXES'})),
						     'previous' => ( ( $count > 0 ) ? htmlcatfile($rootdir,
												  $self->{'THEME'}->filename('indexes',($count-1))) : "" ),
						     'next' => ( ($count<($maxcount-1)) ? htmlcatfile($rootdir,
												      $self->{'THEME'}->filename('indexes',($count+1))) : "" ),
						     'notree' => ( isemptyhash( $self->{'CONTENT'}{'classes'} ) ),
						   },
						   $rootdir ) ;
      $count ++ ;
      @letterentries = () ;
    }

    @letterentries = ( @letterentries, @{$all{$word}} ) ;
  }

  if ( $currentfile ) {
    # Really finish the last file
    $content = join( '',
		     $nav,
		     $self->{'THEME'}->partseparator(),
		     $self->{'THEME'}->format_index_page( $letterlist,
							  $lastletter,
							  \@letterentries ),
		     $self->{'THEME'}->partseparator(),
		     $nav,
		     $self->{'THEME'}->partseparator(),
		     $self->get_translator_copyright($rootdir) ) ;
    $self->{'THEME'}->create_html_body_page( $currentfile,
					     $content,
					     $self->{'SHORT_TITLE'},
					     $rootdir ) ;
  }

  return 1 ;
}

=pod

=item * output_package_frame()

Creates the summary of a package.
Takes 3 args:

=over

=item * package (string)

is the name of the package.

=item * outdir (string)

is the output directory.

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub output_package_frame($$$)  {
  my $self = shift ;
  my $kpack = formathashkeyname( $_[0] ) ;
  my $package = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
  my $outdir = $_[1] ;
  my $rootdir = $_[2] || confess( "the rootdir must be supplied" ) ;
  my $currentfile = htmlcatfile( $outdir, $self->{'THEME'}->filename('package-frame') ) ;
  my $content = '' ;

  if ( $self->{'CONTENT'}{'packages'}{$kpack}{'classes'} ) {
    my @scontent = () ;
    foreach my $kclass ( sort (@{$self->{'CONTENT'}{'packages'}{$kpack}{'classes'}}) ) {
      my $classname = $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'name'} ;
      my $href = htmlcatdir($rootdir,$package) ;
      push @scontent, $self->{'THEME'}->ext_href( 'class',
						  $classname,
						  $href,
						  $classname ) ;
    }
    $content .= $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_CLASSES'), \@scontent, $rootdir ) ;
  }

  if ( ! isemptyhash( $self->{'CONTENT'}{'packages'}{$kpack}{'functions'} ) ) {
    my @scontent = () ;
    foreach my $kname ( sort keys (%{$self->{'CONTENT'}{'packages'}{$kpack}{'functions'}}) ) {
      my $name = removefctbraces( $self->{'CONTENT'}{'packages'}{$kpack}{'functions'}{$kname}{'name'} ) ;
      my $href = htmlcatfile($rootdir,$outdir,
			     $self->{'THEME'}->filename('package-functions'))."#$kname" ;
      push @scontent, $self->{'THEME'}->href( $href, $name,
					      $self->{'THEME'}->browserframe('package-functions') ) ;
    }
    $content .= $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_FUNCTIONS'),
						 \@scontent, $rootdir ) ;
  }

  if ( ! isemptyhash( $self->{'CONTENT'}{'packages'}{$kpack}{'constants'} ) ) {
    my @scontent = () ;
    foreach my $kname ( sort keys (%{$self->{'CONTENT'}{'packages'}{$kpack}{'constants'}}) ) {
      my $name = $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kname}{'name'} ;
      my $href = htmlcatfile($rootdir,$outdir,
			     $self->{'THEME'}->filename('package-constants'))."#$kname" ;
      push @scontent, $self->{'THEME'}->href( $href, $name,
					      $self->{'THEME'}->browserframe('package-constants') ) ;
    }
    $content .= $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_CONSTANTS'), \@scontent, $rootdir ) ;
  }

  if ( ! isemptyhash( $self->{'CONTENT'}{'packages'}{$kpack}{'variables'} ) ) {
    my @scontent = () ;
    foreach my $kname ( sort keys (%{$self->{'CONTENT'}{'packages'}{$kpack}{'variables'}}) ) {
      my $name = $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kname}{'name'} ;
      my $href = htmlcatfile($rootdir,$outdir,
			     $self->{'THEME'}->filename('package-variables'))."#$kname" ;
      push @scontent, $self->{'THEME'}->href( $href, $name,
					      $self->{'THEME'}->browserframe('package-variables') ) ;
    }
    $content .= $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_VARIABLES'), \@scontent, $rootdir ) ;
  }

  my $title = join( '',
		    "Package ",
		    $self->{'THEME'}->ext_href( 'package',
						$package,
						htmlcatdir($rootdir,$package) ) ) ;
  $self->{'THEME'}->create_html_body_page( $currentfile,
					   $self->{'THEME'}->frame_window( $title,
									   $content ),
					   $self->{'LANG'}->get('I18N_LANG_PACKAGE_NAME',$package),
					   $rootdir ) ;
}


=pod

=item * output_package_summary()

Creates the summary of a package.
Takes 3 args:

=over

=item * package (string)

is the name of the package.

=item * outdir (string)

is the output directory.

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub output_package_summary($$$)  {
  my $self = shift ;
  my $kpack = formathashkeyname( $_[0] ) ;
  my $package = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
  my $outdir = $_[1] ;
  my $rootdir = $_[2] || confess( "the rootdir must be supplied" ) ;
  my $currentfile = htmlcatfile( $outdir, $self->{'THEME'}->filename('package') ) ;

  # Computes the next and previous packages
  my $position = posinarray($kpack,$self->{'SORTED_LISTS'}{'packages'}) ;
  my $previous_pack = ( ( $position > 0 ) ?
			htmlcatfile( $rootdir,
				     $self->{'CONTENT'}{'packages'}{$self->{'SORTED_LISTS'}{'packages'}->[$position-1]}{'this'}{'name'},
				     $self->{'THEME'}->filename('package') ) :
			htmlcatfile($rootdir,$self->{'THEME'}->filename('overview')) ) ;
  my $next_pack = ( ( $position < $#{$self->{'SORTED_LISTS'}{'packages'}} ) ?
		    htmlcatfile( $rootdir,
				 $self->{'CONTENT'}{'packages'}{$self->{'SORTED_LISTS'}{'packages'}->[$position+1]}{'this'}{'name'},
				 $self->{'THEME'}->filename('package') ) :
		    '' ) ;

  my $nav = $self->{'THEME'}->get_navigation_bar( htmlcatfile( $rootdir, $currentfile ),
						  { 'notree' => ( isemptyhash( $self->{'CONTENT'}{'classes'} ) ),
						    'index' => $self->{'HAS_INDEXES'},
						    'previous' => $previous_pack,
						    'next' => $next_pack,
						  },
						  $rootdir ) ;

  my $content = join( '',
		      $nav,
		      $self->{'THEME'}->partseparator(),
		      $self->{'THEME'}->title( $self->{'LANG'}->get('I18N_LANG_PACKAGE_NAME',$package) )
		    ) ;

  if ( $self->{'CONTENT'}{'packages'}{$kpack}{'classes'} ) {
    my @classes = () ;
    foreach my $kclass ( sort (@{$self->{'CONTENT'}{'packages'}{$kpack}{'classes'}}) ) {
      my $classname = $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'name'} ;
      my $href = htmlcatfile($rootdir,$outdir,$self->{'THEME'}->filename('class',$classname)) ;
      my $comment = $self->briefcomment( $self->{'CONTENT'}{'classes'}{$kclass}{'this'},
					 $rootdir ) ;
      my %hash = (
		  'name' => $self->{'THEME'}->href( $href, $classname ),
		  'explanation' => "$comment",
		 ) ;
      push( @classes, \%hash ) ;
    }
    $content .= $self->{'THEME'}->build_twocolumn_array( $self->{'LANG'}->get('I18N_LANG_CLASSES'), \@classes ) ;
  }

  if ( ! isemptyhash( $self->{'CONTENT'}{'packages'}{$kpack}{'functions'} ) ) {
    my @acontent = () ;
    foreach my $kname ( sort keys (%{$self->{'CONTENT'}{'packages'}{$kpack}{'functions'}}) ) {
      my $name = removefctbraces( $self->{'CONTENT'}{'packages'}{$kpack}{'functions'}{$kname}{'name'} ) ;
      my $href = htmlcatfile($rootdir,$outdir,$self->{'THEME'}->filename('package-functions'))."#$kname" ;
      my $comment = $self->briefcomment( $self->{'CONTENT'}{'packages'}{$kpack}{'functions'}{$kname}, $rootdir ) ;
      my %hash = (
		  'name' => $self->{'THEME'}->href( $href, $name ),
		  'explanation' => "$comment",
		 ) ;
      push( @acontent, \%hash ) ;
    }
    $content .= $self->{'THEME'}->build_twocolumn_array( $self->{'LANG'}->get('I18N_LANG_FUNCTIONS'), \@acontent ) ;
  }

  if ( ! isemptyhash( $self->{'CONTENT'}{'packages'}{$kpack}{'constants'} ) ) {
    my @acontent = () ;
    foreach my $kname ( sort keys (%{$self->{'CONTENT'}{'packages'}{$kpack}{'constants'}}) ) {
      my $name = $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kname}{'name'} ;
      my $href = htmlcatfile($rootdir,$outdir,
			     $self->{'THEME'}->filename('package-constants'))."#$kname" ;
      my $comment = $self->briefcomment( $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kname}, $rootdir ) ;
      my %hash = (
		  'name' => $self->{'THEME'}->href( $href, $name ),
		  'explanation' => "$comment",
		 ) ;
      push( @acontent, \%hash ) ;
    }
    $content .= $self->{'THEME'}->build_twocolumn_array( "Constants", \@acontent ) ;
  }

  if ( ! isemptyhash( $self->{'CONTENT'}{'packages'}{$kpack}{'variables'} ) ) {
    my @acontent = () ;
    foreach my $kname ( sort keys (%{$self->{'CONTENT'}{'packages'}{$kpack}{'variables'}}) ) {
      my $name = $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kname}{'name'} ;
      my $href = htmlcatfile($rootdir,$outdir,
			     $self->{'THEME'}->filename('package-variables'))."#$kname" ;
      my $comment = $self->briefcomment( $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kname}, $rootdir ) ;
      my %hash = (
		  'name' => $self->{'THEME'}->href( $href, $name ),
		  'explanation' => "$comment",
		 ) ;
      push( @acontent, \%hash ) ;
    }
    $content .= $self->{'THEME'}->build_twocolumn_array( $self->{'LANG'}->get('I18N_LANG_VARIABLES'), \@acontent ) ;
  }

  $content .= join( '',
		    $self->{'THEME'}->partseparator(),
		    $nav,
		    $self->{'THEME'}->partseparator(),
		    $self->get_translator_copyright("") ) ;
  $self->{'THEME'}->create_html_body_page( $currentfile,
					   $content,
					   $self->{'LANG'}->get('I18N_LANG_PACKAGE_NAME',$package),
					   $rootdir ) ;
}

=pod

=item * __get_previous_package_member()

Replies a link to the previous package member.
Takes 4 args:

=over

=item * pack (string)

is the package key

=item * member_type (string)

is the type of member ('functions','constants','variables')

=item * theme_type (string)

is the type of member for the theme ('package-functions','package-constants','package-variables')

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub __get_previous_package_member($$$$) {
  my $self = shift ;
  my $position = posinarray($_[0],$self->{'SORTED_LISTS'}{'packages'}) ;
  my $previous_pack = '' ;
  if ( $position > 0 ) {
    my $i = $position - 1 ;
    while ( ( $i >= 0 ) && ( ! $previous_pack ) ) {
      my $ppack = $self->{'SORTED_LISTS'}{'packages'}[$i] ;
      if ( ( exists $self->{'CONTENT'}{'packages'}{$ppack}{$_[1]} ) &&
	   ( ! isemptyhash($self->{'CONTENT'}{'packages'}{$ppack}{$_[1]}) ) ) {
	$previous_pack = htmlcatfile($_[3],
				     $self->{'SORTED_LISTS'}{'packages'}[$i],
				     $self->{'THEME'}->filename($_[2])
				    ) ;
      }
      $i -- ;
    }
  }
  return $previous_pack ;
}

=pod

=item * __get_next_package_member()

Replies a link to the next package member.
Takes 4 args:

=over

=item * pack (string)

is the package key

=item * member_type (string)

is the type of member ('functions','constants','variables')

=item * theme_type (string)

is the type of member for the theme ('package-functions','package-constants','package-variables')

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub __get_next_package_member($$$$) {
  my $self = shift ;
  my $position = posinarray($_[0],$self->{'SORTED_LISTS'}{'packages'}) ;
  my $next_pack = '' ;
  if ( $position < $#{$self->{'SORTED_LISTS'}{'packages'}} ) {
    my $i = $position + 1 ;
    while ( ( $i <= $#{$self->{'SORTED_LISTS'}{'packages'}} ) && ( ! $next_pack ) ) {
      my $ppack = $self->{'SORTED_LISTS'}{'packages'}[$i] ;
      if ( ( exists $self->{'CONTENT'}{'packages'}{$ppack}{$_[1]} ) &&
	   ( ! isemptyhash($self->{'CONTENT'}{'packages'}{$ppack}{$_[1]}) ) ) {
	$next_pack = htmlcatfile($_[3],
				 $self->{'SORTED_LISTS'}{'packages'}[$i],
				 $self->{'THEME'}->filename($_[2])
				) ;
      }
      $i ++ ;
    }
  }
  return $next_pack ;
}

=pod

=item * output_package_functions()

Creates the functions of a package.
Takes 3 args:

=over

=item * package (string)

is the name of the package.

=item * outdir (string)

is the output directory.

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub output_package_functions($$$)  {
  my $self = shift ;
  my $kpack = formathashkeyname( $_[0] ) ;
  my $package = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
  my $outdir = $_[1] ;
  my $rootdir = $_[2] || confess( "the rootdir must be supplied" ) ;

  if ( ! isemptyhash( $self->{'CONTENT'}{'packages'}{$kpack}{'functions'} ) ) {
    my $currentfile = htmlcatfile( $outdir,
				   $self->{'THEME'}->filename('package-functions') ) ;

    # Computes the next and previous packages
    my $previous_pack = $self->__get_previous_package_member( $kpack,
							      'functions',
							      'package-functions',
							      $rootdir ) ;
    my $next_pack = $self->__get_next_package_member( $kpack,
						      'functions',
						      'package-functions',
						      $rootdir ) ;

    my $nav = $self->{'THEME'}->get_navigation_bar( htmlcatfile($rootdir,$currentfile),
				  	 { 'package' => htmlcatfile($rootdir,$outdir,
								    $self->{'THEME'}->filename('package')),
				    	   'notree' => ( isemptyhash( $self->{'CONTENT'}{'classes'} ) ),
					   'index' => $self->{'HAS_INDEXES'},
					   'previous' => $previous_pack,
					   'next' => $next_pack,
				  	 },
				  	 $rootdir ) ;

    my $content = join( '',
			$nav,
			$self->{'THEME'}->partseparator(),
			$self->{'THEME'}->title( $self->{'LANG'}->get('I18N_LANG_PACKAGE_FUNCTIONS',
								      $self->{'THEME'}->href( htmlcatfile($rootdir,$outdir,
													  $self->{'THEME'}->filename('package')),
											      $package ) ) )
		      ) ;

    # Builds the summary
    my @acontent = () ;
    foreach my $name ( sort keys (%{$self->{'CONTENT'}{'packages'}{$kpack}{'functions'}}) ) {
      my %hash = $self->build_function_summary( $name,
				       		$self->{'CONTENT'}{'packages'}{$kpack}{'functions'}{$name},
				       		$rootdir, $currentfile, $outdir ) ;
      push( @acontent, \%hash ) ;
    }
    $content .= $self->{'THEME'}->build_threecolumn_array( $self->{'LANG'}->get('I18N_LANG_FUNCTION_SUMMARY'),
							   \@acontent, "_section_function_summary" ) .
      $self->{'THEME'}->partseparator() ;

    # Builds the details
    $content .= $self->{'THEME'}->build_detail_section_title( $self->{'LANG'}->get('I18N_LANG_FUNCTION_DETAIL'),
							      "_section_function_detail" ) ;
    foreach my $name (sort keys %{$self->{'CONTENT'}{'packages'}{$kpack}{'functions'}}) {
      $content .= $self->build_function_detail( $name,
				       		$self->{'CONTENT'}{'packages'}{$kpack}{'functions'}{$name},
				       		$rootdir, $currentfile, $outdir ) .
						  $self->{'THEME'}->partseparator() ;
    }

    $content .= join( '',
		      $nav,
		      $self->{'THEME'}->partseparator(),
		      $self->get_translator_copyright("") ) ;
    $self->{'THEME'}->create_html_body_page( $currentfile,
					     $content,
					     $self->{'LANG'}->get('I18N_LANG_PACKAGE_FUNCTIONS',$package),
					     $rootdir ) ;
  }

}

=pod

=item * output_package_constants()

Creates the constants of a package.
Takes 3 args:

=over

=item * package (string)

is the name of the package.

=item * outdir (string)

is the output directory.

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub output_package_constants($$$)  {
  my $self = shift ;
  my $kpack = formathashkeyname( $_[0] ) ;
  my $package = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
  my $outdir = $_[1] ;
  my $rootdir = $_[2] || confess( "the rootdir must be supplied" ) ;

  if ( ! isemptyhash( $self->{'CONTENT'}{'packages'}{$kpack}{'constants'} ) ) {
    my $currentfile = htmlcatfile($outdir,
				  $self->{'THEME'}->filename('package-constants')) ;

    # Computes the next and previous packages
    my $previous_pack = $self->__get_previous_package_member( $kpack,
							      'constants',
							      'package-constants',
							      $rootdir ) ;
    my $next_pack = $self->__get_next_package_member( $kpack,
						      'constants',
						      'package-constants',
						      $rootdir ) ;

    my $nav = $self->{'THEME'}->get_navigation_bar( htmlcatfile($rootdir,$currentfile),
				  	 { 'package' => htmlcatfile($rootdir,$outdir,
								    $self->{'THEME'}->filename('package')),
				    	   'notree' => ( isemptyhash( $self->{'CONTENT'}{'classes'} ) ),
					   'index' => $self->{'HAS_INDEXES'},
					   'previous' => $previous_pack,
					   'next' => $next_pack,
				  	 },
				  	 $rootdir ) ;

    my $content = join( '',
			$nav,
			$self->{'THEME'}->partseparator(),
			$self->{'THEME'}->title( $self->{'LANG'}->get('I18N_LANG_PACKAGE_CONSTANTS',
								      $self->{'THEME'}->href( htmlcatfile($rootdir,$outdir,
													  $self->{'THEME'}->filename('package')),
											      $package ) ) )
		      ) ;

    # Builds the summary
    my @acontent = () ;
    foreach my $kname ( sort keys (%{$self->{'CONTENT'}{'packages'}{$kpack}{'constants'}}) ) {
      my $name = $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kname}{'name'} ;
      my $explanation = $self->briefcomment( $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kname},
                                             $rootdir ) ;
      $self->addsourcelink( $explanation, $rootdir, $currentfile,
			    $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kname}{'location'} ) ;
      my %hash = ( 'name' => $self->{'THEME'}->href( "#$kname", $name ),
		   'explanation' => $explanation ) ;
      push( @acontent, \%hash ) ;
    }
    $content .= $self->{'THEME'}->build_twocolumn_array( $self->{'LANG'}->get('I18N_LANG_CONSTANT_SUMMARY'),
							 \@acontent ) .
							   $self->{'THEME'}->partseparator() ;
										

    # Builds the details
    $content .= $self->{'THEME'}->build_detail_section_title( $self->{'LANG'}->get('I18N_LANG_CONSTANT_DETAIL'),
							      "_section_constant_detail" ) ;
    foreach my $kname ( sort keys (%{$self->{'CONTENT'}{'packages'}{$kpack}{'constants'}}) ) {
      my $name = $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kname}{'name'} ;
      my $explanation = $self->expand( $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kname}{'explanation'}{'text'},
				       $rootdir,
				       $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kname}{'explanation'}{'location'} ) ;
      $self->addsourcelink( $explanation, $rootdir, $currentfile,
			    $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kname}{'explanation'}{'location'} ) ;
      my $type = $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kname}{'type'} ;
      $content .= join( '',
			$self->{'THEME'}->build_function_detail( $kname, $name,
								 "$type ".
								 $self->{'THEME'}->strong(formatvarname($name)),
								 $explanation,
								 $self->build_common_tag_parts( $self->{'CONTENT'}{'packages'}{$kpack}{'constants'}{$kname},
												$rootdir) ),
			$self->{'THEME'}->partseparator()
		      ) ;
    }

    $content .= join( '',
		      $nav,
		      $self->{'THEME'}->partseparator(),
		      $self->get_translator_copyright("") ) ;
    $self->{'THEME'}->create_html_body_page( $currentfile,
					     $content,
					     $self->{'LANG'}->get('I18N_LANG_PACKAGE_CONSTANTS', $package),
					     $rootdir ) ;
  }

}

=pod

=item * output_package_variables()

Creates the variables of a package.
Takes 3 args:

=over

=item * package (string)

is the name of the package.

=item * outdir (string)

is the output directory.

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub output_package_variables($$$$)  {
  my $self = shift ;
  my $kpack = formathashkeyname( $_[0] ) ;
  my $package = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
  my $outdir = $_[1] ;
  my $rootdir = $_[2] || confess( "the rootdir must be supplied" ) ;

  if ( ! isemptyhash( $self->{'CONTENT'}{'packages'}{$kpack}{'variables'} ) ) {
    my $currentfile = htmlcatfile($outdir,
				  $self->{'THEME'}->filename('package-variables')) ;

    # Computes the next and previous packages
    my $previous_pack = $self->__get_previous_package_member( $kpack,
							      'variables',
							      'package-variables',
							      $rootdir ) ;
    my $next_pack = $self->__get_next_package_member( $kpack,
						      'variables',
						      'package-variables',
						      $rootdir ) ;

    my $nav = $self->{'THEME'}->get_navigation_bar( htmlcatfile($rootdir,$currentfile),
				  	 { 'package' => htmlcatfile($rootdir,$outdir,
								    $self->{'THEME'}->filename('package')),
				    	   'notree' => ( isemptyhash( $self->{'CONTENT'}{'classes'} ) ),
					   'index' => $self->{'HAS_INDEXES'},
					   'previous' => $previous_pack,
					   'next' => $next_pack,
				  	 },
  				  	 $rootdir ) ;

    my $content = join( '',
			$nav,
			$self->{'THEME'}->partseparator(),
			$self->{'THEME'}->title( $self->{'LANG'}->get('I18N_LANG_PACKAGE_VARIABLES',
								      $self->{'THEME'}->href( htmlcatfile($rootdir,$outdir,
													  $self->{'THEME'}->filename('package')),
											      $package ) ) )
		      ) ;

    # Builds the summary
    my @acontent = () ;
    foreach my $kname ( sort keys (%{$self->{'CONTENT'}{'packages'}{$kpack}{'variables'}}) ) {
      my $name = $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kname}{'name'} ;
      my $explanation = $self->briefcomment( $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kname},
                                             $rootdir ) ;
      $self->addsourcelink( $explanation, $rootdir, $currentfile,
                            $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kname}{'location'} ) ;
      my %hash = ( 'name' => $self->{'THEME'}->href( "#$kname", $name ),
		   'explanation' => $explanation ) ;
      push( @acontent, \%hash ) ;
    }
    $content .= $self->{'THEME'}->build_twocolumn_array( $self->{'LANG'}->get('I18N_LANG_VARIABLE_SUMMARY'),
							 \@acontent ) .
							   $self->{'THEME'}->partseparator() ;

    # Builds the details
    $content .= $self->{'THEME'}->build_detail_section_title( $self->{'LANG'}->get('I18N_LANG_VARIABLE_DETAIL'),
							      "_section_variable_detail" ) ;
    foreach my $kname ( sort keys (%{$self->{'CONTENT'}{'packages'}{$kpack}{'variables'}}) ) {
      my $name = $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kname}{'name'} ;
      my $explanation = $self->expand( $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kname}{'explanation'}{'text'},
				       $rootdir,
				       $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kname}{'explanation'}{'location'} ) ;
      $self->addsourcelink( $explanation, $rootdir, $currentfile, 
			    $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kname}{'explanation'}{'location'} ) ;
      my $type = $self->{'THEME'}->keyword($self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kname}{'type'}) ;
      $content .= join( '',
			$self->{'THEME'}->build_function_detail( $kname, $name,
								 "$type ".
								 $self->{'THEME'}->strong(formatvarname($name)),
								 $explanation,
								 $self->build_common_tag_parts( $self->{'CONTENT'}{'packages'}{$kpack}{'variables'}{$kname},
												$rootdir) ),
			$self->{'THEME'}->partseparator()
		      ) ;
    }

    $content .= join( '',
		      $nav,
		      $self->{'THEME'}->partseparator(),
		      $self->get_translator_copyright("") ) ;
    $self->{'THEME'}->create_html_body_page( $currentfile,
					     $content,
					     $self->{'LANG'}->get('I18N_LANG_PACKAGE_VARIABLES',$package),
					     $rootdir ) ;
  }

}

=pod

=item * output_package_class()

Creates the class of a package.
Takes 3 args:

=over

=item * name (string)

is the name of the class.

=item * outdir (string)

is the output directory.

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub output_package_class($$$)  {
  my $self = shift ;
  my $kclass = formathashkeyname($_[0]) ;
  my $class = $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'name'} ;
  my $outdir = $_[1] ;
  my $rootdir = $_[2] || confess( "the rootdir must be supplied" ) ;
  my $kpack = formathashkeyname( $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'package'} ) ;
  my $package = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
  my $currentfile = htmlcatfile($outdir,
				$self->{'THEME'}->filename('class',$class)) ;

  # Computes the previous and nexy classes
  my $position = posinarray($kclass,$self->{'SORTED_LISTS'}{'classes'}) ;
  my $next_class = ( ( $position < $#{$self->{'SORTED_LISTS'}{'classes'}} ) ?
		     $self->get_hyperref_class( $self->{'SORTED_LISTS'}{'classes'}[$position+1],
						$rootdir,
						"",
						"" ) :
		     '' ) ;
  if ( $next_class =~ /href\=\"([^\"]*)\"/i ) {
    $next_class = $1 ;
  }
  else {
    $next_class = '' ;
  }
  my $previous_class = ( ( $position > 0 ) ?
			 $self->get_hyperref_class( $self->{'SORTED_LISTS'}{'classes'}[$position-1],
						    $rootdir,
						    "",
						    "" ) :
			 '' ) ;
  if ( $previous_class =~ /href\=\"([^\"]*)\"/i ) {
    $previous_class = $1 ;
  }
  else {
    $previous_class = '' ;
  }

  my $nav = $self->{'THEME'}->get_navigation_bar( htmlcatfile($rootdir,$currentfile),
						  { 'package' => htmlcatfile($rootdir,$outdir,
									     $self->{'THEME'}->filename('package')),
						    'fields' => ( ! isemptyhash( $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'} ) ),
						    'constructors' => ( ! isemptyhash( $self->{'CONTENT'}{'classes'}{$kclass}{'constructor'} ) ),
						    'methods' => ( ! isemptyhash( $self->{'CONTENT'}{'classes'}{$kclass}{'methods'} ) ),
						    'index' => $self->{'HAS_INDEXES'},
						    'previous' => $previous_class,
						    'next' => $next_class,
						  },
						  $rootdir ) ;

  my $content = join( '',
		      $nav,
		      $self->{'THEME'}->partseparator(),
		      $self->{'THEME'}->classtitle( $package, $class ),
		      $self->build_inheritance_tree($class, $rootdir),
		      $self->get_children_list($class, $rootdir),
		      $self->{'THEME'}->partseparator()
		    ) ;

  my $url = '' ;
  if ( $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'extends'}{'class'} ) {
    $url = $self->get_hyperref_class( $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'extends'}{'class'},
				      $rootdir,"",
				      $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'extends'}{'location'} ) ;
  }
  $content .= join( '',
		    $self->{'THEME'}->build_class_detail( $class,
							  $url,
							  $self->expand( $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'explanation'}{'text'},
									 $rootdir,
									 $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'explanation'}{'location'}),
							  $self->build_common_tag_parts( $self->{'CONTENT'}{'classes'}{$kclass}{'this'},
											 $rootdir) ),
		    $self->{'THEME'}->partseparator()
		  ) ;

  # Builds the summary of fields
  if ( ! isemptyhash( $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'} ) ) {
    my @acontent = () ;
    foreach my $kname ( sort keys (%{$self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}}) ) {
      my $name = $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kname}{'name'} ;
      my $explanation = $self->briefcomment( $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kname},
                                             $rootdir ) ;
      my $modifier = "" ;
      if ( $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kname}{'private'} ) {
	$modifier = $self->{'THEME'}->keyword($self->{'LANG'}->get('I18N_LANG_PRIVATE'))." " ;
      }
      elsif ( $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kname}{'protected'} ) {
	$modifier = $self->{'THEME'}->keyword($self->{'LANG'}->get('I18N_LANG_PUBLIC'))." " ;
      }
      my %hash = ( 'name' => $self->{'THEME'}->href( "#$kname", formatvarname($name) ),
		   'explanation' => $explanation,
		   'type' => $modifier.$self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kname}{'type'}) ;
      $self->addsourcelink( $hash{'explanation'}, $rootdir, $currentfile, 
			    $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'location'} ) ;
      push( @acontent, \%hash ) ;
    }
    $content .= $self->{'THEME'}->build_threecolumn_array( $self->{'LANG'}->get('I18N_LANG_FIELD_SUMMARY'),
							   \@acontent,
							   "_section_field_summary" ) ;
  }

  # Builds the summary of constructors
  if ( ! isemptyhash( $self->{'CONTENT'}{'classes'}{$kclass}{'constructor'} ) ) {
    my @acontent = () ;
    my $cons = addfctbraces( $class ) ;
    my %hash = $self->build_function_summary( $cons,
				     	      $self->{'CONTENT'}{'classes'}{$kclass}{'constructor'},
				     	      $rootdir, $currentfile, $outdir ) ;
    push( @acontent, \%hash ) ;
    $content .= $self->{'THEME'}->build_threecolumn_array( $self->{'LANG'}->get('I18N_LANG_CONSTRUCTOR_SUMMARY'),
							   \@acontent,
							   "_section_constructor_summary" ) ;
  }

  # Builds the summary of methods
  if ( ! isemptyhash( $self->{'CONTENT'}{'classes'}{$kclass}{'methods'} ) ) {
    my @acontent = () ;
    foreach my $kname ( sort keys (%{$self->{'CONTENT'}{'classes'}{$kclass}{'methods'}}) ) {
      my $name = $self->{'CONTENT'}{'classes'}{$kclass}{'methods'}{$kname}{'name'} ;
      my %hash = $self->build_function_summary( $name,
				       		$self->{'CONTENT'}{'classes'}{$kclass}{'methods'}{$kname},
				       		$rootdir, $currentfile, $outdir ) ;
      push( @acontent, \%hash ) ;
    }
    $content .= $self->{'THEME'}->build_threecolumn_array( $self->{'LANG'}->get('I18N_LANG_METHOD_SUMMARY'),
							   \@acontent,
							   "_section_method_summary" ) ;
  }

  # Builds the summary of inherited methods
  $content .= $self->build_inherited_methods($class,$rootdir) ;

  # Builds the details of fields
  if ( ! isemptyhash( $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'} ) ) {
    $content .= 
      $self->{'THEME'}->partseparator() .
	$self->{'THEME'}->build_detail_section_title( $self->{'LANG'}->get('I18N_LANG_FIELD_DETAIL'),
						      "_section_field_detail" ) ;
    foreach my $kname ( sort keys (%{$self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}}) ) {
      my $name = $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kname}{'name'} ;
      my $explanation = $self->expand( $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kname}{'explanation'}{'text'},
				       $rootdir,
				       $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kname}{'explanation'}{'location'} ) ;
      $self->addsourcelink( $explanation, $rootdir, $currentfile,
                            $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kname}{'explanation'}{'location'} ) ;
      my $type = $self->{'THEME'}->keyword($self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kname}{'type'}) ;
      my $modifier = "" ;
      if ( $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kname}{'private'} ) {
	$modifier = $self->{'THEME'}->keyword($self->{'LANG'}->get('I18N_LANG_PRIVATE'))." " ;
      }
      elsif ( $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kname}{'protected'} ) {
	$modifier = $self->{'THEME'}->keyword($self->{'LANG'}->get('I18N_LANG_PROTECTED'))." " ;
      }
      $content .= join( '',
			$self->{'THEME'}->build_function_detail( $kname, $name,
								 "$modifier$type ".
								 $self->{'THEME'}->strong(formatvarname($name)),
								 $explanation,
								 $self->build_common_tag_parts( $self->{'CONTENT'}{'classes'}{$kclass}{'attributes'}{$kname},
												$rootdir) ),
			$self->{'THEME'}->partseparator()
		      ) ;
    }
  }

  # Builds the details of constructors
  if ( ! isemptyhash( $self->{'CONTENT'}{'classes'}{$kclass}{'constructor'} ) ) {
    $content .= $self->{'THEME'}->build_detail_section_title( $self->{'LANG'}->get('I18N_LANG_CONSTRUCTOR_DETAIL'),
							      "_section_constructor_detail" ) ;
    my $cons = addfctbraces( $class ) ;
    $content .= $self->build_function_detail( $cons,
				     	      $self->{'CONTENT'}{'classes'}{$kclass}{'constructor'},
				     	      $rootdir, $currentfile, $outdir ) .
						$self->{'THEME'}->partseparator() ;
  }

  # Builds the details of methods
  if ( ! isemptyhash( $self->{'CONTENT'}{'classes'}{$kclass}{'methods'} ) ) {
    $content .= $self->{'THEME'}->build_detail_section_title( $self->{'LANG'}->get('I18N_LANG_METHOD_DETAIL'),
							      "_section_method_detail" ) ;
    foreach my $kname (sort keys %{$self->{'CONTENT'}{'classes'}{$kclass}{'methods'}}) {
      my $name = $self->{'CONTENT'}{'classes'}{$kclass}{'methods'}{$kname}{'name'} ;
      $content .= $self->build_function_detail( $name,
				       		$self->{'CONTENT'}{'classes'}{$kclass}{'methods'}{$kname},
				       		$rootdir, $currentfile, $outdir ) .
						  $self->{'THEME'}->partseparator() ;
    }
  }

  $content .= join( '',
		    $nav,
		    $self->{'THEME'}->partseparator(),
		    $self->get_translator_copyright("") ) ;

  $self->{'THEME'}->create_html_body_page( $currentfile,
					   $content,
					   $self->{'SHORT_TITLE'},
					   $rootdir ) ;
}

=pod

=item * output_module_frame()

Creates the summary of a module.
Takes 3 args:

=over

=item * module (hash)

is the description of the package.

=item * outdir (string)

is the output directory.

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub output_module_frame($$$)  {
  my $self = shift ;
  my $outdir = $_[1] ;
  my $rootdir = $_[2] || confess( "the rootdir must be supplied" ) ;
  my $currentfile = htmlcatfile( $outdir,
				 $self->{'THEME'}->filename('module-frame') ) ;
  my $modname = $_[0]{'name'} ;

  my $content = '' ;

  if ( ! isemptyarray( $_[0]{'submodules'} ) ) {
    my @scontent = () ;
    foreach my $sub ( sort (@{$_[0]{'submodules'}}) ) {
      my $submodname = $sub ;
      my $href = htmlcatdir($rootdir,$self->{'WEBDOC_DIR'},$_[0]{'url'},$submodname) ;
      push @scontent, $self->{'THEME'}->href( htmlcatfile($href,
							  $self->{'THEME'}->filename('module-frame')),
					      $submodname ) ;
    }
    if ( @scontent ) {
      $content .= $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_SUBMODULES'),
						   \@scontent, $rootdir ) ;
    }
  }

  if ( ! isemptyarray( $_[0]{'pages'} ) ) {
    my @scontent = () ;
    foreach my $page ( sort (@{$_[0]{'pages'}}) ) {
      my $fullname = htmlcatfile($_[0]{'name'},$page) ;
      my $href = $self->get_hyperref_webpage("web:$fullname",$rootdir,$page,"") ;
      $href =~ s/HREF=/TARGET=\"classFrame\" HREF=/i ;
      push @scontent, $href ;
    }
    if ( @scontent ) {
      $content .= $self->{'THEME'}->frame_subpart( $self->{'LANG'}->get('I18N_LANG_PAGES'),
						   \@scontent, $rootdir ) ;
    }
  }

  $content  = $self->{'THEME'}->frame_window( $self->{'LANG'}->get('I18N_LANG_WEBMODULE',
								   $self->{'THEME'}->href( htmlcatfile($rootdir,$self->{'WEBDOC_DIR'},
												       $_[0]{'url'},
												       $self->{'THEME'}->filename('webmodule')),
											   $modname,
											   $self->{'THEME'}->browserframe('webmodule') ) ),
					      $content ) ;
  $self->{'THEME'}->create_html_body_page( $currentfile,
					   $content,
					   $self->{'LANG'}->get('I18N_LANG_WEBMODULE',$modname),
					   $rootdir ) ;
}

=pod

=item * output_module_summary()

Creates the summary of a module.
Takes 4 args:

=over

=item * module (hash)

is the description of the module.

=item * modules (hash ref)

is the description of ALL the modules.

=item * outdir (string)

is the output directory.

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub output_module_summary($$$$)  {
  my $self = shift ;
  my $outdir = $_[2] ;
  my $rootdir = $_[3] || confess( "the rootdir must be supplied" ) ;
  my $currentfile = htmlcatfile( $outdir,
				 $self->{'THEME'}->filename('webmodule') ) ;
  my $modname = $_[0]{'name'} ;

  my $nav = $self->{'THEME'}->get_navigation_bar( htmlcatfile( $rootdir, $currentfile ),
				       { 'notree' => ( ( isemptyhash( $self->{'CONTENT'}{'classes'} ) ) &&
						       ( isemptyhash( $self->{'CONTENT'}{'webmodules'} ) ) ),
					 'index' => $self->{'HAS_INDEXES'},
				       },
				       $rootdir ) ;

  my $content = join( '',
		      $nav,
		      $self->{'THEME'}->partseparator(),
		      $self->{'THEME'}->title( $self->{'LANG'}->get('I18N_LANG_WEBMODULE',$modname) ),
		      $self->{'THEME'}->par( $_[0]{'explanation'}{'text'} )
		    ) ;

  $content .= $self->build_common_tag_parts($_[0]{'fields'},$rootdir) ;

  if ( ! isemptyarray( $_[0]{'pages'} ) ) {
    my @pages = () ;
    my %allpages = $self->get_all_webpages() ;
    foreach my $page ( sort (@{$_[0]{'pages'}}) ) {
      my $pagename = htmlcatfile($_[0]{'name'},$page) ;
      my $href = htmlcatfile($rootdir,$self->{'WEBDOC_DIR'},$_[0]{'url'},
			     $self->{'THEME'}->filename('webpage',$page)) ;
      my $comment = $self->briefcomment( $allpages{$pagename},
					 $rootdir ) ;
      my %hash = (
		  'name' => $self->{'THEME'}->href( $href, $page ),
		  'explanation' => "$comment",
		 ) ;
      push( @pages, \%hash ) ;
    }
    $content .= $self->{'THEME'}->build_twocolumn_array( $self->{'LANG'}->get('I18N_LANG_PAGES'),
							 \@pages ) ;
  }

  if ( ! isemptyarray( $_[0]{'submodules'} ) ) {
    my @modules = () ;
    foreach my $module ( sort (@{$_[0]{'submodules'}}) ) {
      my $modname = $_[1]->{$module}{'name'} ;
      my $href = htmlcatfile($rootdir,$self->{'WEBDOC_DIR'},$modname,
			     $self->{'THEME'}->filename('webmodule')) ;
      my $comment = $self->briefcomment( $_[1]->{$module},
					 $rootdir ) ;
      my %hash = (
		  'name' => $self->{'THEME'}->href( $href, $module ),
		  'explanation' => "$comment",
		 ) ;
      push( @modules, \%hash ) ;
    }
    $content .= $self->{'THEME'}->build_twocolumn_array( $self->{'LANG'}->get('I18N_LANG_SUBMODULES'),
							 \@modules ) ;
  }

  $content .= join( '',
		    $self->{'THEME'}->partseparator(),
		    $nav,
		    $self->{'THEME'}->partseparator(),
		    $self->get_translator_copyright("") ) ;

  $self->{'THEME'}->create_html_body_page( $currentfile,
					   $content,
					   $self->{'LANG'}->get('I18N_LANG_WEBMODULE',$modname),
					   $rootdir ) ;
}

=pod

=item * output_module_page_summary()

Creates the summary of a webpage.
Takes 5 args:

=over

=item * page (hash)

is the description of the page.

=item * pages (hash ref)

is the description of ALL the pages.

=item * module (hash)

is the description of the module that contains the page.

=item * outdir (string)

is the output directory.

=item * root (string)

is the root directory of the generated documentation.

=back

=cut
sub output_module_page_summary($$$$$)  {
  my $self = shift ;
  my $outdir = $_[3] ;
  my $rootdir = $_[4] || confess( "the rootdir must be supplied" ) ;
  my $currentfile = htmlcatfile( $outdir,
				 $self->{'THEME'}->filename('webpage',basename($_[0]{'url'})) ) ;
  my $pagename = $_[0]{'name'} ;

  my $nav = $self->{'THEME'}->get_navigation_bar( htmlcatfile( $rootdir, $currentfile ),
				       { 'webmodule' => htmlcatfile( $rootdir,
                                                                     $self->{'WEBDOC_DIR'},
                                                                     $_[2]{'name'},
                                                                     $self->{'THEME'}->filename('webmodule') ),
                                         'notree' => ( ( isemptyhash( $self->{'CONTENT'}{'classes'} ) ) &&
						       ( isemptyhash( $self->{'CONTENT'}{'webmodules'} ) ) ),
					 'index' => $self->{'HAS_INDEXES'},
				       },
				       $rootdir ) ;

  my $content = join( '',
		      $nav,
		      $self->{'THEME'}->partseparator(),
		      $self->{'THEME'}->title( $self->{'LANG'}->get('I18N_LANG_WEBPAGE',$pagename) ),
		      $self->{'THEME'}->par( $_[0]{'explanation'}{'text'} )
		    ) ;

  $content .= $self->build_common_tag_parts($_[0]{'fields'},$rootdir) ;

  $content .= join( '',
		    $self->{'THEME'}->partseparator(),
		    $nav,
		    $self->{'THEME'}->partseparator(),
		    $self->get_translator_copyright("") ) ;

  $self->{'THEME'}->create_html_body_page( $currentfile,
					   $content,
					   $self->{'LANG'}->get('I18N_LANG_WEBPAGE',$pagename),
					   $rootdir ) ;
}

=pod

=item * addsourcelink()

Adds a link to the source page to the first parameter.
Takes 4 args:

=over

=item * str (string ref)

is the string to update.

=item * root (string)

is the root directory of the generated documentation.

=item * currentfile (string)

is the name of the target file.

=item * srclocation (string)

is the location of the source file

=back

=cut
sub addsourcelink($$$$) {
  my $self = shift ;
  if ( $self->{'SHOWSOURCES'} ) {
    my $lnk ;
    my $key = extract_file_from_location($_[3]) ;
    if ( ! $self->{'SOURCEFILENAMES'}{$key} ) {
      my $base = basename( $key ) ;
      my $dir = dirname( $_[2] ) ;
      my $count = 0 ;
      $lnk = htmlcatfile($dir,"${base}.html") ;
      if ( ! isemptyhash($self->{'SOURCEFILENAMES'}) ) {
        while ( valueinhash( $lnk, $self->{'SOURCEFILENAMES'} ) ) {
          $count ++ ;
          $lnk = htmlcatfile($dir,"${base}_$count.html") ;
        }
      }
      $self->{'SOURCEFILENAMES'}{$key} = $lnk ;
    }
    else {
      $lnk = $self->{'SOURCEFILENAMES'}{$key} ;
    }
    $_[0] = $self->{'THEME'}->addsourcelink( $_[0],
					     htmlcatfile($_[1],$lnk) ) ;
  }
}

=pod

=item * generate_source_files()

Creates sources file of a class of a package.

=cut
sub generate_source_files()  {
  my $self = shift ;

  if ( ! $self->{'SHOWSOURCES'} ) {
    return ;
  }

  my @srcfiles = sort keys %{$self->{'SOURCEFILENAMES'}} ;
  my $i ;
  for( $i=0; $i<=$#srcfiles; $i++) {
    my $srcfile = $srcfiles[$i] ;
    my $currentfile = $self->{'SOURCEFILENAMES'}{$srcfile} ;
    my $rootdir = htmltoroot(htmldirname($currentfile)) ;

    my $prev = "" ;
    if ( $i > 0 ) {
      $prev = htmlcatfile($rootdir,$self->{'SOURCEFILENAMES'}{$srcfiles[$i-1]}) ;
    }

    my $next = "" ;
    if ( $i < $#srcfiles ) {
      $next = htmlcatfile($rootdir,$self->{'SOURCEFILENAMES'}{$srcfiles[$i+1]}) ;
    }

    my $nav = $self->{'THEME'}->get_navigation_bar( htmlcatfile($rootdir,$currentfile),
						    { 'previous' => $prev,
						      'next' => $next,
						      'index' => $self->{'HAS_INDEXES'},
						    },
						    $rootdir ) ;

    my $php_code = readfileastext( $srcfile ) ;

    PhpDocGen::General::Verbose::two( "Highlighting $srcfile..." ) ;

    $self->{'THEME'}->create_html_page( $currentfile,
					join( '',
					      $nav,
					      $self->{'THEME'}->partseparator(),
					      $self->{'THEME'}->title( $self->{'LANG'}->get('I18N_LANG_SOURCE_FILE',
											    basename( $srcfile ) ) ),
					      PhpDocGen::Highlight::PHP::highlight_php( $php_code ),
					      $self->{'THEME'}->partseparator(),
					      $self->get_translator_copyright($rootdir) ),
					$self->{'LANG'}->get('I18N_LANG_SOURCE_FILE',basename($srcfile)),
					$rootdir,
					0 ) ;
  }
}

=pod

=item * output_package()

Creates the documentation for the specified package.
Takes 1 arg:

=over

=item * name (string)

is the name of the package.

=back

=cut
sub output_package($)  {
  my $self = shift ;
  my $kpack = formathashkeyname( $_[0] ) ;
  my $pack = $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ;
  # creates the directory for the package
  my $outdir = $pack ;
  my $realoutdir = htmlpath(htmlcatdir($self->{'TARGET'},$outdir)) ;
  if ( ! -d $realoutdir ) {
    mkdir_rec( $realoutdir )
      or PhpDocGen::General::Error::syserr( "creating package directory $realoutdir: $!\n" ) ;
  }
  my $rootdir = htmltoroot( $pack ) ;


  $self->output_package_frame($pack,$outdir,$rootdir) ;
  $self->output_package_summary($pack,$outdir,$rootdir) ;
  $self->output_package_functions($pack,$outdir,$rootdir) ;
  $self->output_package_constants($pack,$outdir,$rootdir) ;
  $self->output_package_variables($pack,$outdir,$rootdir) ;

  foreach my $kclass (@{$self->{'CONTENT'}{'packages'}{$kpack}{'classes'}}) {
    my $classname = $self->{'CONTENT'}{'classes'}{$kclass}{'this'}{'name'} ;
    if ( $self->{'CONTENT'}{'classes'}{$kclass} ) {
      $self->output_package_class( $classname, $outdir, $rootdir ) ;
    }
    else {
      PhpDocGen::General::Error::syserr( "unable to find the definition of ".
					 "the class $classname\n" ) ;
    }
  }
}

=pod

=item * output_module()

Creates the documentation for the specified webmodule.
Takes 2 args:

=over

=item * module (hash)

is the description of the module.

=item * modules (hash)

contains all the modules

=back

=cut
sub output_module($$)  {
  my $self = shift ;
  # creates the directory for the module
  my $outdir = htmlcatfile($self->{'WEBDOC_DIR'},$_[0]{'name'}) ;
  my $realoutdir = htmlpath(htmlcatdir($self->{'TARGET'},$outdir)) ;
  if ( ! -d $realoutdir ) {
    mkdir_rec( $realoutdir )
      or PhpDocGen::General::Error::syserr( "creating webmodule directory $realoutdir: $!\n" ) ;
  }
  my $rootdir = htmltoroot( $outdir ) ;
  $self->output_module_frame($_[0],$outdir,$rootdir) ;
  $self->output_module_summary($_[0],$_[1],$outdir,$rootdir) ;

  # Generate the pages
  my %allpages = $self->get_all_webpages() ;
  foreach my $page (@{$_[0]->{'pages'}}) {
    my $pagename = htmlcatfile( '/', $_[0]->{'name'}, $page ) ;
    if ( exists $allpages{$pagename} ) {
      $self->output_module_page_summary($allpages{$pagename},\%allpages,$_[0],$outdir,$rootdir) ;
    }
  }
}

#------------------------------------------------------
#
# Hyper-reference support
#
#------------------------------------------------------

=pod

=item * format_ext_hyperref()

Replies an hyper-reference formatted according
to the generator.
Takes 5 args:

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
sub format_ext_hyperref($$$$$)  {
  my $self = shift ;
  confess( 'rootdir must be supplied' ) unless $_[0] ;
  confess( 'package must be supplied' ) unless $_[1] ;
  confess( 'classname must be supplied' ) unless $_[2] ;
  my $filename = htmlcatfile( $_[0], $_[1],
			      $self->{'THEME'}->filename( 'class', $_[2] ) ) ;
  my $comment = $_[4] || '' ;
  if ( $_[3] ) {
    return $self->format_hyperref( $filename."#".$_[3], $comment ) ;
  }
  else {
    return $self->format_hyperref( $filename, $comment ) ;
  }
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
  if ( $_[1] ) {
    my $filename = htmlcatfile($_[0],$self->{'WEBDOC_DIR'},$_[1],
			       $self->{'THEME'}->filename('webmodule'));
    return $self->format_hyperref( $filename, $_[3] ) ;
  }
  elsif( $_[2] ) {
    my $filename = htmlcatfile($_[0],$self->{'WEBDOC_DIR'},
			       $self->{'THEME'}->filename('webpage',$_[2]));
    return $self->format_hyperref( $filename, $_[3] ) ;
  }
  else {
    return "" ;
  }
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
  return $self->{'THEME'}->href($_[0],$_[1]) ;
}

#------------------------------------------------------
#
# Inlined tag epxansion
#
#------------------------------------------------------

=pod

=item * expand_inlinedtag_block()

Translates a tag {@block}.
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
sub expand_inlinedtag_block($$$)  {
  my $self = shift ;
  return "<SPAN>$_[0]</SPAN>" ;
}

=pod

=item * expand_inlinedtag_example_code()

Translates a tag {@example}.
Takes 3 args:

=over

=item * framed (boolean)

indicates if the code must be framed

=item * code (string)

is the content of the tag.

=item * root (string)

is the root directory.

=item * location (string)

is the location of the tag inside the input stream.

=back

=cut
sub expand_inlinedtag_example_code($$$$)  {
  my $self = shift ;
  my $framed = $_[0] ;
  my $code = $_[1] || '' ;
  $code = PhpDocGen::Highlight::PHP::highlight_php( $code ) ;
  if ( $framed ) {
    $code = $self->{'THEME'}->build_array( 1, $code ) ;
  }
  return $code ;
}

#------------------------------------------------------
#
# Main generator functions
#
#------------------------------------------------------

=pod

=item * generate_generalfiles()

Creates the general files.

=cut
sub generate_generalfiles()  {
  my $self = shift ;

  $self->{'HAS_INDEXES'} = $self->output_file_indexes() ;
  $self->output_file_index() ;
  $self->output_file_overview_frame() ;
  $self->output_file_allelements_frame() ;
  $self->output_file_overview_summary() ;
  $self->output_file_overview_tree() ;
}

=pod

=item * generate_packages()

Creates the documentation for the packages.

=cut
sub generate_packages()  {
  my $self = shift ;
  return unless $self->{'GENERATE_PHP_DOC'} ;
  foreach my $kpack ( @{$self->{'SORTED_LISTS'}{'packages'}} ) {
    $self->output_package( $self->{'CONTENT'}{'packages'}{$kpack}{'this'}{'name'} ) ;
  }
}

=pod

=item * generate_modules()

Creates the documentation for the webmodules.

=cut
sub generate_modules()  {
  my $self = shift ;
  return unless $self->{'GENERATE_WEB_DOC'} ;
  my %allmods = $self->get_all_notempty_webmodules() ;
  foreach my $key ( @{$self->{'SORTED_LISTS'}{'modules'}} ) {
    $self->output_module( $allmods{$key},\%allmods ) ;
  }
}

=pod

=item * copy_files()

Copies some files from the phpdocgen distribution directly inside the
HTML documentation tree.

=cut
sub copy_files()  {
  my $self = shift ;
  PhpDocGen::General::Verbose::one( "Copying valid-html401.gif..." ) ;
  PhpDocGen::General::Verbose::three( "\tfrom ".$self->{'PERLSCRIPTDIR'} ) ;
  PhpDocGen::General::Verbose::three( "\tto   ".$self->{'TARGET'} ) ;
  my $from = File::Spec->catfile($self->{'PERLSCRIPTDIR'}, "valid-html401.gif") ;
  copy( $from,
        File::Spec->catfile($self->{'TARGET'},"valid-html401.gif") )
    or PhpDocGen::General::Error::syserr( "$from: $!\n" );
  # Copy theme files
  $self->{'THEME'}->copy_files() ;
}

=pod

=item * generate()

Creates the documentation.

=cut
sub generate()  {
  my $self = shift ;
  $self->create_sorted_lists() ;
  $self->generate_generalfiles() ;
  $self->generate_packages() ;
  $self->generate_source_files() ;
  $self->generate_modules() ;
  $self->copy_files() ;
}

#------------------------------------------------------
#
# Information
#
#------------------------------------------------------

=pod

=item * display_supported_themes()

Display the list of supported themes.
Takes 2 args:

=over

=item * perldir (string)

is the path to the directory where the Perl packages
are stored.

=item * default (string)

is the name of the default theme

=back

=cut
sub display_supported_themes($$) {
  my $path = $_[0] || confess( 'you must specify the pm path' ) ;
  my $default = $_[1] || '' ;
  my @pack = split /\:\:/, File::Spec->catfile($path,__PACKAGE__) ;
  pop @pack ;
  push @pack, "Theme" ;
  foreach my $file ( glob(File::Spec->catfile(@pack, '*') ) ) {
    my $name = basename($file) ;
    if ( $name =~ /^(.+)Theme\.pm$/ ) {
      $name = $1 ;
      print join( '',
		  "$name",
		  ( $default && ( $default eq $name ) ) ?
		  " (default)" : "",
		  "\n" ) ;
    }
  }
}

=pod

=item * display_supported_languages()

Display the list of supported languages.
Takes 2 args:

=over

=item * perldir (string)

is the path to the directory where the Perl packages
are stored.

=item * default (string)

is the name of the default language

=back

=cut
sub display_supported_languages($$) {
  my $path = $_[0] || confess( 'you must specify the pm path' ) ;
  my $default = $_[1] || '' ;
  my @pack = split /\:\:/, File::Spec->catfile($path,__PACKAGE__) ;
  pop @pack ;
  push @pack, "Lang" ;
  foreach my $file ( glob(File::Spec->catfile(@pack, '*') ) ) {
    my $name = basename($file) ;
    if ( $name =~ /^(.+)\.pm$/ ) {
      $name = $1 ;
      print join( '',
		  "$name",
		  ( $default && ( $default eq $name ) ) ?
		  " (default)" : "",
		  "\n" ) ;
    }
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

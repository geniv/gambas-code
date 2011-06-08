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

PhpDocGen::Generator::Html::Theme - A theme for the HTML generator

=head1 SYNOPSYS

use PhpDocGen::Generator::Html::Theme ;

my $gen = PhpDocGen::Generator::Html::Theme->new( phpdocgen,
                                                  target,
                                                  title,
                                                  phpgen,
                                                  webgen ) ;

=head1 DESCRIPTION

PhpDocGen::Generator::Html::Theme is a Perl module, which proposes
a documentation theme for the HTML generator of phpdocgen.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use PhpDocGen::Generator::Html::Theme;

    my $gen = PhpDocGen::Generator::Html::Theme->new( { 'VERSION' => '0.11' },
						      './phpdoc',
						      'Title',
						      1, 1 ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * phpdocgen (hash)

contains some data about phpdocgen.

=item * target (string)

The directory in which the documentation must be put.

=item * title (string)

is the title of the documentation.

=item * phpgen (boolean)

indicates if the PHP doc was generated

=item * webgen (boolean)

indicates if the WEB doc was generated

=item * lang (object ref)

is a reference to the language object.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Html.pm itself.

=over

=cut

package PhpDocGen::Generator::Html::Theme;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;

use Carp ;
use File::Spec ;

use PhpDocGen::General::Verbose ;
use PhpDocGen::General::Error ;
use PhpDocGen::General::HTML ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of theme
my $VERSION = "0.5" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$$$$$)  {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = { 'PHPDOCGEN' => $_[0] || '',
	       'TARGET_DIR' => $_[1] || confess( 'you must supply the target directory' ),
	       'TITLE' => $_[2] || '',
	       'GENERATES_PHP' => $_[3],
	       'GENERATES_WEB' => $_[4],
	       'LANG' => $_[5],
	     } ;

  $self->{'FILENAMES'} = { 'overview-frame' => 'overview-frame.html',
			   'all-elements' => 'allelements-frame.html',
			   'overview' => 'overview-summary.html',
			   'tree' => 'overview-tree.html',
			   'indexes' => 'index-#1.html',
			   'main' => 'index.html',
			   'package-frame' => 'package-frame.html',
			   'module-frame' => 'module-frame.html',
			   'package' => 'package-summary.html',
			   'class' => '#1.html',
			   'webmodule' => 'module-summary.html',
			   'webpage' => '#1.html',
			   'package-functions' => 'package-functions.html',
			   'package-constants' => 'package-constants.html',
			   'package-variables' => 'package-variables.html',
			 } ;

  $self->{'FRAMES'} = { 'overview-frame' => 'packageListFrame',
			'all-elements' => 'packageFrame',
			'overview' => 'classFrame',
			'tree' => 'classFrame',
			'indexes' => 'classFrame',
			'main' => '_top',
			'package-frame' => 'packageFrame',
			'module-frame' => 'packageFrame',
			'package' => 'classFrame',
			'class' => 'classFrame',
			'webmodule' => 'classFrame',
			'webpage' => 'classFrame',
			'package-functions' => 'classFrame',
			'package-constants' => 'classFrame',
			'package-variables' => 'classFrame',
		      } ;

  bless( $self, $class );
  return $self;
}

=pod

=item * copy_files()

Copies some files from the phpdocgen distribution directly inside the
HTML documentation tree.

=cut
sub copy_files()  {
  my $self = shift ;
}

#------------------------------------------------------
#
# Filename API
#
#------------------------------------------------------

=pod

=item * ext_href()

Replies a hyperlink according to the parameters
Takes 3 args:

=over

=item * section (string)

is the id of the section.

=item * label (string)

is the label of the hyperlink

=item * rootdir (string)

is the path to the root directory.

=back

=cut
sub ext_href($$$)  {
  my $self = shift ;
  my $section = shift || confess( 'you must supply the section id' ) ;
  my $label = shift || '' ;
  my $rootdir = shift || confess( 'you must supply the root directory' ) ;
  return $self->href( htmlcatfile($rootdir,$self->filename($section,@_)),
                      $label,
                      $self->browserframe($section) ) ;
}

=pod

=item * ext_wt_href()

Replies a hyperlink according to the parameters (without target)
Takes 3 args:

=over

=item * section (string)

is the id of the section.

=item * label (string)

is the label of the hyperlink

=item * rootdir (string)

is the path to the root directory.

=back

=cut
sub ext_wt_href($$$)  {
  my $self = shift ;
  my $section = shift || confess( 'you must supply the section id' ) ;
  my $label = shift || '' ;
  my $rootdir = shift || confess( 'you must supply the root directory' ) ;
  return $self->href( htmlcatfile($rootdir,$self->filename($section,@_)),
                      $label ) ;
}

=pod

=item * filename()

Replies the filename of the specified section.
Takes 1 arg:

=over

=item * section (string)

is the name of the section.

=back

=cut
sub filename($)  {
  my $self = shift ;
  my $section = $_[0] || '' ;
  my $fn = $self->{'FILENAMES'}{$section} ;
  confess( "filename not found for '$section'" ) unless $fn ;
  my $i = 1 ;
  while ( $fn =~ /\#\Q$i\E/ ) {
    my $val = (defined($_[$i])) ? $_[$i] : '' ;
    $fn =~ s/\#$i/$val/g ;
    $i ++ ;
  }
  return $fn ;
}

=pod

=item * browserframe()

Replies the frame used for the specified section.
Takes 1 arg:

=over

=item * section (string)

is the name of the section.

=back

=cut
sub browserframe($)  {
  my $self = shift ;
  my $section = $_[0] || '' ;
  my $fr = $self->{'FRAMES'}{$section} ;
  confess( "frame not found for '$section'" ) unless $fr ;
  return $fr ;
}

#------------------------------------------------------
#
# Page API
#
#------------------------------------------------------

=pod

=item * get_html_index()

Replies the content of the main index.html
Takes 1 arg:

=over

=item * rootdir (string)

is the path to the root directory.

=back

=cut
sub get_html_index($) {
  my $self = shift ;
  my $rootdir = $_[0] || confess( 'you must supply the root directory' ) ;
  return join( '',
	       "<FRAMESET cols=\"20%,80%\">\n",
	       "<FRAMESET rows=\"30%,70%\">\n",
	       "<FRAME src=\"",
	       htmlcatfile($rootdir,$self->filename('overview-frame')),
	       "\" name=\"",
	       $self->browserframe('overview-frame'),
	       "\">\n<FRAME src=\"",
	       htmlcatfile($rootdir,$self->filename('all-elements')),
	       "\" name=\"",
	       $self->browserframe('all-elements'),
	       "\">\n</FRAMESET>\n",
	       "<FRAME src=\"",
	       htmlcatfile($rootdir,$self->filename('overview')),
	       "\" name=\"",
	       $self->browserframe('overview'),
	       "\">\n<NOFRAMES>\n<H2>Frame Alert</H2>\n",
	       $self->par( "<P>".
			   $self->{'LANG'}->get('I18N_LANG_FRAME_MESSAGE',
						$self->href(htmlcatfile($rootdir,$self->filename('overview')),
							    "Non-frame version"),
						$self->get_html_validation_link($rootdir))),
	       "</NOFRAMES>\n",
	       "</FRAMESET>\n" ) ;
}

=pod

=item * create_html_page()

Creates an HTML page without a <BODY>.
Takes 3 args:

=over

=item * filename (string)

is the name of the file in which the page
must be created.

=item * content (string)

is the content of the page.

=item * title (string)

is the title of the page.

=item * rootdir (string)

is the path to the root directory.

=item * frameset (boolean)

must be true if the generated page must respect the w3c frameset definition,
otherwhise it will respect the w3c transitional definition

=back

=cut
sub create_html_page($$$$$)  {
  my $self = shift ;
  my $rootdir = $_[3] || confess( 'you must supply the root directory' ) ;
  my $filename = File::Spec->catfile( $self->{'TARGET_DIR'}, htmlpath($_[0]) ) ;
  PhpDocGen::General::Verbose::two( "Writing $filename..." ) ;
  local *OUTPUTFILE ;
  open( OUTPUTFILE, "> $filename" )
    or PhpDocGen::General::Error::syserr( "$filename: $!\n" );
  my $header ;
  if ( $_[4] ) {
    $header = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Frameset//EN\" \"http://www.w3.org/TR/REC-html40/frameset.dtd\">" ;
  }
  else {
    $header = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">" ;
  }
  print OUTPUTFILE join( '',
  		   	 $header,
			 "\n\n<!-- Generated by phpdocgen ".$self->{'PHPDOCGEN'}{'VERSION'},
			 " on ",
			 "".localtime(),
			 " -->\n\n",
  		  	 "<HTML>\n<HEAD>\n<TITLE>",
			 $_[2],
			 "</TITLE>\n",
			 "<META http-equiv=\"Content-Type\" ",
			 "content=\"text/html; charset=ISO-8859-1\">\n",
			 $self->get_html_header($rootdir),
			 "</HEAD>\n",
			 $_[1],
			 "</HTML>" ) ;
  close( OUTPUTFILE ) ;
}

=pod

=item * get_html_header()

Replies the HTML header of each page.
Takes 1 arg:

=over

=item * rootdir (string)

is the path to the root directory

=back

=cut
sub get_html_header($)  {
  my $self = shift ;
  return '' ;
}

=pod

=item * create_html_body_page()

Creates an HTML page with a <BODY>.
Takes 3 args:

=over

=item * filename (string)

is the name of the file in which the page
must be created.

=item * content (string)

is the content of the page.

=item * title (string)

is the title of the page.

=item * rootdir (string)

is the path to the root directory.

=back

=cut
sub create_html_body_page($$$$)  {
  my $self = shift ;
  $self->create_html_page( $_[0],
	       		   join( '',
				 "<BODY",
				 ( $self->{'BACKGROUND_COLOR'} ?
				   " BGCOLOR=\"" .
				   $self->{'BACKGROUND_COLOR'} .
				   "\"" : '' ),
				 ">\n$_[1]\n</BODY>\n" ),
			   $_[2],
			   $_[3],
			   0 ) ;
}

=pod

=item * get_html_validation_link()

Replies a HTML code that contains the HTML validation icon.

=item * rootdir (string)

is the rootdir of the documentation

=back

=cut
sub get_html_validation_link($)  {
  my $self = shift ;
  my $rootdir = $_[0] || confess( "the rootdir must be supplied" ) ;
  return join( '',
	       "<P ALIGN=\"right\">\n",
	       "<A HREF=\"http://validator.w3.org/check/referer\">",
	       "<IMG BORDER=\"0\" SRC=\"".htmlcatfile($rootdir,"valid-html401.gif"),
	       "\" ",
	       "ALT=\"Valid HTML 4.01!\" HEIGHT=\"31\" WIDTH=\"88\">",
	       "</A></P>\n" ) ;
}

#------------------------------------------------------
#
# Paragraph API
#
#------------------------------------------------------

=pod

=item * frame_subpart()

Replies a subpart of a frame
Takes 3 args:

=over

=item * title (string)

is the title of the part.

=item * text (array)

is the content of the frame.

=item * rootdir (string)

is the path to the root directory.

=back

=cut
sub frame_subpart($$$)  {
  my $self = shift ;
  confess( 'you must overwrite this method' ) ;
}

=pod

=item * frame_window()

Replies a frame
Takes 2 args:

=over

=item * title (string)

is the title of the frame.

=item * text (string)

is the content of the frame.

=back

=cut
sub frame_window($$)  {
  my $self = shift ;
  confess( 'you must overwrite this method' ) ;
}

=pod

=item * keyword()

Formats a keyword
Takes 1 arg:

=over

=item * text (string)

=back

=cut
sub keyword($) {
  my $self = shift ;
  my $text = $_[0] || confess( 'you must specify the text' ) ;
  return $text ;
}

=pod

=item * code()

Formats a string that contains source code
Takes 1 arg:

=over

=item * text (string)

=back

=cut
sub code($) {
  my $self = shift ;
  my $text = $_[0] || confess( 'you must specify the text' ) ;
  return "<code>$text</code>" ;
}

=pod

=item * partseparator()

Replies a part separator.

=cut
sub partseparator($) {
  my $self = shift ;
  return "<HR>\n" ;
}

=pod

=item * title()

Formats a page title
Takes 2 args:

=over

=item * text (string)

=item * text_before (optional boolean)

indicates if some text are before this title

=back

=cut
sub title($) {
  my $self = shift ;
  my $text = $_[0] || confess( 'you must specify the text' ) ;
  return
    ($_[1] ? $self->partseparator() : '') .
      "<center><h2>$text</h2></center>\n\n" ;
}

=pod

=item * classtitle()

Formats a title for a class page
Takes 2 args:

=over

=item * package (string)

is the package of the class

=item * class (string)

indicates the name of the class

=back

=cut
sub classtitle($$) {
  my $self = shift ;
  my $package = $_[0] || confess( 'you must specify the package name' ) ;
  my $class = $_[1] || confess( 'you must specify the class name' ) ;
  return join( '',
	       "<H2><FONT SIZE=\"-1\">$package</FONT><BR>\n",
	       $self->{'LANG'}->get('I18N_LANG_CLASS_UPPER',$class),
	       "</H2>\n\n" ) ;
}

=pod

=item * subtitle()

Formats a page subtitle
Takes 1 arg:

=over

=item * text (string)

=item * text_before (optional boolean)

indicates if some text are before this title

=back

=cut
sub subtitle($) {
  my $self = shift ;
  my $text = $_[0] || confess( 'you must specify the text' ) ;
  return
    ($_[1] ? "<hr>\n" : '').
      "<h2>$text</h2>\n" ;
}

=pod

=item * strong()

Formats a keyword
Takes 2 args:

=over

=item * text (string)

=back

=cut
sub strong($) {
  my $self = shift ;
  my $text = $_[0] || confess( 'you must specify the text' ) ;
  return "<b>$text</b>" ;
}

=pod

=item * href()

Replies a hyperlink.
Takes 3 args:

=over

=item * url (string)

is the URL to link to

=item * label (string)

is the label of the hyperlink

=item * target (optional string)

is the frame target.

=back

=cut
sub href($$) {
  my $self = shift ;
  my $url = $_[0] || confess( 'you must specify the URL' ) ;
  my $label = $_[1] || confess( 'you must specify the label' ) ;
  return join( '',
	       "<A HREF=\"",
	       $url,
	       "\"",
	       ( $_[2] ? " target=\"$_[2]\"" : "" ),
	       ">",
	       $label,
	       "</A>" ) ;
}

=pod

=item * addsourcelink()

Replies a string that corresponds to the first parameter in which
a link to the source code page was added.
Takes 1 arg:

=over

=item * text (string)

=item * url (string)

=back

=cut
sub addsourcelink($$) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  my $url = $_[1] || confess( 'you must supply the URL to the source code' ) ;
  return join( '',
               $text,
               "&nbsp;",
               $self->small( "(".
			     $self->href( $url,
					  $self->{'LANG'}->get('I18N_LANG_SOURCE') ).
			     ")" ) ) ;
}

=pod

=item * small()

Replies a text with a small size.
Takes 1 arg:

=over

=item * text (string)

=back

=cut
sub small($) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  return join( '',
	       "<FONT SIZE=\"-1\">",
	       $text,
	       "</FONT>\n" ) ;
}

=pod

=item * tiny()

Replies a text with a tiny size.
Takes 1 arg:

=over

=item * text (string)

=back

=cut
sub tiny($) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  return join( '',
	       "<FONT SIZE=\"-2\">",
	       $text,
	       "</FONT>\n" ) ;
}

=pod

=item * par()

Replies a paragraph.
Takes 1 arg:

=over

=item * text (string)

=back

=cut
sub par($) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  return join( '',
	       "<P>",
	       $text,
	       "</P>\n" ) ;
}

=pod

=item * get_tree_node()

Replues the HTML string for the specified tree.
a list.
Takes 2 args:

=over

=item * node (string)

is the string that is the root of the tree.

=item * subs (string)

is an HTML string that describes the children.

=item * rootdir (string)

is the path to the root directory.

=back

=cut
sub get_tree_node($$$) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  my $sub = $_[1] || '' ;
  $sub = "<ul>$sub</ul>" ;
  if ( $text ) {
    return "<li type=\"circle\">".$text.$sub."</li>\n" ;
  }
  else {
    return "$sub\n" ;
  }
}

=pod

=item * get_tree_leaf()

Replies a line of a tree which will be displayed inside
a list.
Takes 1 args:

=over

=item * node (string)

is the string that is the root of the tree.

=item * rootdir (string)

is the path to the root directory.

=back

=cut
sub get_tree_leaf($$) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  return join( '',
               "<li type=\"circle\">",
               $text,
               "</li>\n" ) ;
}

=pod

=item * build_linked_tree()

Creates a tree iwth links between nodes.
Takes 1 arg:

=over

=item * tree (array)

is the tree

=back

=cut
sub build_linked_tree($$)  {
  my $self = shift ;
  my $tree = $_[0] || confess( "you must supply the tree" ) ;
  my $content = "" ;
  if ( $#{$tree} >= 0 ) {
    $content = "<PRE>\n" ;
    my $indent = "" ;
    foreach my $class (@{$tree}) {
      $content .= $indent ;
      if ( $indent ) {
	$content .= "|\n$indent+--" ;
	$indent .= "   " ;
      }
      $class =~ s/<!--.*?-->//g ;
      $content .= "$class\n" ;
      $indent .= "  " ;
    }
    $content .= "</PRE>\n" ;
  }
  return $content ;
}

=pod

=item * get_navigation_bar()

Replies the navigation bar.
Takes 3 args:

=over

=item * url (string)

is the url of the generated page.

=item * params (hash ref)

is a set of parameters used to generate the bar.

=item * root (string)

is the root directory for the generated documentation.

=back

=cut
sub get_navigation_bar($$$)  {
  my $self = shift ;
  confess( 'you must overwrite this method' ) ;
}

=pod

=item * build_detail_section_title()

Replies title of an detail section.
Takes 2 args:

=over

=item * title (string)

is the title of the section.

=item * label (string)

is the label of the title bar.

=back

=cut
sub build_detail_section_title($$)  {
  my $self = shift ;
  confess( 'you must overwrite this method' ) ;
}

=pod

=item * build_class_detail()

Replies the detail for a class.
Takes 3 args:

=over

=item * classname (string)

is the name of the class

=item * extends (string)

is the name of extended class.

=item * explanation (string)

is the description of the function.

=item * details (string)

contains some details on this function.

=back

=cut
sub build_class_detail($$$$)  {
  my $self = shift ;
  confess( 'you must overwrite this method' ) ;
}

=pod

=item * build_function_detail()

Replies the detail for a function.
Takes 5 args:

=over

=item * key_name (string)

is the keyname of the function.

=item * name (string)

is the name of the function.

=item * signature (string)

is the signature of the function.

=item * explanation (string)

is the description of the function.

=item * details (string)

contains some details on this function.

=back

=cut
sub build_function_detail($$$$)  {
  my $self = shift ;
  confess( 'you must overwrite this method' ) ;
}

=pod

=item * build_detail_part()

Replies a detail part.
Takes 3 args:

=over

=item * title (string)

is the title of the section.

=item * separator (string)

is the separator of the elements.

=item * elements (array ref)

is the whole of the elements.

=back

=cut
sub build_detail_part($$$)  {
  my $self = shift ;
  confess( 'you must overwrite this method' ) ;
}

#------------------------------------------------------
#
# Array API
#
#------------------------------------------------------

=pod

=item * build_array()

Replies an array.
Takes at least 2 args:

=over

=item * cols (integer)

is the number of cols

=item * cells (strings)

is the content of the array.

=back

=cut
sub build_array($$)  {
  my $self = shift ;
  my $cols = shift || 1 ;
  if ( ( ! $cols ) || ( $cols <= 0 ) ) {
    $cols = 1 ;
  }
  my $i = 0 ;
  my $content = join( '',
               	      "<DIV><TABLE WIDTH=\"100%\" BORDER=1 CELLPADDING=3 CELLSPACING=0><TR>" ) ;
  foreach my $cell ( @_ ) {
    if ( $i >= $cols ) {
      $content .= "</TR>\n<TR>" ;
      $i = 0 ;
    }
    $content .= "<TD>".$cell."</TD>\n" ;
    $i++ ;
  }
  $content .= "</TR></TABLE></DIV>\n" ;
  return $content ;
}

=pod

=item * build_onecolumn_array()

Replies an one-column array.
Takes 2 args:

=over

=item * title (string)

is the title of the array

=item * cells (array ref)

is the content of the returned cells.

=back

=cut
sub build_onecolumn_array($$)  {
  my $self = shift ;
  confess( 'you must overwrite this method' ) ;
}

=pod

=item * build_twocolumn_array()

Replies an two-column array.
Takes 2 args:

=over

=item * title (string)

is the title of the array

=item * cells (array ref)

is the content of the returned cells.

=back

=cut
sub build_twocolumn_array($$)  {
  my $self = shift ;
  confess( 'you must overwrite this method' ) ;
}

=pod

=item * build_small_array()

Replies an small one-column array.
Takes 2 args:

=over

=item * title (string)

is the title of the array

=item * cells (array ref)

is the content of the returned cells.

=back

=cut
sub build_small_array($$)  {
  my $self = shift ;
  confess( 'you must overwrite this method' ) ;
}

=pod

=item * build_tiny_array()

Replies a tiny one-column array.
Takes 2 args:

=over

=item * title (string)

is the title of the array

=item * cells (array ref)

is the content of the returned cells.

=back

=cut
sub build_tiny_array($$)  {
  my $self = shift ;
  confess( 'you must overwrite this method' ) ;
}

=pod

=item * build_threecolumn_array()

Replies an two-column array.
Takes 3 args:

=over

=item * title (string)

is the title of the array

=item * cells (array ref)

is the content of the returned cells.

=item * anchor (string)

is the name of the anchor.

=back

=cut
sub build_threecolumn_array($$$)  {
  my $self = shift ;
  confess( 'you must overwrite this method' ) ;
}


#------------------------------------------------------
#
# Index API
#
#------------------------------------------------------

=pod

=item * format_index_page()

Replies a formatted page for the index.
Takes 3 args:

=over

=item * letterlist (string)

is the list of letters of the index.

=item * letter (string)

is the current letter.

=item * content (array ref)

is the content of the page.

=back

=cut
sub format_index_page($$$)  {
  my $self = shift ;
  my $letterlist = $_[0] || '' ;
  my $letter = $_[1] || confess( 'you must supply the index letter for this page' ) ;

  my $content = join( '',
		      ( $letterlist ?
			$letterlist.$self->partseparator() : '' ),
		      "<H2>",
		      uc($letter),
		      "</H2>\n",
		      "<DL>" ) ;

  foreach my $entry (@{$_[2]}) {
    $content .= join( '',
		      "<DT>",
		      $entry->{'link'},
		      " - ",
		      $entry->{'type'},
		      "</DT><DD>",
		      $entry->{'explanation'},
		      "&nbsp;</DD>\n" ) ;
  }

  $content .= join( '',
		    "</DL>",
		    ( $letterlist ?
		      $self->partseparator().$letterlist : '' ) ) ;

  return $content ;
}

#------------------------------------------------------
#
# Language API
#
#------------------------------------------------------

=pod

=item * addLang()

adds some language definitions according to the current language.
Takes 1 arg:

=over

=item * defs (hash ref)

is the list of language definitions.

=back

=cut
sub addLang($)  {
  my $self = shift ;
  my $name = $self->{'LANG'}->getname() ;
  if ( ! exists $_[0]->{$name} ) {
    if ( exists $_[0]->{'English'} ) {
      $name = 'English' ;
    }
    else {
      PhpDocGen::General::Error::syswarm( "the theme does not support the language '$name'" ) ;
    }
  }
  foreach my $key ( keys %{$_[0]->{'English'}} ) {
    $self->{'LANG'}->{'defs'}{$key} = $_[0]->{'English'}{$key} ;
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

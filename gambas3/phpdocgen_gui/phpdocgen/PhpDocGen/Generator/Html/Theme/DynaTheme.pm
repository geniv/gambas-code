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

PhpDocGen::Generator::Html::Theme::DynaTheme - A theme for the HTML generator

=head1 SYNOPSYS

use PhpDocGen::Generator::Html::Theme::DynaTheme ;

my $gen = PhpDocGen::Generator::Html::Theme::DynaTheme->new( phpdocgen,
                                                         target,
                                                         title,
                                                         phpgen,
                                                         webgen ) ;

=head1 DESCRIPTION

PhpDocGen::Generator::Html::Theme::DynaTheme is a Perl module, which proposes
a documentation theme for the HTML generator of phpdocgen. This theme generates
something like javadoc.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use PhpDocGen::Generator::Html::Theme::DynaTheme;

    my $gen = PhpDocGen::Generator::Html::Theme::DynaTheme->new( { 'VERSION' => '0.11' },
								 "./phpdoc",
								 "Title",
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

package PhpDocGen::Generator::Html::Theme::DynaTheme;

@ISA = ('PhpDocGen::Generator::Html::Theme');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;

use Carp ;
use File::Copy ;

use PhpDocGen::Generator::Html::Theme ;
use PhpDocGen::General::Verbose ;
use PhpDocGen::General::Error ;
use PhpDocGen::General::HTML ;
use PhpDocGen::General::Misc ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of Dyna theme
my $VERSION = "0.6" ;

my %LANG_DEFS = ( 'English' => { 'I18N_LANG_THEME_SUMMARY_BAR' => "SUMMARY: &nbsp;#1&nbsp;|&nbsp;#2&nbsp;|&nbsp;#3",
				 'I18N_LANG_THEME_DETAIL_BAR' => "DETAIL: &nbsp;#1&nbsp;|&nbsp;#2&nbsp;|&nbsp;#3",
				 'I18N_LANG_THEME_TREE_ROOT' => "Root",
			       },
		  'French' => { 'I18N_LANG_THEME_SUMMARY_BAR' => "R&Eacute;SUM&Eacute;: &nbsp;#1&nbsp;|&nbsp;#2&nbsp;|&nbsp;#3",
				'I18N_LANG_THEME_DETAIL_BAR' => "DETAIL: &nbsp;#1&nbsp;|&nbsp;#2&nbsp;|&nbsp;#3",
				'I18N_LANG_THEME_TREE_ROOT' => "Racine",
			      },
		) ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$$$$$$)  {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = $class->SUPER::new( @_ ) ;

  $self->{'COPY_FILES'} = [ 'stylesheet.css',
			    'minus.gif',
			    'plus.gif',
			    'child.gif',
			    'lastchild.gif',
			    'samechild.gif',
			    'emptychild.gif',
			  ] ;

  $self->{'FRAME_TREE_ID_COUNT'} = 0 ;
  $self->{'TREE_ID_COUNT'} = 0 ;

  $self->addLang( \%LANG_DEFS ) ;

  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Main structure
#
#------------------------------------------------------

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
  my $rootdir = $_[0] || confess( 'you must supply the root directory' ) ;
  return join( '',
               "<link REL ='stylesheet' TYPE='text/css' HREF='",
               htmlcatfile($rootdir,"stylesheet.css"),
               "' TITLE='Style'>\n",

               # JavaScript
               "<script language='JavaScript1.2'>\n<!--\n",
               "function swaptreecontent(elID) {\n",
	       "  b = document.getElementById(elID).innerHTML;\n",
	       "  a = document.getElementById(elID + \"off__\").innerHTML;\n",
	       "  if (a.length == 0) {",
	       "    document.getElementById(elID).innerHTML = \"\";\n",
               "  } else {\n",
	       "    document.getElementById(elID).innerHTML = a;\n",
               "  }\n",
	       "  document.getElementById(elID + \"off__\").innerHTML = b;\n",
	       "}\n\n",
               "function swaptreeicon(elID) {\n",
               "  a = document.getElementById(elID + \"plusminus\").src;\n",
	       "  if (a.indexOf(\"minus.gif\") != -1) a = \"",
               htmlcatfile($rootdir,"plus.gif"),
               "\";\n",
	       "  else a = \"",
               htmlcatfile($rootdir,"minus.gif"),
               "\";\n",
	       "  document.getElementById(elID + \"plusminus\").src = a;\n",
	       "}\n\n",
               "function swaptree(elID) {\n",
	       "  swaptreecontent(elID);\n",
	       "  swaptreeicon(elID);\n",
               "}\n\n",
               "function swaptree2(elID1,elID2) {\n",
	       "  swaptreecontent(elID1);\n",
	       "  swaptreecontent(elID2);\n",
	       "  swaptreeicon(elID1);\n",
               "}\n",
               "//-->\n</script>\n" ) ;
}


#------------------------------------------------------
#
# Structural element API
#
#------------------------------------------------------

=pod

=item * get_tree()

Creates a tree.
Takes 2 args:

=over

=item * tree (hash)

is the tree

=item * rootdir (string)

is the path to the root directory

=back

=cut
sub get_tree($$)  {
  my $self = shift ;
  my $tree = $_[0] || confess( "you must supply the tree" ) ;
  my $rootdir = $_[1] || confess( 'you must supply the root directory' ) ;
  $tree = { $self->{'LANG'}->get('I18N_LANG_THEME_TREE_ROOT') => $tree } ;
  return $self->__get_tree__( $tree, $rootdir ) ;
}

sub __get_tree__($$) {
  my $self = shift ;
  my $rootdir = $_[1] || confess( 'you must supply the root directory' ) ;
  my ($prevs,$lines,$max) = $self->__get_tree_rec__(@_) ;
  my $content = '' ;

  foreach my $prev (@{$prevs}) {
    $content .= join( '',
		      "<DIV id=\"",
		      $prev,
		      "off__\" style=\"visibility : hidden; position: absolute\"></DIV>\n" ) ;
  }

  my $header = "<TABLE border='0' cellspacing='0' cellpadding='0' cols='$max' width='100%'>\n" ;
  my $footer = "</TABLE>\n" ;

  $content .=  $header ;

  foreach my $line (@{$lines}) {
    my $iddata = pop @{$line} ;
    my $count = $max ;
    $content .= "<TR height='17'>" ;
    for(my $i=0; $i<=$#{$line}; $i++) {
      my $cell = $line->[$i] ;
      if ($cell eq '[-]') {
	confess( 'empty id when collapsable node' ) unless $iddata->{'open'} ;
	$count -- ;
	$content .= join( '',
			  "<TD valign='middle' align='left' width='11'>",
			  $self->href( "javascript:swaptree('".$iddata->{'open'}."')",
				       "<img src=\"".
				       htmlcatfile($rootdir,"minus.gif").
				       "\" alt=\"-\" ".
				       "id=\"".$iddata->{'open'}."plusminus\" width=\"11\" ".
				       "height=\"11\" border=\"0\">" ),
			  "</TD>" ) ;
      }
      elsif ($cell eq '[ ]') {
	$count -- ;
	$content .= join( '',
			  "<TD valign='top' align='left' width='11'>",
			  "<IMG src=\"",
			  htmlcatfile($rootdir,"emptychild.gif"),
			  "\" alt=\" \" width=\"11\" ",
			  "height=\"17\" border=\"0\">",
			  "</TD>" ) ;
      }
      elsif ($cell eq '[+]') {
	$count -- ;
	$content .= join( '',
			  "<TD valign='top' align='left' width='11'>",
			  "<IMG src=\"",
			  htmlcatfile($rootdir,"child.gif"),
			  "\" alt=\"+\" width=\"11\" ",
			  "height=\"17\" border=\"0\">",
			  "</TD>" ) ;
      }
      elsif ($cell eq '[|]') {
	$count -- ;
	$content .= join( '',
			  "<TD valign='top' align='left'>",
			  "<IMG src=\"",
			  htmlcatfile($rootdir,"samechild.gif"),
			  "\" alt=\"|\" width=\"11\" ",
			  "height=\"17\" border=\"0\">",
			  "</TD>" ) ;
      }
      elsif ($cell eq '[\\]') {
	$count -- ;
	$content .= join( '',
			  "<TD valign='top' align='left' width='11'>",
			  "<IMG src=\"",
			  htmlcatfile($rootdir,"lastchild.gif"),
			  "\" alt=\"\\\" width=\"11\" ",
			  "height=\"17\" border=\"0\">",
			  "</TD>" ) ;
      }
      elsif ( $cell ) {
	$content .= join( '',
			  "<TD colspan='$count' width='100%' valign='middle' align='left' class='TreeText'>",
			  $cell,
			  "</TD>" ) ;
      }
    }
    $content .= "</TR>\n" ;
    if ( ! isemptyarray( $iddata->{'closes'}) ) {
      for(my $i=0; $i<@{$iddata->{'closes'}}; $i++) {
	$content .= "$footer</DIV>\n$header" ;
      }
    }
    if ( $iddata->{'open'} ) {
      $content .= "$footer<DIV id=\"".$iddata->{'open'}."\">$header" ;
    }
  }

  return $content.$footer ;
}

sub __get_tree_rec__($$) {
  my $self = shift ;
  my $rootdir = $_[1] || confess( 'you must supply the root directory' ) ;
  my @content = () ;
  my @prev = () ;
  my $max = 0 ;

  if ( ! isemptyhash( $_[0] ) ) {

    my @keys = sort { my $aa = strip_html_tags($a) ;
		      my $bb = strip_html_tags($b) ;
		      return 0 if ( $aa eq $bb ) ;
		      return -1 if ( $aa lt $bb ) ;
		      return 1 ;
		    } keys %{$_[0]} ;

    for(my $i=0; $i<=$#keys; $i++) {
      my $nodename = $keys[$i] ;
      my $oid = '' ;

      # Gets the children
      my ($child_prev,$child_content,$child_max) = $self->__get_tree_rec__( $_[0]->{$nodename}, $rootdir ) ;

      # Computes the collpasing icon
      my $collaps = '' ;
      if ( ! isemptyarray( $child_content ) ) {
	$collaps = '[-]' ;
	# Computes the tags just before the tree
	# This tag permits to undisplay the $id area
	$self->{'FRAME_TREE_ID_COUNT'} ++ ;
	$oid = "treeoverviewid".$self->{'FRAME_TREE_ID_COUNT'} ;
	push @prev, $oid ;
      }
      push @prev, @{$child_prev} ;

      # Adds this node to the array
      push @content, [ "$collaps", "&nbsp;$nodename", { 'open' => $oid,
							'closes' => [] } ] ;
      $max = 2 ;

      # Adds the children
      my @subcontent = () ;
      my $found = 0 ;
      for(my $j=$#{$child_content}; $j>=0; $j--) {
	my $next = $child_content->[$j][0] ;
	my $icon = '[ ]' ;
	if ( $found ) {
	  if ( ( ! $next ) || ( $next eq '[-]' ) ) {
	    $icon = '[+]' ;
	  }
	  else {
	    $icon = '[|]' ;
	  }
	}
	elsif ( ( ! $next ) || ( $next eq '[-]' ) ) {
	  $found = 1 ;
	  $icon = '[\\]' ;
	}
	unshift @subcontent, [ $icon, @{$child_content->[$j]} ] ;
	if ( $max < (@{$child_content->[$j]}-1) ) {
	  $max = @{$child_content->[$j]}-1 ;
	}
      }
      push @content, @subcontent ;
      if ( $oid ) {
	push( @{$content[$#content]->[$#{$content[$#content]}]->{'closes'}},
	      $oid ) ;
      }
    }

  }

  return (\@prev,\@content,$max) ;
}

=pod

=item * build_linked_tree()

Creates a tree with links between nodes.
Takes 1 arg:

=over

=item * tree (array)

is the tree

=item * rootdir (string)

is the path to the root directory

=back

=cut
sub build_linked_tree($$)  {
  my $self = shift ;
  my $tree = $_[0] || confess( "you must supply the tree" ) ;
  my $rootdir = $_[1] || confess( 'you must supply the root directory' ) ;
  my $content = "" ;
  if ( $#{$tree} >= 0 ) {
    my $end = '' ;
    for(my $i=0; $i<=$#{$tree}; $i++ ) {
      my $class = $tree->[$i] ;

      $self->{'FRAME_TREE_ID_COUNT'} ++ ;
      my $id1 = "classtreeid".$self->{'FRAME_TREE_ID_COUNT'} ;
      $self->{'FRAME_TREE_ID_COUNT'} ++ ;
      my $id2 = "classtreeid".$self->{'FRAME_TREE_ID_COUNT'} ;

      $content .= join( '',
			"<DIV id=\"",
			$id1,
			"off__\" style=\"visibility : hidden; position: absolute\"></DIV>\n",
			"<DIV id=\"",
			$id2,
			"off__\" style=\"visibility : hidden; position: absolute\"></DIV>\n",

			"<TABLE border=0 cellspacing=2 cellpadding=0>",
			"<TR><TD>" ) ;

      if ( $i < $#{$tree} ) {
	$content .= join( '',
			  $self->href( "javascript:swaptree2('".$id1."','".$id2."')",
				       "<img src=\"".
				       htmlcatfile($rootdir,"minus.gif").
				       "\" alt=\"-\" ".
				       "id=\"".$id1."plusminus\" width=\"11\" ".
				       "height=\"11\" border=\"0\">" ),
			  "</TD><TD>&nbsp;" ) ;
      }

      $content .= join( '',
			$class,
			"</TD></TR>",
			"<TR><TD valign='top' align='right'>" ) ;

      if ( $i < $#{$tree} ) {
	$content .= join( '',
			  "<DIV id=\"",
			  $id2,
			  "\">",
			  "<IMG src=\"",
			  htmlcatfile($rootdir,"lastchild.gif"),
			  "\" alt=\"-\" width=\"11\" ",
			  "height=\"17\" border=\"0\">",
			  "</DIV>" ) ;
      }

      $content .= join( '',
			"</TD><TD class='TreeText' valign='middle' align='left'><DIV id=\"",
			$id1,
			"\">") ;

      $end .= "</DIV></TD></TR></TABLE>" ;

    }

    $content .= $end ;

  }
  return $content ;
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
  return join( '',
	       "<A NAME=\"",
               $_[1] || '',
               "\"></A>",
	       "<P><TABLE BORDER='1' CELLPADDING='3' CELLSPACING='0' WIDTH='100%'>",
               "<THEAD><TR><TD CLASS='largetabletitle'>",
               $_[0] || '',
               "</TD></TR></THEAD></TABLE><BR>\n" ) ;
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
  my $classname = $_[0] || confess( 'you must supply the classname' ) ;
  my $extends = $_[1] || '' ;
  my $explanation = $_[2] || '' ;
  my $details = $_[3] || '' ;
  return join( '',
               "<DL>\n<DT>",
	       $self->{'LANG'}->get('I18N_LANG_CLASS'),
	       " <B>$classname</B>",
               ( $extends ? "<DT>".
		 $self->{'LANG'}->get('I18N_LANG_EXTENDS').
		 " $extends</DL>\n" : '' ),
	       "<P>",
               $explanation,
	       "</P>\n",
               $details,
	       "</DL>\n" ) ;
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
  my $kname = $_[0] || confess( 'you must supply the keyname' ) ;
  my $name = $_[1] || confess( 'you must supply the name' ) ;
  my $signature = $_[2] || confess( 'you must supply the signature' ) ;
  my $explanation = $_[3] || confess( 'you must supply the explanation' ) ;
  my $details = $_[4] || '' ;
  return join( '',
	       "<A NAME=\"",
               $kname,
               "\"></A><H3>",
               $name,
               "</H3>\n<PRE>\n",
	       $signature,
	       "</PRE>\n<DL><DD><P>",
               $explanation,
	       "</P>\n",
	       $details,
	       "</DD></DL>"
	     ) ;
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
  if ( $#{$_[2]} >= 0 ) {
    my $content = join( '',
			"<DL><DT><B>$_[0]:</B></DT><DD>"
		      ) ;
    my $i = 0 ;
    $content .= "<UL>" if ( $_[1] =~ /<li>/i ) ;
    foreach my $e (@{$_[2]}) {
      if ( $_[1] =~ /<li>/i ) {
        $content .= "<LI>" ;
      }
      elsif ( $i > 0 ) {
	$content .= $_[1] ;
      }
      $content .= $e ;
      $content .= "</LI>" if ( $_[1] =~ /<li>/i ) ;
      $i ++ ;
    }
    $content .= "</UL>" if ( $_[1] =~ /<li>/i ) ;
    $content .= "</DD></DL>\n" ;
    return $content ;
  }
  else {
    return "" ;
  }
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
  my $title = $_[0] || confess( 'you must supply the title' ) ;
  my $rootdir = $_[2] || confess( 'you must supply the root directory' ) ;
  $self->{'FRAME_TREE_ID_COUNT'} ++ ;
  my $id = "treeid".$self->{'FRAME_TREE_ID_COUNT'} ;

  my $content = "<P><DIV id=\"".$id."off__\" style=\"visibility : hidden; position: absolute\"></DIV>\n" ;

  $content .= $self->href( "javascript:swaptree('".$id."')",
                           "<img src=\"".
                           htmlcatfile($rootdir,"minus.gif").
                           "\" alt=\"-\" ".
                           "id=\"".$id."plusminus\" width=\"11\" ".
                           "height=\"11\" border=\"0\">" ) ;
  $content .= join( '',
                    '&nbsp;',
                    $title,
                    "<BR>\n",
                    "<div id=\"",
                    $id,
                    "\">" ) ;

  if ( ( isarray($_[1]) ) && ( ! isemptyarray($_[1]) ) ) {
    for(my $i=0; $i<=$#{$_[1]}; $i++) {
      $content .= join( '',
                        "<TABLE border=0 cellspacing=0 cellpadding=0>",
                        "<TR><TD valign='top' align='right'><img src=\"",
                        htmlcatfile($rootdir,
                                    ($i==$#{$_[1]}) ?
                                    "lastchild.gif" : "child.gif"),
                        "\" alt=\"-\" width=\"11\" ",
                        "height=\"17\" border=\"0\"></TD><TD class='TreeText' valign='middle' align='left'>&nbsp;",
                        $_[1][$i],
                        "</TD></TR></TABLE>\n" ) ;
    }
  }
  $content .= "</DIV></P>\n\n" ;
  return $content ;
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
  my $title = $_[0] || '' ;
  my $text = $_[1] || '' ;
  return join( '',
               ( $title ? "<H2>$title</H2>\n\n" : '' ),
               $text ) ;
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
	       "<SPAN CLASS='small'>",
	       $text,
	       "</SPAN>\n" ) ;
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
	       "<SPAN CLASS='tiny'>",
	       $text,
	       "</SPAN>\n" ) ;
}

#------------------------------------------------------
#
# Array API
#
#------------------------------------------------------

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
  my $title = $_[0] || '' ;
  my $content = '' ;
  if ( ( isarray($_[1]) ) && ( ! isemptyarray($_[1]) ) ) {
    foreach my $cell (@{$_[1]}) {
      $content .= join( '',
                        "<TR><TD>",
                        $cell,
                        "</TD></TR>\n" ) ;
    }
  }
  return join( '',
               "<P><TABLE BORDER='1' CELLPADDING='3' CELLSPACING='0' WIDTH='100%'>",
               "<THEAD>",
               "<TR><TD CLASS='tabletitle'><B>",
               $title,
               "</B></TD></TR>",
               "</THEAD>\n<TBODY>",
               $content,
               "</TBODY>\n</TABLE></P>\n\n" ) ;
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
  my $title = $_[0] || '' ;
  my $content = '' ;
  if ( ( isarray($_[1]) ) && ( ! isemptyarray($_[1]) ) ) {
    for(my $i=0; $i<=$#{$_[1]}; $i++) {
      if ( ( ishash($_[1][$i]) ) && ( ! isemptyhash($_[1][$i]) ) ) {
        $content .= join( '',
                          "<TR><TD valign='top' align='left'>",
                          $_[1][$i]->{'name'},
                          "</TD><TD valign='top' align='left'>",
                          $_[1][$i]->{'explanation'},
                          "</TD></TR>" ) ;
      }
    }
  }
  return join( '',
               "<P><TABLE BORDER='1' CELLPADDING='3' CELLSPACING='0' WIDTH='100%'>",
               "<THEAD>",
               "<TR><TD CLASS='tabletitle' COLSPAN='2'><B>",
               $title,
               "</B></TD></TR>",
               "</THEAD>\n<TBODY>",
               $content,
               "</TBODY>\n</TABLE></P>\n\n" ) ;
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
  my $title = $_[0] || '' ;
  my $content = '' ;
  if ( ( isarray($_[1]) ) && ( ! isemptyarray($_[1]) ) ) {
    foreach my $cell (@{$_[1]}) {
      $content .= join( '',
                        "<TR><TD>",
                        $cell,
                        "</TD></TR>\n" ) ;
    }
  }
  return join( '',
               "<P><TABLE BORDER='1' CELLPADDING='3' CELLSPACING='0' WIDTH='100%'>",
               "<THEAD>",
               "<TR><TD CLASS='smalltabletitle'><B>",
               $title,
               "</B></TD></TR>",
               "</THEAD>\n<TBODY CLASS='smalltable'>",
               $content,
               "</TBODY>\n</TABLE></P>\n\n" ) ;
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
  my $title = $_[0] || '' ;
  my $content = '' ;
  if ( ( isarray($_[1]) ) && ( ! isemptyarray($_[1]) ) ) {
    foreach my $cell (@{$_[1]}) {
      $content .= join( '',
                        "<TR><TD>",
                        $cell,
                        "</TD></TR>\n" ) ;
    }
  }
  return join( '',
               "<P><TABLE BORDER='1' CELLPADDING='3' CELLSPACING='0' WIDTH='100%'>",
               "<THEAD>",
               "<TR><TD CLASS='tinytabletitle'><B>",
               $title,
               "</B></TD></TR>",
               "</THEAD>\n<TBODY CLASS='tinytable'>",
               $content,
               "</TBODY>\n</TABLE></P>\n\n" ) ;
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
  my $title = $_[0] || '' ;
  my $content = '' ;
  if ( ( isarray($_[1]) ) && ( ! isemptyarray($_[1]) ) ) {
    for(my $i=0; $i<=$#{$_[1]}; $i++) {
      if ( ( ishash($_[1][$i]) ) && ( ! isemptyhash($_[1][$i]) ) ) {
        $content .= join( '',
                          "<TR><TD valign='top' align='left'>",
                          $_[1][$i]->{'type'},
                          "</TD><TD WIDTH='100%' valign='top' align='left'>",
                          $_[1][$i]->{'name'},
                          "<BR>\n",
                          $_[1][$i]->{'explanation'},
                          "</TD></TR>" ) ;
      }
    }
  }
  return join( '',
               "<P><TABLE BORDER='1' CELLPADDING='3' CELLSPACING='0' WIDTH='100%'>",
               "<THEAD>",
               "<TR><TD CLASS='tabletitle' COLSPAN='3'><B>",
               $title,
               "</B></TD></TR>",
               "</THEAD>\n<TBODY>",
               $content,
               "</TBODY>\n</TABLE></P>\n\n" ) ;
}

#------------------------------------------------------
#
# Navigation API
#
#------------------------------------------------------

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
  my $thispage = $_[0] || confess( 'you must supply the URL' ) ;
  my $rootdir = $_[2] || confess( 'you must supplythe root directory' ) ;

  my $overview = "<b>".$self->{'LANG'}->get('I18N_LANG_OVERVIEW')."</b>" ;
  my $tree = "<b>".$self->{'LANG'}->get('I18N_LANG_TREE')."</b>" ;
  my $index = "<b>".$self->{'LANG'}->get('I18N_LANG_INDEX')."</b>" ;
  my $package = "<b>".$self->{'LANG'}->get('I18N_LANG_PACKAGE')."</b>" ;
  my $webmodule = "<b>".$self->{'LANG'}->get('I18N_LANG_MODULE')."</b>" ;

  my $prev = uc( $self->{'LANG'}->get('I18N_LANG_PREV') ) ;
  my $next = uc( $self->{'LANG'}->get('I18N_LANG_NEXT') ) ;

  my $field_sum = uc( $self->{'LANG'}->get('I18N_LANG_FIELD') ) ;
  my $constructor_sum = uc( $self->{'LANG'}->get('I18N_LANG_CONSTR') ) ;
  my $method_sum = uc ($self->{'LANG'}->get('I18N_LANG_METHOD') ) ;
  my $field_detail = $field_sum ;
  my $constructor_detail = $constructor_sum ;
  my $method_detail = $method_sum ;

  my $sectionshortcut_sum = "" ;
  my $sectionshortcut_detail = "" ;

  if ( ! $_[1]{'overview'} ) {
    $overview = $self->ext_wt_href('overview',$overview,$rootdir) ;
  }
  if ( ! $_[1]{'tree'} ) {
    $tree = $self->ext_wt_href('tree',$tree,$rootdir) ;
  }
  if ( $_[1]{'index'} ) {
    $index = $self->href( htmlcatfile( $rootdir,
				       $self->filename('indexes',0) ),
			  $index,
			  $self->browserframe('indexes') ) ;
  }
  if ( ( $self->{'GENERATES_PHP'} ) && ( $_[1]{'package'} ) ) {
    $package = $self->href($_[1]{'package'},$package) ;
  }
  if ( ( $self->{'GENERATES_WEB'} ) && ( $_[1]{'webmodule'} ) ) {
    $webmodule = $self->href($_[1]{'webmodule'},$webmodule) ;
  }
  if ( $_[1]{'previous'} ) {
    $prev = $self->href($_[1]{'previous'},$prev) ;
  }
  if ( $_[1]{'next'} ) {
    $next = $self->href($_[1]{'next'},$next) ;
  }

  if ( ( $_[1]{'fields'} ) ||
       ( $_[1]{'constructors'} ) ||
       ( $_[1]{'methods'} )  ) {
    if ( $_[1]{'fields'} ) {
      $field_sum = $self->href("#_section_field_summary",$field_sum) ;
      $field_detail = $self->href("#_section_field_detail",$field_detail) ;
    }
    if ( $_[1]{'constructors'} ) {
      $constructor_sum = $self->href("#_section_constructor_summary",$constructor_sum) ;
      $constructor_detail = $self->href("#_section_constructor_detail",$constructor_detail) ;
    }
    if ( $_[1]{'methods'} ) {
      $method_sum = $self->href("#_section_method_summary",$method_sum) ;
      $method_detail = $self->href("#_section_method_detail",$method_detail) ;
    }
    $sectionshortcut_sum = $self->{'LANG'}->get('I18N_LANG_THEME_SUMMARY_BAR',
						$field_sum,
						$constructor_sum,
						$method_sum ) ;
    $sectionshortcut_detail = $self->{'LANG'}->get('I18N_LANG_THEME_DETAIL_BAR',
						   $field_detail,
						   $constructor_detail,
						   $method_detail ) ;
  }

  if ( $_[1]{'notree'} ) {
    $tree = "" ;
  }
  else {
    $tree = "<td>&nbsp;$tree&nbsp;</td>\n" ;
  }

  if ( $self->{'GENERATES_PHP'} ) {
    $package = "<td>&nbsp;$package&nbsp;</td>\n" ;
  }
  else {
    $package = "" ;
  }

  if ( $self->{'GENERATES_WEB'} ) {
    $webmodule = "<td>&nbsp;$webmodule&nbsp;</td>\n" ;
  }
  else {
    $webmodule = "" ;
  }

  my $content = join( '',
		      "<table BORDER=\"0\" WIDTH=\"100%\" ",
		      "CELLPADDING=\"1\" CELLSPACING=\"0\">\n",
		      "<tr>\n",
		      "<td COLSPAN=2>\n",
		      # First row
		      "<table BORDER=\"0\" CELLPADDING=\"0\" ",
		      "CELLSPACING=\"3\">\n",
		      "<tr ALIGN=\"center\" VALIGN=\"top\">\n",
		      "<td>&nbsp;$overview&nbsp;</td>\n",
		      $package,
		      $webmodule,
		      $tree,
		      "<td>&nbsp;$index&nbsp;</td>\n",
		      "</tr>\n</table>\n",
		      "</td>\n",
		      # Name of the doc
		      "<td ALIGN=\"right\" VALIGN=\"top\" ROWSPAN=3><em><b>",
		      $self->{'TITLE'},
		      "</b></em></td>\n</tr>\n",
		      # Second row
		      "<tr>\n",
		      "<td BGCOLOR=\"white\">",
		      $self->small("$prev&nbsp;&nbsp;$next"),
		      "</td>\n",
		      "<td>",
		      $self->small( $self->ext_href('main',"<b>".
						    $self->{'LANG'}->get('I18N_LANG_FRAMES').
						    "</b>",$rootdir) .
 		                    "&nbsp;&nbsp;".
		                    $self->href($thispage,"<b>".
						$self->{'LANG'}->get('I18N_LANG_NO_FRAME').
						"</b>",
				                $self->browserframe('main')).
		                    "&nbsp;" ),
                      "</td>\n",
		      "</tr>\n",
		      "<tr>",
		      "<td VALIGN=\"top\">",
		      $self->small($sectionshortcut_sum),
		      "</td>\n",
		      "<td VALIGN=\"top\">",
		      $self->small($sectionshortcut_detail),
		      "</td>\n",
		      "</tr>\n",
		      "</table>\n"
		    ) ;
}

#------------------------------------------------------
#
# Filename API
#
#------------------------------------------------------

=pod

=item * copy_files()

Copies some files from the phpdocgen distribution directly inside the
HTML documentation tree.

=cut
sub copy_files()  {
  my $self = shift ;
  $self->SUPER::copy_files() ;
  my @pack = File::Spec->splitdir( __FILE__ ) ;
  pop @pack ;
  push @pack, 'Dyna' ;
  foreach my $file (@{$self->{'COPY_FILES'}}) {
    PhpDocGen::General::Verbose::one( "Copying $file..." ) ;
    PhpDocGen::General::Verbose::three( "\tfrom ".File::Spec->catdir(@pack) ) ;
    PhpDocGen::General::Verbose::three( "\tto   ".$self->{'TARGET_DIR'} ) ;
    my $from = File::Spec->catfile(@pack, $file) ;
    copy( $from,
	  File::Spec->catfile($self->{'TARGET_DIR'},$file) )
      or PhpDocGen::General::Error::syserr( "$from: $!\n" );
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

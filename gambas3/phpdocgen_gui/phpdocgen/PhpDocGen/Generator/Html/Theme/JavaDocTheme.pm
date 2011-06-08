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

PhpDocGen::Generator::Html::Theme::JavaDocTheme - A theme for the HTML generator

=head1 SYNOPSYS

use PhpDocGen::Generator::Html::Theme::JavaDocTheme ;

my $gen = PhpDocGen::Generator::Html::Theme::JavaDocTheme->new( phpdocgen,
                                                         target,
                                                         title,
                                                         phpgen,
                                                         webgen ) ;

=head1 DESCRIPTION

PhpDocGen::Generator::Html::Theme::JavaDocTheme is a Perl module, which proposes
a documentation theme for the HTML generator of phpdocgen. This theme generates
something like javadoc.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use PhpDocGen::Generator::Html::Theme::JavaDocTheme;

    my $gen = PhpDocGen::Generator::Html::Theme::JavaDocTheme->new( { 'VERSION' => '0.11' },
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

package PhpDocGen::Generator::Html::Theme::JavaDocTheme;

@ISA = ('PhpDocGen::Generator::Html::Theme');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;

use Carp ;

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

# Version number of JavaDoc theme
my $VERSION = "0.4" ;

my %LANG_DEFS = ( 'English' => { 'I18N_LANG_THEME_SUMMARY_BAR' => "SUMMARY: &nbsp;#1&nbsp;|&nbsp;#2&nbsp;|&nbsp;#3",
				 'I18N_LANG_THEME_DETAIL_BAR' => "DETAIL: &nbsp;#1&nbsp;|&nbsp;#2&nbsp;|&nbsp;#3",
			       },
		  'French' => { 'I18N_LANG_THEME_SUMMARY_BAR' => "R&Eacute;SUM&Eacute;: &nbsp;#1&nbsp;|&nbsp;#2&nbsp;|&nbsp;#3",
				'I18N_LANG_THEME_DETAIL_BAR' => "DETAIL: &nbsp;#1&nbsp;|&nbsp;#2&nbsp;|&nbsp;#3",
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

  $self->{'BACKGROUND_COLOR'} = "white" ;

  $self->addLang( \%LANG_DEFS ) ;

  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Main structure
#
#------------------------------------------------------

#------------------------------------------------------
#
# Navigation
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
  my $thispage = $_[0] ;
  my $rootdir = $_[2] || confess( "the rootdir must be supplied" ) ;

  my $overview = "<b>".$self->{'LANG'}->get('I18N_LANG_OVERVIEW')."</b>" ;
  my $tree = "<b>".$self->{'LANG'}->get('I18N_LANG_TREE')."</b>" ;
  my $index = "<b>".$self->{'LANG'}->get('I18N_LANG_INDEX')."</b>" ;
  my $package = "<b>".$self->{'LANG'}->get('I18N_LANG_PACKAGE')."</b>" ;
  my $webmodule = "<b>".$self->{'LANG'}->get('I18N_LANG_MODULE')."</b>" ;

  my $prev = uc( $self->{'LANG'}->get('I18N_LANG_PREV') ) ;
  my $next = uc( $self->{'LANG'}->get('I18N_LANG_NEXT') ) ;

  my $field_sum = uc( $self->{'LANG'}->get('I18N_LANG_FIELD') ) ;
  my $constructor_sum = uc( $self->{'LANG'}->get('I18N_LANG_CONSTR') ) ;
  my $method_sum = uc( $self->{'LANG'}->get('I18N_LANG_METHOD') ) ;
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
    $tree = "<td BGCOLOR=\"#EEEEFF\">&nbsp;$tree&nbsp;</td>\n" ;
  }

  if ( $self->{'GENERATES_PHP'} ) {
    $package = "<td BGCOLOR=\"#EEEEFF\">&nbsp;$package&nbsp;</td>\n" ;
  }
  else {
    $package = "" ;
  }

  if ( $self->{'GENERATES_WEB'} ) {
    $webmodule = "<td BGCOLOR=\"#EEEEFF\">&nbsp;$webmodule&nbsp;</td>\n" ;
  }
  else {
    $webmodule = "" ;
  }

  my $content = join( '',
		      "<table BORDER=\"0\" WIDTH=\"100%\" ",
		      "CELLPADDING=\"1\" CELLSPACING=\"0\">\n",
		      "<tr>\n",
		      "<td COLSPAN=2 BGCOLOR=\"#EEEEFF\">\n",
		      # First row
		      "<table BORDER=\"0\" CELLPADDING=\"0\" ",
		      "CELLSPACING=\"3\">\n",
		      "<tr ALIGN=\"center\" VALIGN=\"top\">\n",
		      "<td BGCOLOR=\"#EEEEFF\">&nbsp;$overview&nbsp;</td>\n",
		      $package,
		      $webmodule,
		      $tree,
		      "<td BGCOLOR=\"#EEEEFF\">&nbsp;$index&nbsp;</td>\n",
		      "</tr>\n</table>\n",
		      "</td>\n",
		      # Name of the doc
		      "<td ALIGN=\"right\" VALIGN=\"top\" ROWSPAN=3><em><b>",
		      $self->{'TITLE'},
		      "</b></em></td>\n</tr>\n",
		      # Second row
		      "<tr>\n",
		      "<td BGCOLOR=\"white\"><font SIZE=\"-2\">",
		      "$prev&nbsp;&nbsp;$next",
		      "</font></td>\n",
		      "<td BGCOLOR=\"white\"><font SIZE=\"-2\">",
		      $self->ext_href('main',"<b>".
				      uc( $self->{'LANG'}->get('I18N_LANG_FRAMES') ).
				      "</b>",$rootdir),
		      "&nbsp;&nbsp;",
		      $self->href($thispage,"<b>".
				  uc( $self->{'LANG'}->get('I18N_LANG_NO_FRAME') ).
				  "</b>",
				  $self->browserframe('main')),
		      "&nbsp;</font></td>\n",
		      "</tr>\n",
		      "<tr>",
		      "<td VALIGN=\"top\"><font SIZE=\"-2\">",
		      $sectionshortcut_sum,
		      "</font></td>\n",
		      "<td VALIGN=\"top\"><font SIZE=\"-2\">",
		      $sectionshortcut_detail,
		      "</font></td>\n",
		      "</tr>\n",
		      "</table>\n"
		    ) ;
}

#------------------------------------------------------
#
# Right Frames
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
  my $title = $_[0] || '' ;
  my $content = "<P><FONT size=\"+1\">$title</FONT><BR>\n" ;
  if ( isarray( $_[1] ) ) {
    foreach my $line (@{$_[1]}) {
      $content .= $line."<BR>\n" ;
    }
  }
  return $content."</P>\n" ;
}

=pod

=item * frame_window()

Replies a frame
Takes 2 args:

=over

=item * title (string)

is the title of the frame (could be empty).

=item * text (string)

is the content of the frame.

=back

=cut
sub frame_window($$)  {
  my $self = shift ;
  my $title = $_[0] || '' ;
  my $text = $_[1] || '' ;
  return join( '',
	       ($title ? "<FONT size=\"+1\"><B>$title</B></FONT>":''),
	       "<TABLE BORDER=\"0\" WIDTH=\"100%\">\n<TR>\n",
	       "<TD NOWRAP>",
               $text,
               "</TD></TR></TABLE><BR>\n" ) ;
}

#------------------------------------------------------
#
# Sectioning
#
#------------------------------------------------------

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
	       "<P><TABLE BORDER=\"1\" CELLPADDING=\"3\" ",
	       "CELLSPACING=\"0\" WIDTH=\"100%\">\n",
	       "<TR BGCOLOR=\"#CCCCFF\"><TD COLSPAN=1>",
	       "<FONT SIZE=\"+2\"><B>",
	       $_[0] || '',
	       "</B></FONT></TD>\n",
	       "</TR></TABLE><BR>\n" ) ;
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
  my $class = $_[0] || confess( 'you must supply the classame' ) ;
  my $extends = $_[1] || '' ;
  my $explanation = $_[2] || '' ;
  my $details = $_[3] || '' ;
  return join( '',
               "<DL>\n<DT>",
	       $self->{'LANG'}->get('I18N_LANG_CLASS'),
	       " <B>$class</B>",
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
  my $explanation = $_[3] || '' ;
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
# Bugs
#
#------------------------------------------------------

=pod

=item * format_fixed_bug()

Replies a formated string that corresponds to the description of a
fixed bug.
Takes 1 arg:

=over

=item * text (string)

is the description of the bug.

=back

=cut
sub format_fixed_bug($) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  return join( '',
	       "<table border=\"0\" cellspacing=\"0\" cellpading=\"0\" width=\"100%\">\n",
	       "<tr><td align=\"left\">",
	       "<font color=\"#555555\">",
	       $text,
	       "</font>",
	       "</td><td align=\"right\">",
	       "<strong>",
	       uc( $self->{'LANG'}->get('I18N_LANG_FIXED') ),
	       "</strong>",
	       "</td></tr></table>\n" ) ;
}

#------------------------------------------------------
#
# Tabulars
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
  my $content = join( '',
               	      "<DIV><TABLE BORDER=\"1\" ",
		      "CELLPADDING=\"3\" CELLSPACING=\"0\" ",
		      "WIDTH=\"100%\">\n",
               	      "<TR BGCOLOR=\"#CCCCFF\">\n",
               	      "<TD COLSPAN=2><FONT SIZE=\"+2\"><B>",
		      $_[0],
		      "</B></FONT></TD>\n",
               	      "</TR>\n" ) ;
  foreach my $case (@{$_[1]}) {
    $content .= join( '',
                      "<TR BGCOLOR=\"white\">",
                      "<TD WIDTH=\"20%\">",
		      $case,
		      "</TD>",
                      "</TR>\n" ) ;
  }
  $content .= "</TABLE><BR></DIV>\n" ;
  return $content ;
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
  my $content = join( '',
               	      "<P><TABLE BORDER=\"1\" CELLPADDING=\"3\" ",
		      "CELLSPACING=\"0\" WIDTH=\"100%\">\n",
               	      "<TR BGCOLOR=\"#EEEEFF\">\n",
               	      "<TD><B>$_[0]</B></TD>\n",
               	      "</TR>\n" ) ;
  foreach my $case (@{$_[1]}) {
    $content .= join( '',
                      "<TR BGCOLOR=\"white\">",
                      "<TD ALIGN=\"left\" VALIGN=\"top\">",
		      $case,
                      "</TD></TR>\n" ) ;
  }
  $content .= "</TABLE></P>\n" ;
  return $content ;
}

=pod

=item * build_tiny_array()

Replies an small one-column array.
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
  my $content = join( '',
               	      "<P><TABLE BORDER=\"1\" CELLPADDING=\"3\" ",
		      "CELLSPACING=\"0\" WIDTH=\"100%\">\n",
               	      "<TR BGCOLOR=\"#EEEEEFF\">\n",
               	      "<TD><FONT SIZE=\"-1\"><B>$_[0]</B></FONT></TD>\n",
               	      "</TR>\n" ) ;
  foreach my $case (@{$_[1]}) {
    $content .= join( '',
                      "<TR BGCOLOR=\"white\">",
                      "<TD ALIGN=\"left\" VALIGN=\"top\">",
		      "<FONT SIZE=\"-1\">",
		      $case,
		      "</FONT>",
                      "</TD></TR>\n" ) ;
  }
  $content .= "</TABLE></P>\n" ;
  return $content ;
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
  my $content = join( '',
               "<P><TABLE BORDER=\"1\" ",
	       "CELLPADDING=\"3\" CELLSPACING=\"0\" ",
	       "WIDTH=\"100%\">\n",
               "<TR BGCOLOR=\"#CCCCFF\">\n",
               "<TD COLSPAN=2><FONT SIZE=\"+2\"><B>",
	       $_[0],
	       "</B></FONT></TD>\n",
               "</TR>\n" ) ;
  foreach my $cellule (@{$_[1]}) {
    my $name = ${%{$cellule}}{name} ;
    my $explanation = ${%{$cellule}}{explanation} || '' ;
    if ( $name ) {
      if ( ! $explanation ) {
        $explanation = "&nbsp;" ;
      }
      $content = join( '', 
                       $content,
                       "<TR BGCOLOR=\"white\">",
                       "<TD WIDTH=\"20%\">",
                       $name,
                       "</TD><TD>",
                       $explanation,
                       "</TD></TR>\n" ) ;
    }
  }
  $content .= "</TABLE></P>\n" ;
  return $content ;
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
  my $content = join( '',
		      "<P>",
		      "<A NAME=\"$_[2]\"></A>",
		      "<TABLE BORDER=\"1\" ",
		      "CELLPADDING=\"3\" CELLSPACING=\"0\" ",
		      "WIDTH=\"100%\">\n",
		      "<TR BGCOLOR=\"#CCCCFF\">\n",
		      "<TD COLSPAN=2><FONT SIZE=\"+2\"><B>",
		      $_[0],
		      "</B></FONT></TD>\n",
		      "</TR>\n" ) ;
  foreach my $cellule (@{$_[1]}) {
    my $name = ${%{$cellule}}{name} ;
    my $explanation = ${%{$cellule}}{explanation} || '' ;
    my $type = ${%{$cellule}}{type} ;
    if ( $name ) {
      if ( ! $explanation ) {
        $explanation = "&nbsp;" ;
      }
      $content = join( '', 
                       $content,
                       "<TR BGCOLOR=\"white\"><TD WIDTH=\"1%\" ",
		       "VALIGN=\"top\"><FONT SIZE=\"-1\"><CODE>",
                       $type,
                       "</CODE></FONT></TD>",
                       "<TD ALIGN=\"left\" VALIGN=\"top\"><CODE>",
                       $name,
                       "</CODE><BR>\n",
                       $explanation,
                       "</TD></TR>\n" ) ;
    }
  }
  $content .= "</TABLE></P>\n" ;
  return $content ;
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

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

PhpDocGen::Checker::Checker - An checker for the extracted data

=head1 SYNOPSYS

use PhpDocGen::Checker::Checker ;

my $gen = PhpDocGen::Checker::Checker->new( dc ) ;

=head1 DESCRIPTION

PhpDocGen::Checker::Checker is a Perl module, which checks
the extracted data to detct aby inconsistance.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use PhpDocGen::Checker::Checker;

    my $gen = PhpDocGen::Checker::Checker->new( 1 ) ;

...or something similar. Acceptable parameters are :

=over

=item * dc (boolean )

indicates if the data collection extracted from the source files
must be directly displayed.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Checker.pm itself.

=over

=cut

package PhpDocGen::Checker::Checker;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;
use Data::Dumper ;

use PhpDocGen::General::Misc ;
use PhpDocGen::General::Error ;
use PhpDocGen::General::Token ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of checker
my $VERSION = "0.2" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($)  {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = { 'DISPLAY_DATA_COLLECTION' => $_[0] || 0,
	     } ;
  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# General purpose functions
#
#------------------------------------------------------

# Display an error message
sub checkerr($) {
  my $msg = $_[0] || '' ;
  PhpDocGen::General::Error::syserr($msg) ;
}

# Display an warning message
sub checkwarm($) {
  my $msg = $_[0] || '' ;
  PhpDocGen::General::Error::syswarm($msg) ;
}

#------------------------------------------------------
#
# Checking main function
#
#------------------------------------------------------

=pod

=item * check()

Replies if the specified data is valid.
Takes 1 arg:

=over

=item * data (hash ref)

is the result of the parsing.

=back

=cut
sub check($)  {
  my $self = shift ;

  if ( isemptyhash($_[0]) ) {
    checkerror( 'kernel panic: no data extracted' ) ;
  }

  if ( $self->{'DISPLAY_DATA_COLLECTION'} ) {
    print STDERR Dumper($_[0]) ;
  }

  return ( ( $self->check_packages($_[0]{'packages'}, $_[0]) ) &&
	   ( $self->check_classes($_[0]{'classes'}, $_[0]) ) ) ;
}

#------------------------------------------------------
#
# Class checking
#
#------------------------------------------------------

=pod

=item * check_classes()

Replies if the classes was correctly parsed.
Takes 2 args:

=over

=item * classes (hash ref)

is the list of packages

=item * data (hash ref)

is the entire result of the parsing.

=back

=cut
sub check_classes($$)  {
  my $self = shift ;
  my $classes = $_[0] ;

  if ( isemptyhash( $classes ) ) {
    checkwarm( 'no class found during the parsing. Do you are sure to use phpdocgen?' ) ;
    return 0 ;
  }

  foreach my $kcls ( keys %{$classes} ) {
    PhpDocGen::General::Verbose::two( "Checking class '$kcls'...\n" ) ;
    # THIS
    if ( $self->_check_package( $classes->{$kcls}{'this'}{'package'}, 'class', "$kcls", $_[1] ) ) {
      #name
      $self->_check_name( $classes->{$kcls}{'this'}{'name'}, 'class', "$kcls", $kcls ) ;
      #location
      $self->_check_location( $classes->{$kcls}{'this'}{'location'}, 'class', "$kcls" ) ;
      #explanation
      $self->_check_explanation( $classes->{$kcls}{'this'}{'explanation'}, 'class', "$kcls" ) ;
      #extends
      $self->_check_extends( $classes->{$kcls}{'this'}, 'class', "$kcls", $classes ) ;
      #common tags
      $self->_check_commontags( $classes->{$kcls}{'this'}, 'class', "$kcls", $_[1] ) ;

      # ATTRIBUTES
      $self->check_class_attributes( $kcls, $classes->{$kcls}{'attributes'}, $_[1] ) ;

      # CONSTRUCTOR
      $self->check_class_constructor( $kcls, $classes->{$kcls}{'constructor'}, $_[1] ) ;

      # METHODS
      $self->check_class_methods( $kcls, $classes->{$kcls}{'methods'}, $_[1] ) ;
    }
  }

  return 1 ;
}

=pod

=item * check_class_attributes()

Replies if the attributes of the specified class
was correctly parsed.
Takes 3 args:

=over

=item * class (string)

is the class name.

=item * attribute (hash ref)

is the list of attributes

=item * data (hash ref)

is the entire result of the parsing.

=back

=cut
sub check_class_attributes($$$)  {
  my $self = shift ;
  if ( ( $_[1] ) &&
       ( ! isemptyhash($_[1]) ) ) {
    foreach my $katr (keys %{$_[1]}) {
      my $fullname = $_[0]."::".$katr ;
      PhpDocGen::General::Verbose::two( "Checking attribute '$fullname'...\n" ) ;
      # name
      $self->_check_name( $_[1]->{$katr}{'name'}, 'attribute', $fullname, $katr ) ;
      # type
      $self->_check_type( $_[1]->{$katr}{'type'}, 'attribute', $fullname ) ;
      # location
      $self->_check_location( $_[1]->{$katr}{'location'}, 'attribute', $fullname ) ;
      # explanation
      $self->_check_explanation( $_[1]->{$katr}{'explanation'}, 'attribute', $fullname ) ;
      # Access rights
      $self->_check_access_rights( $_[1]->{$katr}, 'attribute', $fullname ) ;
      #common tags
      $self->_check_commontags( $_[1]->{$katr}, 'attribute', $fullname, $_[2] ) ;
    }
  }
}

=pod

=item * check_class_constructor()

Replies if the constructors of the specified class
was correctly parsed.
Takes 3 args:

=over

=item * class (string)

is the class name.

=item * constructor (hash ref)

is the constructors

=item * data (hash ref)

is the entire result of the parsing.

=back

=cut
sub check_class_constructor($$$)  {
  my $self = shift ;
  if ( ( $_[1] ) &&
       ( ! isemptyhash($_[1]) ) ) {
    my $fullname = $_[0]."::".addfctbraces($_[0]) ;
    PhpDocGen::General::Verbose::two( "Checking constructor '$fullname'...\n" ) ;
    # function tags
    $self->_check_function( $_[1], 'constructor', $fullname, $_[2] ) ;
  }
}

=pod

=item * check_class_methods()

Replies if the methods of the specified class
was correctly parsed.
Takes 3 args:

=over

=item * class (string)

is the class name.

=item * methods (hash ref)

is the methods

=item * data (hash ref)

is the entire result of the parsing.

=back

=cut
sub check_class_methods($$$)  {
  my $self = shift ;
  if ( ( $_[1] ) &&
       ( ! isemptyhash($_[1]) ) ) {
    foreach my $kmth (keys %{$_[1]}) {
      my $fullname = $_[0]."::".addfctbraces($kmth) ;
      PhpDocGen::General::Verbose::two( "Checking method '$fullname'...\n" ) ;
      # function tags
      $self->_check_function( $_[1]->{$kmth}, 'method', $fullname, $_[2] ) ;
      # Access rights
      $self->_check_access_rights( $_[1]->{$kmth}, 'method', $fullname ) ;
    }
  }
}

#------------------------------------------------------
#
# Package checking
#
#------------------------------------------------------

=pod

=item * check_packages()

Replies if the packages was correctly parsed.
Takes 2 args:

=over

=item * packages (hash ref)

is the list of packages

=item * data (hash ref)

is the entire result of the parsing.

=back

=cut
sub check_packages($$)  {
  my $self = shift ;
  my $packages = $_[0] ;

  if ( ( isemptyhash( $packages ) ) &&
       ( isemptyhash( $_[1]->{'webmodules'} ) ) ) {
    checkerr( 'kernel panic: no package found during the parsing' ) ;
    return 0 ;
  }

  foreach my $kpack ( keys %{$packages} ) {
    PhpDocGen::General::Verbose::two( "Checking package '$kpack'...\n" ) ;
    # THIS
    $self->_check_name( $packages->{$kpack}{'this'}{'name'}, 'package', "$kpack", $kpack ) ;
    #common tags
    $self->_check_commontags( $packages->{$kpack}{'this'}, 'package', "$kpack", $_[1] ) ;
    # Constants
    return 0 unless
      $self->check_package_constants( $kpack, $packages->{$kpack}{'constants'}, $_[1] ) ;
    # Variables
    return 0 unless
      $self->check_package_variables( $kpack, $packages->{$kpack}{'variables'}, $_[1] ) ;
    # Functions
    return 0 unless
      $self->check_package_functions( $kpack, $packages->{$kpack}{'functions'}, $_[1] ) ;
    # Class list
    return 0 unless
      $self->check_package_classlist( $kpack, $packages->{$kpack}{'classes'}, $_[1] ) ;
  }

  return 1 ;
}

=pod

=item * check_package_constants()

Replies if the constants of the specified package
was correctly parsed.
Takes 3 args:

=over

=item * pack (string)

is the package name.

=item * constants (hash ref)

is the list of constants

=item * data (hash ref)

is the entire result of the parsing.

=back

=cut
sub check_package_constants($$$)  {
  my $self = shift ;
  my $kpack = $_[0] || confess( 'package expected' ) ;
  my $constants = $_[1]  ;

  if ( ! isemptyhash( $constants ) ) {

    foreach my $kcst ( keys %{$constants} ) {
      my $fullname = $kpack."::".$kcst ;
      PhpDocGen::General::Verbose::two( "Checking constant '$kcst'...\n" ) ;
      # name
      $self->_check_name( $constants->{$kcst}{'name'}, 'constant', $fullname, $kcst ) ;
      # type
      $self->_check_type( $constants->{$kcst}{'type'}, 'constant', $fullname ) ;
      # location
      $self->_check_location( $constants->{$kcst}{'location'}, 'constant', $fullname ) ;
      # explanation
      $self->_check_explanation( $constants->{$kcst}{'explanation'}, 'constant', $fullname ) ;
      #common tags
      $self->_check_commontags( $constants->{$kcst}, 'constant', $fullname, $_[2] ) ;
    }

  }

  return 1 ;
}


=pod

=item * check_package_variables()

Replies if the variables of the specified package
was correctly parsed.
Takes 3 args:

=over

=item * pack (string)

is the package name.

=item * variables (hash ref)

is the list of variables

=item * data (hash ref)

is the entire result of the parsing.

=back

=cut
sub check_package_variables($$$)  {
  my $self = shift ;
  my $kpack = $_[0] || confess( 'package expected' ) ;
  my $variables = $_[1]  ;

  if ( ! isemptyhash( $variables ) ) {

    foreach my $kvar ( keys %{$variables} ) {
      my $fullname = $kpack."::".$kvar ;
      PhpDocGen::General::Verbose::two( "Checking variable '$kvar'...\n" ) ;
      # name
      $self->_check_name( $variables->{$kvar}{'name'}, 'variable', $fullname, $kvar ) ;
      # type
      $self->_check_type( $variables->{$kvar}{'type'}, 'variable', $fullname ) ;
      # location
      $self->_check_location( $variables->{$kvar}{'location'}, 'variable', $fullname ) ;
      # explanation
      $self->_check_explanation( $variables->{$kvar}{'explanation'}, 'variable', $fullname ) ;
      #common tags
      $self->_check_commontags( $variables->{$kvar}, 'variable', $fullname, $_[2] ) ;
    }

  }

  return 1 ;
}

=pod

=item * check_package_functions()

Replies if the functions of the specified package
was correctly parsed.
Takes 3 args:

=over

=item * pack (string)

is the package name.

=item * functions (hash ref)

is the list of functions

=item * data (hash ref)

is the entire result of the parsing.

=back

=cut
sub check_package_functions($$$)  {
  my $self = shift ;
  my $kpack = $_[0] || confess( 'package expected' ) ;
  my $functions = $_[1]  ;

  if ( ! isemptyhash( $functions ) ) {

    foreach my $kfct ( keys %{$functions} ) {
      my $fullname = $kpack."::".$kfct ;
      PhpDocGen::General::Verbose::two( "Checking function '$kfct'...\n" ) ;
      # function tags
      $self->_check_function( $functions->{$kfct},'function',$fullname,$_[2] ) ;
    }

  }

  return 1 ;
}

=pod

=item * check_package_classlist()

Replies if the class list of the specified package
was correctly parsed.
Takes 3 args:

=over

=item * pack (string)

is the package name.

=item * list (array ref)

is the list of classes

=item * data (hash ref)

is the entire result of the parsing.

=back

=cut
sub check_package_classlist($$$)  {
  my $self = shift ;
  my $kpack = $_[0] || confess( 'package expected' ) ;
  my $list = $_[1]  ;

  PhpDocGen::General::Verbose::two( "Checking class list...\n" ) ;

  if ( ! isemptyarray( $list ) ) {

    my @newlist = () ;
    my $toto = 0 ;
    foreach my $kcls ( @{$list} ) {
      my $fullname = $kpack."::".$kcls ;

      if ( ! exists $_[2]->{'classes'}{$kcls} ) {
	checkwarm( "the class definition of '$fullname' was not found. Removes this class from the package." ) ;
	$toto = 1 ;
      }
      else {
	push @newlist, $kcls ;
      }
    }

    @{$list} = @newlist ;

  }
  elsif ( ( isemptyhash( $_[2]->{'constants'} ) ) ||
	  ( isemptyhash( $_[2]->{'variables'} ) ) ||
	  ( isemptyhash( $_[2]->{'functions'} ) ) ) {
    checkwarm( "the package '$kpack' does not contains any object (class, constant, variable or function)." ) ;
  }

  return 1 ;
}

#------------------------------------------------------
#
# Internal checking
#
#------------------------------------------------------

=pod

=item * _check_uses()

Takes 4 args:

=over

=item * fct (string ref)

=item * type (string)

=item * fullname (string)

=item * data (string)

=back

=cut
sub _check_uses($$$$) {
  my $self = shift ;
  if ( ( ! $_[0] ) ||
       ( isemptyhash($_[0]) ) ) {
    checkerr( "kernel panic: the definition of a function block is attempted by the $_[1] '$_[2]'." ) ;
  }

  if ( exists $_[0]->{'uses'} ) {

    PhpDocGen::General::Verbose::three( "Checking use definitions...\n" ) ;

    if ( ! isemptyarray($_[0]->{'uses'}) ) {
      my @uses = () ;
      foreach my $use (@{$_[0]->{'uses'}}) {
        # use location
        $self->_check_location( $use->{'location'}, $_[1], $_[2] ) ;
        # name
        if ( ! $use->{'name'} ) {
          checkwarm( "the name of the used global element inside the $_[1] '$_[2]' is empty. Removes this use from the list." ) ;
        }
        else {
          push @uses, { 'location' => $use->{'location'},
                        'name' => $use->{'name'},
                      } ;
        }
      }
      delete( $_[0]->{'uses'} ) ;
      if ( @uses ) {
        @{$_[0]->{'uses'}} = @uses ;
      }
    }
  }
}

=pod

=item * _check_return()

Takes 4 args:

=over

=item * fct (string ref)

=item * type (string)

=item * fullname (string)

=item * data (string)

=back

=cut
sub _check_return($$$$) {
  my $self = shift ;
  PhpDocGen::General::Verbose::three( "Checking $_[1] returned value...\n" ) ;
  if ( ( ! $_[0] ) ||
       ( isemptyhash($_[0]) ) ) {
    checkerr( "kernel panic: the definition of a function block is attempted by the $_[1] '$_[2]'." ) ;
  }

  if ( exists $_[0]->{'return'} ) {

    if ( ! isemptyhash($_[0]->{'return'}) ) {
      # return location
      $self->_check_location( $_[0]->{'return'}{'location'}, $_[1], $_[2] ) ;
      # type
      $self->_check_type( $_[0]->{'return'}{'type'}, $_[1], $_[2] ) ;
      # comment
      if ( ! $_[0]->{'return'}{'comment'} ) {
        $_[0]->{'return'}{'comment'} = '' ;
      }
      # main type
      if ( ( ! exists $_[0]->{'type'} ) ||
	   ( ! $_[0]->{'type'} ) ||
	   ( ! is_valid_type( $_[0]->{'type'} ) ) ) {
	$_[0]->{'type'} = $_[0]->{'return'}{'type'} ;
      }
      $self->_check_type( $_[0]->{'type'}, $_[1], $_[2] ) ;
      if ( $_[0]->{'type'} ne $_[0]->{'return'}{'type'} ) {
        checkwarm( "the types specified inside the return value and inside the the $_[1] definition of '$_[2]' are not the same. ".
                   "Assumes the first is right: '".$_[0]->{'return'}{'type'}."'." ) ;
        $_[0]->{'type'} = $_[0]->{'return'}{'type'} ;
      }
    }
    else {
      checkwarm( "the definition of a return block is attempted by the $_[1] '$_[2]'. Removes his from de definition." ) ;
      delete( $_[0]->{'type'} ) ;
      delete( $_[0]->{'return'} ) ;
    }

  }
}

=pod

=item * _check_function()

Takes 4 args:

=over

=item * fct (string ref)

=item * type (string)

=item * fullname (string)

=item * data (string)

=back

=cut
sub _check_function($$$$) {
  my $self = shift ;
  if ( ( ! $_[0] ) ||
       ( isemptyhash($_[0]) ) ) {
    checkerr( "kernel panic: the definition of a function block is attempted by the $_[1] '$_[2]'." ) ;
  }
  # name
  $self->_check_name( $_[0]->{'name'}, $_[1], $_[2], $_[3] ) ;
  # location
  $self->_check_location( $_[0]->{'location'}, $_[1], $_[2] ) ;
  # explanation
  $self->_check_explanation( $_[0]->{'explanation'}, $_[1], $_[2] ) ;
  # common tags
  $self->_check_commontags( $_[0], $_[1], $_[2], $_[3] ) ;
  # Parameters
  $self->_check_parameters( $_[0]->{'parameters'}, $_[1], $_[2] ) ;
  # returned value
  $self->_check_return( $_[0], $_[1], $_[2] ) ;
  # uses
  $self->_check_uses( $_[0], $_[1], $_[2] ) ;
}

=pod

=item * _check_name()

Takes 4 args:

=over

=item * name (string ref)

=item * type (string)

=item * fullname (string)

=item * default (string)

=back

=cut
sub _check_name($$$$) {
  my $self = shift ;
  if ( ! $_[0] ) {
    checkwarm( "the real name of the $_[1] '$_[2]' is not found. Assumes '$_[3]'." ) ;
    $_[0] = $_[3] ;
  }
}

=pod

=item * _check_type()

Takes 3 args:

=over

=item * name (string ref)

=item * type (string)

=item * fullname (string)

=back

=cut
sub _check_type($$$) {
  my $self = shift ;
  my $type = $_[0] || '' ;
  if ( ! is_valid_type($type) ) {
    checkwarm( "the type '$type' of the $_[1] '$_[2]' is invalid. Assumes 'mixed'." ) ;
    $_[0] = 'mixed' ;
  }
}

=pod

=item * _check_location()

Takes 3 args:

=over

=item * name (string ref)

=item * type (string)

=item * fullname (string)

=back

=cut
sub _check_location($$$) {
  my $self = shift ;
  if ( ! is_valid_location($_[0]) ) {
    checkerr( "kernel panic: the location of the $_[1] '$_[2]' is invalid." ) ;
  }
}

=pod

=item * _check_access_rights()

Takes 3 args:

=over

=item * name (string ref)

=item * type (string)

=item * fullname (string)

=back

=cut
sub _check_access_rights($$$) {
  my $self = shift ;
  my ($private,$protected,$public) = (0,0,0) ;
  PhpDocGen::General::Verbose::three( "Checking $_[1] access rights...\n" ) ;
  if ( ( $_[0] ) &&
       ( ! isemptyhash($_[0]) ) ) {
    $private = $_[0]->{'private'} || 0 if ( exists $_[0]->{'private'} ) ;
    $protected = $_[0]->{'protected'} || 0 if ( exists $_[0]->{'protected'} ) ;
    $public = $_[0]->{'public'} || 0 if ( exists $_[0]->{'public'} ) ;
    unless ( $private || $protected || $public ) {
      checkwarm( "the access right for the $_[1] '$_[2]' is not defined. Assumes public." ) ;
      $private = $protected = 0 ;
      $public = 1 ;
    }
    elsif ( ( (!$private) || $protected || $public ) &&
	    ( $private || (!$protected) || $public ) &&
	    ( $private || $protected || (!$public) ) ) {
      checkwarm( "more than once access right was defined for the $_[1] '$_[2]'. Assumes public." ) ;
      $private = $protected = 0 ;
      $public = 1 ;
    }
    $_[0]->{'private'} = $private ;
    $_[0]->{'protected'} = $protected ;
    $_[0]->{'public'} = $public ;
  }
  else {
    checkerr( "kernel panic: unable to obtain the right access fields for the $_[1] '$_[2]'." ) ;
  }
}

=pod

=item * _check_parameters()

Takes 3 args:

=over

=item * name (string ref)

=item * type (string)

=item * fullname (string)

=back

=cut
sub _check_parameters($$$) {
  my $self = shift ;
  if ( ( $_[0] ) &&
       ( ! isemptyhash($_[0]) ) &&
       ( exists $_[0]->{'parameters'} ) ) {
    PhpDocGen::General::Verbose::three( "Checking $_[1] parameters...\n" ) ;
    if ( ( ! $_[0]->{'parameters'} ) ||
	 ( isemptyarray( $_[0]->{'parameters'} ) ) ) {
      checkerr( "kernel panic: the parameter list for the $_[1] '$_[2]' is invalid." ) ;
    }
    my @params = () ;
    for(my $i=0; $i<@{$_[0]->{'parameters'}}; $i++) {
      my $param = $_[0]->{'parameters'}[$i] ;
      if ( ( ! $param ) ||
	   ( isemptyhash( $param ) ) ) {
	checkwarm( "kernel panic: the ".to_th($i+1)." parameter of the $_[1] '$_[2]' is invalid. Removes her from the list." ) ;
      }
      else {
	# name
	$self->_check_name( $param->{'name'}, $_[1], $_[2], '__p'.($i+1).'__' ) ;
	# type
	$self->_check_type( $param->{'type'}, $_[1], $_[2] ) ;
	# location
	$self->_check_location( $param->{'location'}, $_[1], $_[2] ) ;
	# explanation
	$self->_check_line_explanation( $param->{'explanation'}, $_[1], $_[2] ) ;
      }
    }
    delete( $_[0]->{'parameters'} ) ;
    if ( @params ) {
      @{$_[0]->{'parameters'}} = @params ;
    }
  }
}
=pod

=item * _check_explanation()

Takes 3 args:

=over

=item * name (string ref)

=item * type (string)

=item * fullname (string)

=back

=cut
sub _check_explanation($$$) {
  my $self = shift ;
  if ( ( ! ishash($_[0]) ) ||
       ( isemptyhash($_[0]) ) ) {
    checkerr( "kernel panic: the explanation of the $_[1] '$_[2]' is invalid." ) ;
  }
  # location
  $self->_check_location( $_[0]->{'location'}, $_[1], $_[2] ) ;
  # text
  if ( ! $_[0]->{'text'} ) {
    checkwarm( "the explanation text of the $_[1] '$_[2]' is empty." ) ;
    $_[0]->{'text'} = '' ;
  }
}

=pod

=item * _check_line_explanation()

Takes 3 args:

=over

=item * name (string ref)

=item * type (string)

=item * fullname (string)

=back

=cut
sub _check_line_explanation($$$) {
  my $self = shift ;
  if ( ! $_[0] ) {
    checkwarm( "the explanation text of the $_[1] '$_[2]' is empty." ) ;
    $_[0]->{'text'} = '' ;
  }
}

=pod

=item * _check_package()

Takes 3 args:

=over

=item * name (string ref)

=item * type (string)

=item * fullname (string)

=item * alldata (hash ref)

=back

=cut
sub _check_package($$$$) {
  my $self = shift ;
  if ( ! $_[0] ) {
    checkwarm( "no package was assigned to the $_[1] '$_[2]'." ) ;
    return 0 ;
  }
  if ( ! exists $_[3]->{'packages'}{$_[0]} ) {
    checkwarm( "the package definition of '$_[0]' assigned to the $_[1] '$_[2]' is not found." ) ;
    return 0 ;
  }
  return 1 ;
}


=pod

=item * _check_extends()

Takes 3 args:

=over

=item * name (string ref)

=item * type (string)

=item * fullname (string)

=item * classes (hash ref)

=back

=cut
sub _check_extends($$$$) {
  my $self = shift ;
  if ( exists $_[0]->{'extends'} ) {
    my $leave = 0 ;
    PhpDocGen::General::Verbose::three( "Checking extend tag...\n" ) ;
    if ( ! isemptyhash($_[0]->{'extends'}) ) {
      my $mother = $_[0]->{'extends'}{'class'} ;
      if ( ! $mother ) {
	checkwarm( "the name of the $_[1] extended by '$_[2]' is not properly set." ) ;
      }
      else {
	$self->_check_location( $_[0]->{'extends'}{'location'}, $_[1], $_[2] ) ;
	$leave = ( exists( $_[3]->{$mother} ) ) ;
	if ( ! $leave ) {
	  checkwarm( "the $_[1] '$mother', which is extended by '$_[2]', is not found. Assumes the ".
		     "$_[1] '$_[2]' does not extend anything." ) ;
	}
      }
    }
    if ( ! $leave ) {
      delete( $_[0]->{'extends'} ) ;
    }
  }
}

=pod

=item * _check_commontags()

Takes 3 args:

=over

=item * name (string ref)

=item * type (string)

=item * fullname (string)

=item * data (hash ref)

=back

=cut
sub _check_commontags($$$$) {
  my $self = shift ;
  # Gets all common sections
  my @ks = keys %COMMON_SECTIONED_TAGS ;

  foreach my $t (@ks) {
    if ( exists $_[0]->{$t} ) {
      # Build the content of the tag
      my @acontent = () ;
      if ( isarray( $_[0]->{$t} ) ) {
	push( @acontent, @{$_[0]->{$t}} ) ;
      }
      elsif ( $_[0]{$t}->{'text'} ) {
	push( @acontent, \%{$_[0]->{$t}} ) ;
      }
      # Checks all tag values
      PhpDocGen::General::Verbose::three( "Checking common tag".
					  ((@acontent>1) ? "s" : "").
					  " \@$t...\n" ) ;
      my @tags = () ;
      foreach my $tag (@acontent) {
	if ( ( ! ishash($tag) ) ||
	     ( isemptyhash($tag) ) ) {
	  checkerr( "kernel panic: a tag \@$t of the $_[1] '$_[2]' is invalid." ) ;
	}
	# location
	$self->_check_location( $tag->{'location'}, $_[1], $_[2] ) ;
	# text
	if ( ! $tag->{'text'} ) {
	  checkwarm( "a tag \@$t for the $_[1] '$_[2]' is empty. Removes her from the list." ) ;
	}
	else {
	  PhpDocGen::General::Verbose::four( "\t\"".$tag->{'text'}."\"\n" ) ;
	  push @tags, { 'location' => $tag->{'location'},
			'text' => $tag->{'text'},
		      } ;
	}
      }
      @{$_[0]->{$t}} = @tags ;
    }
  }
  # Checks the changelogs
  if ( exists $_[0]->{'logs'} ) {
    if ( ( ! $_[0]->{'logs'} ) ||
	 ( isemptyarray( $_[0]->{'logs'} ) ) ) {
      checkerr( "kernel panic: a tag \@log of the $_[1] '$_[2]' is invalid." ) ;
    }
    PhpDocGen::General::Verbose::three( "Checking changelog".
					((@{$_[0]->{'logs'}}>1) ? "s" : "")."...\n" ) ;
    my @tags = () ;
    foreach my $tag (@{$_[0]->{'logs'}}) {
      if ( ( ! ishash($tag) ) ||
	   ( isemptyhash($tag) ) ) {
	checkerr( "kernel panic: a tag \@log of the $_[1] '$_[2]' is invalid." ) ;
      }
      # location
      $self->_check_location( $tag->{'location'}, $_[1], $_[2] ) ;
      # text
      if ( ! $tag->{'text'} ) {
	checkwarm( "a tag \@log for the $_[1] '$_[2]' is empty. Removes her from the list." ) ;
      }
      # date
      elsif ( ! $tag->{'date'} ) {
	checkwarm( "a tag \@log for the $_[1] '$_[2]' has empty date. Removes her from the list." ) ;
      }
      else {
	PhpDocGen::General::Verbose::four( "\t\"".$tag->{'text'}."\" (".$tag->{'date'}.")\n" ) ;
	push @tags, { 'location' => $tag->{'location'},
		      'text' => $tag->{'text'},
		      'date' => $tag->{'date'},
		    } ;
      }
    }
    @{$_[0]->{'logs'}} = @tags ;
  }
  # Checks the bugs
  if ( exists $_[0]->{'bugs'} ) {
    if ( ( ! $_[0]->{'bugs'} ) ||
	 ( isemptyarray( $_[0]->{'bugs'} ) ) ) {
      checkerr( "kernel panic: a tag \@bug of the $_[1] '$_[2]' is invalid." ) ;
    }
    PhpDocGen::General::Verbose::three( "Checking bug".
					((@{$_[0]->{'bugs'}}>1) ? "s" : "")."...\n" ) ;
    my @tags = () ;
    foreach my $tag (@{$_[0]->{'bugs'}}) {
      if ( ( ! ishash($tag) ) ||
	   ( isemptyhash($tag) ) ) {
	checkerr( "kernel panic: a tag \@bug of the $_[1] '$_[2]' is invalid." ) ;
      }
      # location
      $self->_check_location( $tag->{'location'}, $_[1], $_[2] ) ;
      # text
      if ( ! $tag->{'text'} ) {
	checkwarm( "a tag \@bug for the $_[1] '$_[2]' is empty. Removes her from the list." ) ;
      }
      else {
	PhpDocGen::General::Verbose::four( "\t\"".$tag->{'text'}."\"".
					   ($tag->{'fixed'} ? " (fixed)" : '' ).
					   "\n" ) ;
	push @tags, { 'location' => $tag->{'location'},
		      'text' => $tag->{'text'},
		      'fixed' => $tag->{'fixed'} || 0,
		    } ;
      }
    }
    @{$_[0]->{'bugs'}} = @tags ;
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

package Class::Meta::Class;

# $Id: Class.pm,v 1.25 2004/01/09 03:50:21 david Exp $

=head1 NAME

Class::Meta::Class - Class::Meta class introspection

=head1 SYNOPSIS

  # Assuming MyApp::Thingy was generated by Class::Meta.
  my $class = MyApp::Thingy->class;
  my $thingy = MyApp::Thingy->new;

  print "Examining object of class ", $class->package, $/;

  print "\nConstructors:\n";
  for my $ctor ($class->constructors) {
      print "  o ", $ctor->name, $/;
  }

  print "\nAttributes:\n";
  for my $attr ($class->attributes) {
      print "  o ", $attr->name, " => ", $attr->call_get($thingy) $/;
  }

  print "\nMethods:\n";
  for my $meth ($class->methods) {
      print "  o ", $meth->name, $/;
  }

=head1 DESCRIPTION

Object of this class describe classes created by Class::Meta. They contain
everything you need to know about a class to be able to put objects of that
class to good use. In addition to retrieving metadata about the class itself,
you can retrieve objects that describe the constructors, attributes, and
methods of the class. See C<Class::Meta|Class::Meta> for a fuller description
of the utility of the Class::Meta suite of modules.

Class::Meta::Class objects are created by Class::Meta; they are never
instantiated directly in client code. To access the class object for a
Class::Meta-generated class, simply call its C<class> method.

=cut

##############################################################################
# Dependencies                                                               #
##############################################################################
use strict;
use Class::ISA ();
use Class::Meta;
use Class::Meta::Attribute;
use Class::Meta::Method;

##############################################################################
# Package Globals                                                            #
##############################################################################
our $VERSION = "0.10";
our @CARP_NOT = qw(Class::Meta);

##############################################################################
# Private Package Globals
##############################################################################
my $croak = sub { require Carp; Carp::croak(@_) };

##############################################################################
# Constructors                                                               #
##############################################################################
# We don't document new(), since it's a protected method, really.
{
    # We'll keep the class specifications in here.
    my %specs;

##############################################################################
    sub new {
        my ($pkg, $spec) = @_;
        # Check to make sure that only Class::Meta or a subclass is
        # constructing a Class::Meta::Class object.
        my $caller = caller;
        $croak->("Package '$caller' cannot create ", __PACKAGE__,
                 " objects")
          unless UNIVERSAL::isa($caller, 'Class::Meta');

        # Check to make sure we haven't created this class already.
        $croak->("Class object for class '$spec->{package}' already exists")
          if $specs{$spec->{package}};

        # Save a reference to the spec hash ref.
        $specs{$spec->{package}} = $spec;

        # Okay, create the class object.
        my $self = bless { package => $spec->{package} }, ref $pkg || $pkg;

        # Copy its parents' attributes and return.
        return $self->_inherit('attr');
    }

##############################################################################
# Instance Methods
##############################################################################

=head1 INTERFACE

=head2 Instance Methods

=head3 package

  my $pkg = $class->package;

Returns the name of the package that the Class::Meta::Class object describes.

=head3 key

  my $key = $class->key;

Returns the key name that uniquely identifies the class across the
application. The key name may simply be the same as the package name.

=head3 name

  my $name = $class->name;

Returns the name of the the class. This should generally be a descriptive
name, rather than a package name.

=head3 desc

  my $desc = $class->desc;

Returns a description of the class.

=cut

    sub package { $_[0]->{package}                 }
    sub key     { $specs{$_[0]->{package}}->{key}  }
    sub name    { $specs{$_[0]->{package}}->{name} }
    sub desc    { $specs{$_[0]->{package}}->{desc} }

##############################################################################

=head3 is_a

  if ($class->is_a('MyApp::Base')) {
      print "All your base are belong to us\n";
  }

This method returns true if the object or package name passed as an argument
is an instance of the class described by the Class::Meta::Class object or one
of its subclasses. Functionally equivalent to
C<< $class->package->isa($pkg) >>, but more efficient.

=cut

    # Check inheritance.
    sub is_a { UNIVERSAL::isa($_[0]->{package}, $_[1]) }

##############################################################################
# Accessors to get at the constructor, attribute, and method objects.
##############################################################################

=head3 constructors

  my @constructors = $class->constructors;
  my $ctor = $class->constructors($ctor_name);
  @constructors = $class->constructors(@ctor_names);

Provides access to the Class::Meta::Constructor objects that describe the
constructors for the class. When called with no arguments, it returns all of
the constructor objects. When called with a single argument, it returns the
constructor object for the constructor with the specified name. When called
with a list of arguments, returns all of the constructor objects with the
specified names.

=cut

    sub constructors {
        my $self = shift;
        my $spec = $specs{$self->{package}};
        my $objs = $spec->{constructors};
        # Explicit list requested.
        my $list = @_ ? \@_
          # List of protected interface objects.
          : UNIVERSAL::isa(scalar caller, $self->{package}) ? $spec->{prot_ctor_ord}
          # List of public interface objects.
          : $spec->{ctor_ord};
        return unless $list;
        return @$list == 1 ? $objs->{$list->[0]} : @{$objs}{@$list};
    }

##############################################################################

=head3 attributes

  my @attributes = $class->attributes;
  my $attr = $class->attributes($attr_name);
  @attributes = $class->attributes(@attr_names);

Provides access to the Class::Meta::Attribute objects that describe the
attributes for the class. When called with no arguments, it returns all of the
attribute objects. When called with a single argument, it returns the
attribute object for the attribute with the specified name. When called with a
list of arguments, returns all of the attribute objects with the specified
names.

=cut

    sub attributes {
        my $self = shift;
        my $spec = $specs{$self->{package}};
        my $objs = $spec->{attrs};
        # Explicit list requested.
        my $list = @_ ? \@_
          # List of protected interface objects.
          : UNIVERSAL::isa(scalar caller, $self->{package}) ? $spec->{prot_attr_ord}
          # List of public interface objects.
          : $spec->{attr_ord};
        return unless $list;
        return @$list == 1 ? $objs->{$list->[0]} : @{$objs}{@$list};
    }

##############################################################################

=head3 methods

  my @methods = $class->methods;
  my $meth = $class->methods($meth_name);
  @methods = $class->methods(@meth_names);

Provides access to the Class::Meta::Method objects that describe the methods
for the class. When called with no arguments, it returns all of the method
objects. When called with a single argument, it returns the method object for
the method with the specified name. When called with a list of arguments,
returns all of the method objects with the specified names.

=cut

    sub methods {
        my $self = shift;
        my $spec = $specs{$self->{package}};
        my $objs = $spec->{meths};
        # Explicit list requested.
        my $list = @_ ? \@_
          # List of protected interface objects.
          : UNIVERSAL::isa(scalar caller, $self->{package}) ? $spec->{prot_meth_ord}
          # List of public interface objects.
          : $spec->{meth_ord};
        return unless $list;
        return @$list == 1 ? $objs->{$list->[0]} : @{$objs}{@$list};
    }

##############################################################################
# Private Methods.
##############################################################################

    sub build {
        my $self = shift;

        # Check to make sure that only Class::Meta or a subclass is building
        # attribute accessors.
        my $caller = caller;
        $croak->("Package '$caller' cannot call " . __PACKAGE__ . "->build")
          unless UNIVERSAL::isa($caller, 'Class::Meta');
        $self->_inherit(qw(ctor meth));
    }

##############################################################################
    sub _inherit {
        my $self = shift;
        my $spec = $specs{$self->{package}};

        # Get a list of all of the parent classes.
        my @classes = reverse Class::ISA::self_and_super_path($spec->{package});

        # For each metadata class, copy the parents' objects.
        for my $key (@_) {
            my (@things, @ord, @prot, %sord, %sprot);
            for my $super (@classes) {
                push @things, %{ $specs{$super}{"${key}s"} }
                  if $specs{$super}{$key . 's'};
                push @ord, grep { not $sord{$_}++ }
                  @{ $specs{$super}{"$key\_ord"} }
                  if $specs{$super}{"$key\_ord"};
                push @prot, grep { not $sprot{$_}++ }
                  @{ $specs{$super}{"prot_$key\_ord"} }
                  if $specs{$super}{"prot_$key\_ord"};
            }

            $spec->{"${key}s"}         = { @things } if @things;
            $spec->{"$key\_ord"}      = \@ord       if @ord;
            $spec->{"prot_$key\_ord"} = \@prot      if @prot;
        }
        return $self;
    }
}

1;
__END__

=head1 AUTHOR

David Wheeler <david@kineticode.com>

=head1 SEE ALSO

Other classes of interest within the Class::Meta distribution include:

=over 4

=item L<Class::Meta|Class::Meta>

=item L<Class::Meta::Constructor|Class::Meta::Constructor>

=item L<Class::Meta::Attribute|Class::Meta::Attribute>

=item L<Class::Meta::Method|Class::Meta::Method>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2004, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

package Fey::SQL::Intersect;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.45';

use Moose 2.1200;

with 'Fey::Role::SetOperation' => { keyword => 'INTERSECT' };

with 'Fey::Role::SQL::Cloneable';

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents an INTERSECT operation

__END__

=head1 SYNOPSIS

  my $intersect = Fey::SQL->new_intersect;

  $intersect->intersect( Fey::SQL->new_select->select(...),
                         Fey::SQL->new_select->select(...),
                         Fey::SQL->new_select->select(...),
                         ...
                       );

  $intersect->order_by( $part_name, 'DESC' );
  $intersect->limit(10);

  print $intersect->sql($dbh);

=head1 DESCRIPTION

This class represents an INTERSECT set operator.

=head1 METHODS

See L<Fey::Role::SetOperation> for all methods.

=head1 ROLES

=over 4

=item * L<Fey::Role::SetOperation>

=item * L<Fey::Role::SQL::Cloneable>

=back

=head1 BUGS

See L<Fey> for details on how to report bugs.

=cut

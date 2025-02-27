package Fey::Role::Named;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.45';

use Moose::Role;

requires 'name';

1;

# ABSTRACT: A role for things with a name

__END__

=head1 SYNOPSIS

  use Moose 2.1200;

  with 'Fey::Role::Named';

=head1 DESCRIPTION

This role has no methods or attributes of its own, it simply requires
that the consuming class provide a C<name()> method.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=cut

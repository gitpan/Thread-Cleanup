package Thread::Cleanup;

use 5.008;

use strict;
use warnings;

=head1 NAME

Thread::Cleanup - Hook thread destruction.

=head1 VERSION

Version 0.05

=cut

our $VERSION;

BEGIN {
 $VERSION = '0.05';
 require XSLoader;
 XSLoader::load(__PACKAGE__, $VERSION);
}

=head1 SYNOPSIS

    use Thread::Cleanup;

    use threads;

    Thread::Cleanup::register {
     my $tid = threads->tid();
     warn "Thread $tid finished\n";
    };

=head1 DESCRIPTION

This module allows you to hook thread destruction without fiddling with the internals of L<threads>.

It acts globally on all the threads that may spawn anywhere in your program, with the exception of the main thread.

=head1 FUNCTIONS

=head2 C<register>

    register { ... };
    &register($coderef);

Specify that the given block or code reference C<$coderef> will have to be called (in void context, without arguments) every time a thread finishes its job.
More precisely,

=over 4

=item *

it will always be called before the joining for joined threads ;

=item *

it will be called for detached threads if and only if they terminate before the main thread, and the hook will then fire at C<END> time ;

=item *

it won't trigger for the destruction of the main thread.

=back

=cut

my @callbacks;

sub register (&) { push @callbacks, shift }

sub _CLEANUP { $_->() for @callbacks }

=head1 EXPORT

None.

=head1 DEPENDENCIES

L<perl> 5.8.

A C compiler.
This module may happen to build with a C++ compiler as well, but don't rely on it, as no guarantee is made in this regard.

L<threads> 1.07.

L<XSLoader>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-thread-cleanup at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Thread-Cleanup>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Thread::Cleanup

=head1 ACKNOWLEDGEMENTS

Inspired by a question from TonyC on #p5p.

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2013 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Thread::Cleanup

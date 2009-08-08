package Alien::SDL;
use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

Alien::SDL - building, finding and using SDL binaries

=head1 SYNOPSIS

    use Alien::SDL <options>;

    my $version = Alien::SDL->version;
    my $config = Alien::SDL->config;
    my $compiler = Alien::SDL->compiler;
    my $linker = Alien::SDL->linker;
    my $include_path = Alien::SDL->include_path;
    my $defines = Alien::SDL->defines;
    my $cflags = Alien::SDL->c_flags;
    my $linkflags = Alien::SDL->link_flags;
    my $libraries = Alien::SDL->libraries( qw(sdl mixer image sound net ttf gfx svg) );
    my @libraries = Alien::SDL->link_libraries( qw(sdl mixer image sound net ttf gfx svg));
    my @implib = Alien::SDL->import_libraries( qw(sdl mixer image sound net ttf gfx svg) );
    my @shrlib = Alien::SDL->shared_libraries( qw(sdl mixer image sound net ttf gfx svg) );
    my @keys = Alien::SDL->library_keys; # 'sdl', 'mixer', ...
    my $library_path = Alien::SDL->shared_library_path;
    my $key = Alien::SDL->key;
    my $prefix = Alien::SDL->prefix;

=head1 DESCRIPTION

Please see L<Alien> for the manifesto of the Alien namespace.

In short C<Alien::SDL> can be used to detect and get
configuration settings from an installed SDL and related libraries .
=cut

#################### main pod documentation begin ###################
=head1 BUGS
Please post issues and bugs at http://github.com/kthakore/Alien_SDL/issues


=head1 SUPPORT



=head1 AUTHOR

    Kartik Thakore
    CPAN ID: KTHAKORE
    none
    Thakore.Kartik@gmail.com
    http://github.com/kthakore

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value


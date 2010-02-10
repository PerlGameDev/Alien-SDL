package Alien::SDL;
use strict;
use warnings;
use Alien::SDL::ConfigData;
use File::ShareDir qw(dist_dir);
use File::Spec;
use File::Spec::Functions qw(catdir catfile );

=head1 NAME

Alien::SDL - building, finding and using SDL binaries

=head1 VERSION

Version 0.8.0

=cut

our $VERSION = '0.8.0';

=head1 SYNOPSIS

Alien::SDL tries (in given order) during its installation:

=over

=item * Locate an already installed SDL + related libraries (via 'sdl-config')

=item * Check for SDL libs in directory specified by SDL_INST_DIR variable

=item * Download prebuilt SDL binaries (if available for your platform)

=item * Build SDL binaries from source codes (if possible on your system)

=back

Later you can use Alien::SDL in your module that needs to link agains SDL
and/or related libraries like this:

    # Example of Makefile.pl
    use ExtUtils::MakeMaker;
    use Alien::SDL;

    WriteMakefile(
      NAME         => 'Any::SDL::Module',
      VERSION_FROM => 'lib/Any/SDL/Module.pm',
      LIBS         => Alien::SDL->config('libs'),
      INC          => Alien::SDL->config('cflags'),
      # + additional params
    );

=head1 DESCRIPTION

Please see L<Alien> for the manifesto of the Alien namespace.

In short C<Alien::SDL> can be used to detect and get
configuration settings from an installed SDL and related libraries.
Based on your platform it offers the possibility to download and
install prebuilt binaries or to build SDL & co. from source codes.

The important facts:

=over

=item * The module does not modify in any way the already existing SDL
installation on your system.

=item * If you reinstall SDL libs on your system you do not need to
reinstall Alien::SDL (providing that you use the same directory for
the new installation).

=item * The prebuild binaries and/or binaries built from sources are always
installed into perl module's 'share' directory.

=item * If you use prebuild binaries and/or binaries built from sources
it happens that some of the dynamic libraries (*.so, *.dll) will not
automaticly loadable as they will be stored somewhere under perl module's
'share' directory. To handle this scenario Alien::SDL offers some special
functionality (see below).

=back

=head1 METHODS

=head2 sdl_config()

This function is B<the only public interface to this module>. Basic
functionality works in a very similar maner to 'sdl-config' script:

    Alien::SDL->config('prefix');   # gives the same string as 'sdl-config --prefix'
    Alien::SDL->config('version');  # gives the same string as 'sdl-config --version'
    Alien::SDL->config('libs');     # gives the same string as 'sdl-config --libs'
    Alien::SDL->config('cflags');   # gives the same string as 'sdl-config --cflags'

On top of that this function supports special parameters:

    Alien::SDL->config('shared_libs');

Returns the list of full paths to shared libraries (*.so, *.dll) that will be
required for running the resulting binaries you have linked with SDL libs.

=head1 BUGS

Please post issues and bugs at L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-SDL>

=head1 AUTHOR

    Kartik Thakore
    CPAN ID: KTHAKORE
    Thakore.Kartik@gmail.com
    http://yapgh.blogspot.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

### main function - external interface
sub config
{
  my ($package, $param) = @_;
  return _sdl_config_via_script($param) if(Alien::SDL::ConfigData->config('script'));
  return _sdl_config_via_config_data($param) if(Alien::SDL::ConfigData->config('config'));
}

### internal functions
sub _sdl_config_via_script
{
  my ($param) = @_;
  my $devnull = File::Spec->devnull();
  my $script = Alien::SDL::ConfigData->config('script');
  return unless ($script && ($param =~ /[a-z0-9_]*/i));
  return `$script --$param 2>$devnull`;
}

sub _sdl_config_via_config_data
{
  my ($param) = @_;
  my $share_dir = dist_dir('Alien-SDL');
  my $subdir = Alien::SDL::ConfigData->config('share_subdir');
  return unless $subdir;
  my $real_prefix = catdir($share_dir, $subdir);
  return unless ($param =~ /[a-z0-9_]*/i);
  my $val = Alien::SDL::ConfigData->config('config')->{$param};
  return unless $val;
  $val =~ s/\@PrEfIx\@/$real_prefix/g;
  return $val;
}

1;

package Alien::SDL;
use strict;
use warnings;
use Alien::SDL::ConfigData;
use File::ShareDir;


our $VERSION = '0.7.8';

=head1 NAME

Alien::SDL - building, finding and using SDL binaries

=head1 SYNOPSIS

Just gets windows deps for strawberry perl

=head1 DESCRIPTION

Please see L<Alien> for the manifesto of the Alien namespace.

In short C<Alien::SDL> can be used to detect and get
configuration settings from an installed SDL and related libraries .
=cut

### main function - external interface
sub sdl_config
{
  my $itype = Alien::SDL::ConfigData->config('install_type');
  if($itype eq 'using_config_script') {
    return _sdl_config_via_script();
  }
  elsif($itype eq 'using_config_data') {
    return _sdl_config_via_config_data();
  }
  else {
    return undef;
  }
}

### internal functions
sub _sdl_config_via_script
{

}

sub _sdl_config_via_config_data
{
  #fetch sharedir
  #read ConfigData
  #create 
}

#################### main pod documentation begin ###################
=head1 BUGS

Please post issues and bugs at L<http://sdlperl.ath.cx/projects/SDLPerl/>

=head1 SUPPORT



=head1 AUTHOR

    Kartik Thakore
    CPAN ID: KTHAKORE
    none
    Thakore.Kartik@gmail.com
    http://yapgh.blogspot.com

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


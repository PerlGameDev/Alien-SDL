package My::Builder::Unix;

use strict;
use warnings;
use base 'My::Builder';

use File::Spec::Functions qw(catdir catfile rel2abs);
use Config;

my $inc_lib_candidates = {
  '/usr/local/include/SDL11'  => '/usr/local/lib', #freebsd
  '/usr/pkg/include',         => '/usr/local/lib', #netbsd
  '/usr/pkg/include/SDL'      => '/usr/local/lib', #netbsd
  '/usr/pkg/include/smpeg'    => '/usr/local/lib', #netbsd
  '/usr/local/include'        => '/usr/local/lib',
  '/usr/local/include/gl'     => '/usr/local/lib',
  '/usr/local/include/GL'     => '/usr/local/lib',
  '/usr/local/include/SDL'    => '/usr/local/lib',
  '/usr/local/include/smpeg'  => '/usr/local/lib',
  '/usr/include'              => '/usr/lib',
  '/usr/include/gl'           => '/usr/lib',
  '/usr/include/GL'           => '/usr/lib',
  '/usr/include/SDL'          => '/usr/lib',
  '/usr/include/smpeg'        => '/usr/lib',
  '/usr/X11R6/include'        => '/usr/X11R6/lib',
  '/usr/X11R6/include/gl'     => '/usr/X11R6/lib',
  '/usr/X11R6/include/GL'     => '/usr/X11R6/lib',
};

sub get_additional_cflags {
  my $self = shift;
  my @list = ();
  ### any platform specific -L/path/to/libs shoud go here
  for (keys %$inc_lib_candidates) {
    push @list, "-I$_" if (-d $_);
  }
  return join(' ', @list);
}

sub get_additional_libs {
  my $self = shift;
  ### any platform specific -L/path/to/libs shoud go here
  my @list = ();
  my %rv; # putting detected dir into hash to avoid duplicates
  for (keys %$inc_lib_candidates) {
    my $ld = $inc_lib_candidates->{$_};
    $rv{"-L$ld"} = 1 if ((-d $_) && (-d $ld));
  }
  push @list, (keys %rv);
  push @list, '-lpthread' if ($^O eq 'openbsd');
  return join(' ', @list);
}

sub can_build_binaries_from_sources {
  my $self = shift;
  return 1; # yes we can
}

sub build_binaries {
  my( $self, $build_out, $build_src ) = @_;
  my $bp = $self->notes('build_params');
  foreach my $pack (@{$bp->{members}}) {
    print "BUILDING package '" . $pack->{dirname} . "'...\n";
    my $srcdir = catfile($build_src, $pack->{dirname});
    my $prefixdir = rel2abs($build_out);
    $self->config_data('build_prefix', $prefixdir); # save it for future Alien::SDL::ConfigData

    chdir $srcdir;

    # do './configure ...'
    my $run_configure = 'y';
    $run_configure = $self->prompt("Run ./configure for '$pack->{pack}' again?", "n") if (-f "config.status");
    if (lc($run_configure) eq 'y') {
      my $cmd = $self->_get_configure_cmd($pack->{pack}, $prefixdir);
      print "Configuring $pack->{pack}...\n";
      print "(cmd: $cmd)\n";
      $self->do_system($cmd) or die "###ERROR### [$?] during ./configure ... ";
    }

    # do 'make install'
    my $cmd = "make install";
    print "Running make install $pack->{pack}...\n";
    print "(cmd: $cmd)\n";
    $self->do_system($cmd) or die "###ERROR### [$?] during make ... ";

    chdir $self->base_dir();
  }
  return 1;
}

### internal helper functions

sub _get_configure_cmd {
  my ($self, $pack, $prefixdir) = @_;
  my $extra = '';
  my $extra_cflags = "-I$prefixdir/include";
  my $extra_ldflags = "-L$prefixdir/lib";  
  my $cmd;

  # NOTE: all ugly IFs concerning ./configure params have to go here

  if(($pack eq 'SDL_gfx') && $Config{archname} =~ /powerpc|ppc|64|2level/i) {
    $extra .= ' --disable-mmx';
  }
  
  if(($pack eq 'SDL') && ($Config{archname} =~ /(powerpc|ppc)/)) {
    $extra .= ' --disable-video-ps3';
  }

  if($pack =~ /^SDL_/) {
    $extra .= " --with-sdl-prefix=$prefixdir";
  }

  if(($pack eq 'SDL') && ($^O eq 'cygwin')) {
    # kmx experienced troubles while cygwin build when nasm was present in PATH
    $extra .= " --disable-nasm";
  }

  if(($pack eq 'SDL') && ($^O eq 'darwin')) {
    # fix for many MacOS CPAN tester reports saying "error: X11/Xlib.h: No such file or directory"
    $extra_cflags .= ' -I/usr/X11R6/include';
    $extra_ldflags .= ' -L/usr/X11R6/lib';
  }
  
  if($pack =~ /^zlib/) {
    # does not support params CFLAGS=...
    $cmd = "./configure --prefix=$prefixdir";
  }
  else {
    $cmd = "./configure --prefix=$prefixdir --enable-static=no --enable-shared=yes $extra" .
           " CFLAGS=\"$extra_cflags\" LDFLAGS=\"$extra_ldflags\"";
  }
  
  # we need to have $prefixdir/bin in PATH while running ./configure
  $cmd = "PATH=\"$prefixdir/bin:\$PATH\" $cmd";
  
  return $cmd;
}

1;

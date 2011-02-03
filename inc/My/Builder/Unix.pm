package My::Builder::Unix;

use strict;
use warnings;
use base 'My::Builder';

use File::Spec::Functions qw(catdir catfile rel2abs);
use My::Utility qw(check_header check_prereqs_libs check_prereqs_tools);
use Config;

# $Config{cc} tells us to use gcc-4, but it is not there by default
if($^O eq 'cygwin') {
  $My::Utility::cc = 'gcc';
}

my $inc_lib_candidates = {
  '/usr/local/include'       => '/usr/local/lib',
  '/usr/local/include/smpeg' => '/usr/local/lib',
  '/usr/pkg/include'         => '/usr/pkg/lib',
};

$inc_lib_candidates->{'/usr/pkg/include/smpeg'}   = '/usr/local/lib' if -f '/usr/pkg/include/smpeg/smpeg.h';
#$inc_lib_candidates->{'/usr/local/include/smpeg'} = '/usr/local/lib' if -f '/usr/local/include/smpeg/smpeg.h';
$inc_lib_candidates->{'/usr/include/smpeg'}       = '/usr/lib'       if -f '/usr/include/smpeg/smpeg.h';
$inc_lib_candidates->{'/usr/X11R6/include'}       = '/usr/X11R6/lib' if -f '/usr/X11R6/include/GL/gl.h';
#$inc_lib_candidates->{'/usr/local/include'}       = '/usr/local/lib' if -f '/usr/local/include/png.h';
#$inc_lib_candidates->{'/usr/local/include'}       = '/usr/local/lib' if -f '/usr/local/include/tiff.h';
#$inc_lib_candidates->{'/usr/local/include'}       = '/usr/local/lib' if -f '/usr/local/include/jpeglib.h';

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
    if(($pack->{pack} =~ m/^(png)$/ && check_prereqs_libs($pack->{pack}))
    || ($pack->{pack} =~ m/^zlib$/  && check_prereqs_libs('z'))) {
      print "SKIPPING package '" . $pack->{dirname} . "' (already installed)...\n";
    }
    elsif($pack->{pack} =~ m/^(SDL_mixer)$/ && !$self->_is_gnu_make($self->_get_make)) {
      print "SKIPPING package '" . $pack->{dirname} . "' (GNU Make needed)...\n";
    }
    elsif($pack->{pack} =~ m/^(SDL_Pango)$/ && !check_prereqs_tools('pkg-config')) {
      print "SKIPPING package '" . $pack->{dirname} . "' (pkg-config needed)...\n";
    }
    else {
      print "BUILDING package '" . $pack->{dirname} . "'...\n";
      my $srcdir = catfile($build_src, $pack->{dirname});
      my $prefixdir = rel2abs($build_out);
      $self->config_data('build_prefix', $prefixdir); # save it for future Alien::SDL::ConfigData

      chdir $srcdir;

      # do './configure ...'
      my $run_configure = 'y';
      $run_configure = $self->prompt("Run ./configure for '$pack->{pack}' again?", "y") if (-f "config.status");
      if (lc($run_configure) eq 'y') {
        my $cmd = $self->_get_configure_cmd($pack->{pack}, $prefixdir);
        print "Configuring package '$pack->{pack}'...\n";
        print "(cmd: $cmd)\n";
        unless($self->do_system($cmd)) {
          if(-f "config.log" && open(CONFIGLOG, "<config.log")) {
            print "config.log:\n";
            print while <CONFIGLOG>;
            close(CONFIGLOG);
          }
          die "###ERROR### [$?] during ./configure for package '$pack->{pack}'...";
        }
      }

      # do 'make install'
      my @cmd = ($self->_get_make, 'install');
      print "Running make install $pack->{pack}...\n";
      print "(cmd: ".join(' ',@cmd).")\n";
      $self->do_system(@cmd) or die "###ERROR### [$?] during make ... ";

      chdir $self->base_dir();
    }
  }
  return 1;
}

### internal helper functions

sub _get_configure_cmd {
  my ($self, $pack, $prefixdir) = @_;
  my $extra                     = '';
  my $extra_cflags              = "-I$prefixdir/include";
  my $extra_ldflags             = "-L$prefixdir/lib";  
  my $cmd;

  # NOTE: all ugly IFs concerning ./configure params have to go here

  if(($pack eq 'SDL_gfx') && $Config{archname} =~ /(powerpc|ppc|64|2level|alpha)/i) {
    $extra .= ' --disable-mmx';
  }
  
  if(($pack eq 'SDL') && ($Config{archname} =~ /(powerpc|ppc)/)) {
    $extra .= ' --disable-video-ps3';
  }

  if($pack eq 'SDL' && $^O eq 'darwin' && !check_header($self->get_additional_cflags, 'X11/Xlib.h')) {
    $extra .= ' --without-x';
  }

  if($pack eq 'SDL' && !check_header($self->get_additional_cflags, 'X11/extensions/XShm.h')) {
    $extra        .= ' --disable-video-x11-xv';
    $extra_cflags .= ' -DNO_SHARED_MEMORY';
  }

  if($pack eq 'SDL_image' && $^O eq 'darwin') {
    $extra .= ' --disable-sdltest';
  }

  if(($pack eq 'SDL') && ($Config{archname} =~ /solaris/) && !check_header($extra_cflags, 'sys/audioio.h')) {
    $extra .= ' --disable-audio';
  }

  if($pack =~ /^SDL_/) {
    $extra .= " --with-sdl-prefix=$prefixdir";
  }

  if($pack =~ /^SDL/ && -d '/usr/X11R6/lib' && -d '/usr/X11R6/include') {
    $extra_cflags  .= ' -I/usr/X11R6/include';
    $extra_ldflags .= ' -L/usr/X11R6/lib';
  }

  if(($pack eq 'SDL') && ($^O eq 'cygwin')) {
    # kmx experienced troubles while cygwin build when nasm was present in PATH
    $extra .= " --disable-nasm";
  }

  if($pack eq 'jpeg') {
    # otherwise libtiff will complain about invalid version number on dragonflybsd
    $extra .= " --disable-ld-version-script";
  }

  ### This was intended as a fix for http://www.cpantesters.org/cpan/report/7064012
  ### Unfortunately does not work.
  #
  #if(($pack eq 'SDL') && ($^O eq 'darwin')) {
  #  # fix for many MacOS CPAN tester reports saying "error: X11/Xlib.h: No such file or directory"
  #  $extra_cflags .= ' -I/usr/X11R6/include';
  #  $extra_ldflags .= ' -L/usr/X11R6/lib';
  #}

  if($pack =~ /^zlib/) {
    # does not support params CFLAGS=...
    $cmd = "./configure --prefix=$prefixdir";
  }
  else {
    $cmd = "./configure --prefix=$prefixdir --enable-static=no --enable-shared=yes $extra" .
           " CFLAGS=\"$extra_cflags\" LDFLAGS=\"$extra_ldflags\"";
  }

  if($pack ne 'SDL' && $^O eq 'openbsd') {
    $cmd = "LD_LIBRARY_PATH=\"$prefixdir/lib:\$LD_LIBRARY_PATH\" $cmd";
  }

  # we need to have $prefixdir/bin in PATH while running ./configure
  $cmd = "PATH=\"$prefixdir/bin:\$PATH\" $cmd";

  return $cmd;
}

sub _get_make {
  my ($self) = @_;
  my @try = ($Config{gmake}, 'gmake', 'make', $Config{make});
  my %tested;
  print "Gonna detect GNU make:\n";
  foreach my $name ( @try ) {
    next unless $name;
    next if $tested{$name};
    $tested{$name} = 1;
    print "- testing: '$name'\n";
    if ($self->_is_gnu_make($name)) {
      print "- found: '$name'\n";
      return $name
    }
  }
  print "- fallback to: 'make'\n";
  return 'make';
}

sub _is_gnu_make {
  my ($self, $name) = @_;
  my $devnull = File::Spec->devnull();
  my $ver = `$name --version 2> $devnull`;
  if ($ver =~ /GNU Make/i) {
    return 1;
  }
  return 0;
}

1;

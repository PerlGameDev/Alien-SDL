package My::Builder::Unix;

use strict;
use warnings;
use base 'My::Builder';

use File::Spec::Functions qw(catdir catfile rel2abs);

sub can_build_binaries_from_sources { 1 } # yes we can

sub build_binaries {
  my( $self, $build_out, $build_src ) = @_;
  my $bp = $self->notes('build_params');
  foreach my $pack (@{$bp->{members}}) {
    print "BUILDING package '" . $pack->{dirname} . "'...\n";
    my $srcdir = catfile($build_src, $pack->{dirname});
    my $prefixdir = rel2abs($build_out);
   $self->config_data('build_prefix', $prefixdir); # save it for future Alien::SDL::ConfigData

    # do './configure ...'
    my $run_configure = 'y';
    $run_configure = $self->prompt("Run ./configure again?", "n") if (-f "$srcdir/config.log");
    if (lc($run_configure) eq 'y') {
      my $cmd = "./configure --prefix=$prefixdir CFLAGS=-I$prefixdir/include LDFLAGS=-L$prefixdir/lib";
      print "Configuring $pack->{pack}...\n";
      print "(cmd: $cmd)\n";
      chdir $srcdir;
      ###$self->do_system($cmd) or die '###ERROR### ', $?;
      chdir $self->base_dir();
    }

    # do 'make install'
    my $cmd = "make install";
    print "Running make install $pack->{pack}...\n";
    print "(cmd: $cmd)\n";
    chdir $srcdir;
    ###$self->do_system($cmd) or die '###ERROR### ', $?;
    chdir $self->base_dir();
  }
  return 1;
}

1;

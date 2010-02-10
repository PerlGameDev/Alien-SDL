package My::Builder;

use strict;
use warnings;
use base 'Module::Build';

use File::Spec::Functions qw(catdir catfile);
use File::Path qw(make_path remove_tree);
use File::Fetch;
use Archive::Extract;
use Digest::SHA1;
use Config;

sub ACTION_build {
  my $self = shift;
  # as we want to wipe 'share' dir during 'Build clean' we has
  # to recreate 'share' dir at this point if it does not exist
  mkdir 'share' unless(-d 'share');
  $self->add_to_cleanup('share');
  $self->SUPER::ACTION_build;
}

sub ACTION_code {
  my $self = shift;
  $self->SUPER::ACTION_code;
  
  my $bp = $self->notes('build_params');
  die "###ERROR### Cannot continue build_params not defined" unless defined($bp);

  # check marker
  return if (-f 'build_done');

  # important directories
  my $download     = 'download';
  my $patches      = 'patches';
  my $share_subdir = 'build_out_' . $self->{properties}->{dist_version};
  my $build_out    = catfile('share', $share_subdir);
  my $build_src    = 'build_src';
  $self->add_to_cleanup($build_src, $build_out);

  # save some data into future Alien::SDL::ConfigData
  $self->config_data('share_subdir', $share_subdir);
  $self->config_data('build_params', $bp);
  $self->config_data('build_cc', $Config{cc});
  $self->config_data('build_arch', $Config{archname});
  $self->config_data('build_os', $^O);

  if($bp->{buildtype} eq 'use_config_script') {
    $self->config_data('script', $bp->{script});
  }
  elsif($bp->{buildtype} eq 'use_prebuilt_binaries') {
    # all the following functions die on error, no need to test ret values
    $self->fetch_binaries($download);
    $self->clean_dir($build_out);
    $self->extract_binaries($download, $build_out);
    $self->set_config_data($build_out);
  }
  elsif($bp->{buildtype} eq 'build_from_sources' ) {
    # all the following functions die on error, no need to test ret values
    $self->fetch_sources($download);
    $self->extract_sources($download, $patches, $build_src);
    $self->clean_dir($build_out);
    $self->build_binaries($build_out, $build_src);
    $self->set_config_data($build_out);
  }

  # mark sucessfully finished build
  $self->touch_build_done_marker;
}

sub fetch_file {
  my ($self, $url, $sha1sum, $download) = @_;
  die "###ERROR### _fetch_file undefined url\n" unless $url;
  die "###ERROR### _fetch_file undefined sha1sum\n" unless $sha1sum;
  my $ff = File::Fetch->new(uri => $url);
  my $fn = catfile($download, $ff->file);
  if (-e $fn) {
    print "Checking checksum for already existing '$fn'...\n";
    return 1 if $self->check_sha1sum($fn, $sha1sum);
    unlink $fn; #exists but wrong checksum
  }
  print "Fetching '$url'...\n";
  my $fullpath = $ff->fetch(to => $download);
  die "###ERROR### Unable to fetch '$url'" unless $fullpath;
  if (-e $fn) {
    print "Checking checksum for '$fn'...\n";
    return 1 if $self->check_sha1sum($fn, $sha1sum);
    die "###ERROR### Checksum failed '$fn'";
  }
  die "###ERROR### _fetch_file failed '$fn'";
}

sub fetch_binaries {
  my ($self, $download) = @_;
  my $bp = $self->notes('build_params');
  $self->fetch_file($bp->{url}, $bp->{sha1sum}, $download);
}

sub fetch_sources {
  my ($self, $download) = @_;
  my $bp = $self->notes('build_params');
  $self->fetch_file($_->{url}, $_->{sha1sum}, $download) foreach (@{$bp->{members}});
}

sub extract_binaries {
  my ($self, $download, $build_out) = @_;
  my $bp = $self->notes('build_params');
  my $archive = catfile($download, File::Fetch->new(uri => $bp->{url})->file);
  print "Extracting $archive...\n";
  my $ae = Archive::Extract->new( archive => $archive );
  die "###ERROR###: Cannot extract $archive ", $ae->error unless $ae->extract(to => $build_out);
}

sub extract_sources {
  my ($self, $download, $patches, $build_src) = @_;
  my $bp = $self->notes('build_params');
  foreach my $pack (@{$bp->{members}}) {
    my $srcdir = catfile($build_src, $pack->{dirname});
    my $unpack = 'y';
    $unpack = $self->prompt("Dir '$srcdir' exists, wanna replace with clean sources?", "n") if (-d $srcdir);
    if (lc($unpack) eq 'y') {
      my $archive = catfile($download, File::Fetch->new(uri => $pack->{url})->file);
      print "Extracting $pack->{pack}...\n";
      my $ae = Archive::Extract->new( archive => $archive );
      die "###ERROR###: cannot extract $pack ", $ae->error unless $ae->extract(to => $build_src);
      foreach my $i (@{$pack->{patches}}) {
        chdir catfile($build_src, $pack->{dirname});
        my $cmd = $self->patch_command($srcdir, catfile($patches, $i));
        print "Applying patch '$i'\n";
	print "(cmd: $cmd)\n";
        $self->do_system($cmd) or die '###ERROR### ', $?;
	chdir $self->base_dir();
      }
    }
  }
  return 1;
}

sub set_config_data {
  my( $self, $build_out ) = @_;  
  # xxx TODO xxx
  # 1/ $build_out/bin/sdl-config
  # 1.1/ use sdl-config to get all info
  # 2/ try to find 'sdl-config' and 'SDL.h' => guess $prefix  
  # 2.1/ grep version from SDL.h
  # 2.2/ use defaults fo cflags and libs
  # 2.3/ fill shared libs
  # use '@PrEfIx@' as a placeholder for the real prefix
  $self->config_data('config_version', '1.2.14');
  $self->config_data('config_prefix', '@PrEfIx@');
  $self->config_data('config_libs', '"-L@PrEfIx@" -lSDLmain -lSDL');
  $self->config_data('config_cflags', '"-I@PrEfIx@/include" -D_GNU_SOURCE=1 -Dmain=SDL_main');
  $self->config_data('config_shared_libs', 'xxx TODO xxx');    
}

sub can_build_binaries_from_sources {
  # this needs to be overriden in My::Builder::<platform>
  return 0; # no
}

sub build_binaries {
  # this needs to be overriden in My::Builder::<platform>
  my( $self, $build_out, $build_src ) = @_;
  die "###ERROR### My::Builder cannot build SDL from sources, use rather My::Builder::<platform>";
}

sub clean_dir {
  my( $self, $dir ) = @_;
  if (-d $dir) {
    remove_tree($dir);
    make_path($dir);
  }
}

sub check_build_done_marker {
  my $self = shift;
  return (-e 'build_done');
}

sub touch_build_done_marker {
  my $self = shift;
  require ExtUtils::Command;
  local @ARGV = ('build_done');
  ExtUtils::Command::touch();
  $self->add_to_cleanup('build_done');
}

sub clean_build_done_marker {
  my $self = shift;
  unlink 'build_done' if (-e 'build_done');
}

sub check_sha1sum {
  my( $self, $file, $sha1sum ) = @_;
  my $sha1 = Digest::SHA1->new;
  my $fh;
  open($fh, $file) or die "###ERROR## Cannot check checksum for '$file'\n";
  binmode($fh);
  $sha1->addfile($fh);
  close($fh);
  return ($sha1->hexdigest eq $sha1sum) ? 1 : 0
}

sub patch_command {
  my( $self, $base_dir, $patch_file ) = @_;
  $patch_file = File::Spec->abs2rel( $patch_file, $base_dir );
  return "patch -N -p0 -u -b .bak < $patch_file";
}

1;

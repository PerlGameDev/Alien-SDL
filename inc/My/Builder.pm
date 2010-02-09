package My::Builder;

use strict;
use warnings;
use base 'Module::Build';

use File::Path;
use File::Touch;
use File::Spec::Functions qw(catdir catfile);
use File::Path qw(make_path remove_tree);
use Fatal qw(open close unlink);
use Data::Dumper;
use File::Fetch;
use Archive::Extract;
use Digest::SHA1;
use Config;

sub ACTION_build {
  my $self = shift;
  # sharedir has to exist before calling the original build action
  mkdir 'sharedir' unless(-d 'sharedir');
  # avoid double building when: 'perl Build.pl && Build && Build test'
  unlink 'build_done' if -f 'build_done';
  $self->SUPER::ACTION_build;
}

sub ACTION_code {
  my $self = shift;
  $self->SUPER::ACTION_code;

  # check marker
  return if (-f 'build_done');

  print STDERR "### ACTION_code: starting custom build process\n";
  my $bp = $self->notes('build_params');
  die "###ERROR### Cannot continue build_params not defined" unless defined($bp);
  # save some data into future Alien::SDL::ConfigData
  $self->config_data('build_params', $bp);
  $self->config_data('build_cc', $Config{cc});
  $self->config_data('build_arch', $Config{archname});
  $self->config_data('build_os', $^O);
  if($bp->{buildtype} eq 'use_config_script') {
    $self->config_data('script', $bp->{script});
  }
  elsif($bp->{buildtype} eq 'use_prebuilt_binaries') {     
     $self->fetch_binaries;
     #xxx $self->clean_build_out;
     $self->extract_binaries;     
     #xxx $self->set_config_data;
  }
  elsif($bp->{buildtype} eq 'build_from_sources' ) {  
     $self->fetch_sources;
     $self->extract_sources;
     #xxx $self->clean_build_out;
     $self->build_binaries;
     #xxx $self->set_config_data;
  }
  
  # mark sucessfully finished build
  touch('build_done');
  $self->add_to_cleanup(qw(build_done build_src build_out sharedir));
  print STDERR "### ACTION_code: custom build process finished\n";
}

sub fetch_file {
  my ($self, $url, $sha1sum) = @_;
  die "###ERROR### _fetch_file undefined url\n" unless $url;
  die "###ERROR### _fetch_file undefined sha1sum\n" unless $sha1sum;
  my $ff = File::Fetch->new(uri => $url);
  my $fn = catfile('download', $ff->file);
  if (-e $fn) {      
    print "Checking checksum for already existing '$fn'...\n";
    return 1 if $self->check_sha1sum($fn, $sha1sum);
    unlink $fn; #exists but wrong checksum
  }
  print "Fetching '$url'...\n";
  my $fullpath = $ff->fetch(to => 'download');
  die "###ERROR### Unable to fetch '$url'" unless $fullpath;
  if (-e $fn) {
    print "Checking checksum for '$fn'...\n";
    return 1 if $self->check_sha1sum($fn, $sha1sum);
    die "###ERROR### Checksum failed '$fn'";
  }
  die "###ERROR### _fetch_file failed '$fn'";
}

sub fetch_binaries {
  my $self = shift;
  my $bp = $self->notes('build_params'); 
  $self->fetch_file($bp->{url}, $bp->{sha1sum});
}

sub fetch_sources {
  my $self = shift;
  my $bp = $self->notes('build_params');
  $self->fetch_file($_->{url}, $_->{sha1sum}) foreach (@{$bp->{members}});
}

sub extract_binaries {
  my $self = shift;
  my $bp = $self->notes('build_params');
  my $archive = catfile('download', File::Fetch->new(uri => $bp->{url})->file);
  print "Extracting $archive...\n";
  my $ae = Archive::Extract->new( archive => $archive );    
  die "###ERROR###: Cannot extract $archive ", $ae->error unless $ae->extract(to => 'build_out');
}

sub extract_sources {
  my $self = shift;
  my $bp = $self->notes('build_params');
  foreach my $pack (@{$bp->{members}}) {
    my $srcdir = catfile('build_src', $pack->{dirname});
    my $unpack = 'y';
    $unpack = $self->prompt("Dir '$srcdir' exists, wanna replace with clean sources?", "n") if (-d $srcdir);
    if (lc($unpack) eq 'y') {
      my $archive = catfile('download', File::Fetch->new(uri => $pack->{url})->file);
      print "Extracting $pack->{pack}...\n";
      my $ae = Archive::Extract->new( archive => $archive );    
      die "###ERROR###: cannot extract $pack ", $ae->error unless $ae->extract(to => 'build_src');
      foreach my $i (@{$pack->{patches}}) {
        chdir catfile('build_src', $pack->{dirname});        
        my $cmd = $self->patch_command($srcdir, catfile('patches', $i));
        print "Applying patch '$i'\n";
	print "(cmd: $cmd)\n";
        $self->do_system($cmd) or die '###ERROR### ', $?;
	chdir $self->base_dir();
      }
    }
  }
  return 1;
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

sub can_build_binaries_from_sources {
  # this needs to be overriden in My::Builder::<platform>
  return 0;
}

sub build_binaries {
  # this needs to be overriden in My::Builder::<platform>
  die "###ERROR### Don't know how to build SDL from sources on your system";
}

1;

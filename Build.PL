use strict;
use warnings;

use lib "inc";
use File::Spec::Functions qw(catdir catfile);
use My::Utility qw(check_config_script check_prebuilt_binaries check_src_build);
use My::Builder::Unix;
use My::Builder::Windows;

#### Maybe do something more clever in the future
my $package = 'My::Builder::Unix'; # default
$package = 'My::Builder::Windows' if($^O eq 'MSWin32');

#### Stadard Module::Builder stuff
my $build = $package->new(
  module_name          => 'Alien::SDL',
  all_from             => 'lib/Alien/SDL.pm',
  requires             => {
    'File::Spec'       => '0',
    'File::Temp'       => '0',
    'File::ShareDir'   => '0',
    'ExtUtils::CBuilder' => '0',
  },
  build_requires       => {
    'File::Spec'       => '0',
    'File::Path'       => '0',
    'File::Fetch'      => '0',
    'File::Find'       => '0',
    'Digest::SHA1'     => '0',
    'Archive::Extract' => '0',
    'Archive::Tar'     => '0',
    'Archive::Zip'     => '0',
  },
  configure_requires   => {
    'File::Spec'       => '0',
    'File::Path'       => '0',
    'File::Fetch'      => '0',
    'File::Find'       => '0',
    'Digest::SHA1'     => '0',
    'Archive::Extract' => '0',
  },
  meta_merge => {
    resources  => {
      bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-SDL',
      repository => 'http://github.com/kthakore/Alien_SDL'
    }
  },
  share_dir => 'sharedir',
  # sharedir is used for storing compiled/prebuilt binaries of SDL lib + related libraries
  # avoid using 'share' name as M::B doe not handle well paths like /xx/yy/share/zz/ww/share/xx
);
$build->create_build_script();

#### clean build_done stamp; force rebuild when running 'Build'
$build->clean_build_done_marker;

print "\nWelcome to Alien::SDL module installation";
print "\n-----------------------------------------\n\n";

#### check what options we have for our platform
my $rv; my @candidates = ();

if(defined($ENV{SDL_INST_DIR})) {
  print "Gonna use SDL_INST_DIR environment variable...\n";
  print "(SDL_INST_DIR=$ENV{SDL_INST_DIR})\n";
  if (-d $ENV{SDL_INST_DIR}) {
    my @sdlinst = File::Spec->splitdir($ENV{SDL_INST_DIR});
    if($rv=check_config_script(File::Spec->catdir(@sdlinst, 'bin', 'sdl-config'))) {
      push @candidates, $rv;
    }
    elsif($rv=check_config_script(File::Spec->catdir(@sdlinst, 'sdl-config'))) {
      push @candidates, $rv;
    }
  }
  else {
    warn "###WARN### Non-existing directory '$ENV{SDL_INST_DIR}' - skipping";
  }
}

if($rv=check_config_script("sdl-config")) {
  push @candidates, $rv;
};

if($rv=check_prebuilt_binaries($build->os_type)) {
  push @candidates, @{$rv};
};

if(($rv=check_src_build($build->os_type)) && $build->can_build_binaries_from_sources()) {
  push @candidates, @{$rv};
};

push @candidates, { title => 'Quit installation' };

#### ask user what way to go
my $i = 1;
my $prompt_string = "\nYou have the following options:\n";
foreach my $c (@candidates) {
  $prompt_string .= "[" . $i++ . "] Use: " . $c->{title} . "\n"
}
$prompt_string .= "\nWhat way do you wanna go?";
my $ans = $build->prompt($prompt_string, 1);

#### store build params into 'notes'
if(($ans>0) && ($ans<scalar(@candidates))) {
  $build->notes('build_params', $candidates[$ans-1]);
}
else {
  $build->notes('build_params', undef); # just to be sure
}

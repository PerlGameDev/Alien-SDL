use strict;
use warnings;

use Data::Dumper;
use File::Spec::Functions qw(catdir catfile);

use lib "inc";
use My::Utility qw(check_config_script check_prebuilt_binaries check_src_build);

use My::Builder::Unix;
use My::Builder::Windows;

#### Maybe do something more clever in the future
my $package = 'My::Builder::Unix'; # default
$package = 'My::Builder::Windows' if($^O eq 'MSWin32');

#### Stadard Module::Builder stuff
my $build = $package->new(
  module_name          => 'Alien::SDL',
  license              => 'perl',
  dist_author          => 'kthakore <kthakore@cpan.org>',
  dist_version_from    => 'lib/Alien/SDL.pm',
  build_requires       => {
    'File::Spec'       => '0',
    # M::B 0.36
  },
  configure_requires   => {
    'File::Fetch'      => '0.20',
    'Archive::Extract' => '0.34',
    'WWW::Mechanize'   => '0'
  },
  share_dir => 'sharedir', # used for storing compiled/prebuilt binaries of SDL lib + related libraries
);
$build->create_build_script();    

print <<'END';

---------------------------------------------------------------------
The Alien::SDL module installation will try to:
 * locate an already installed SDL related libs (via 'sdl-config')
 * check for SDL libs in directory specified by SDL_INST_DIR variable
 * download prebuilt SDL binaries (if available for your platform)
 * build SDL binaries from source codes (if possible on your system)
---------------------------------------------------------------------

END

#### check what options we have for our platform
my $rv;
my @candidates = ();

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
    warn "###WARN### Non-existing directory '$ENV{SDL_INST_DIR}' - skipping\n";
  }  
}

if($rv=check_config_script("sdl-config")) {
  push @candidates, $rv;
};

if($rv=check_prebuilt_binaries($build->os_type)) {
  push @candidates, @{$rv};  
};

if($build->can_build_binaries_from_sources() && ($rv=check_src_build($build->os_type))) {
  push @candidates, @{$rv};
};

#### ask user what way to go
my $i = 1;
my $prompt_string = "\nYou have the following options:\n";
foreach my $c (@candidates) {
  $prompt_string .= "[" . $i++ . "] Use: " . $c->{title} . "\n"
}
$prompt_string .= "\nWhat way do you wanna go?";
my $ans = $build->prompt($prompt_string, 1);
die "###ERROR### Invalid option" unless(($ans>0) && ($ans<=scalar(@candidates)));

#### store build params into notes
$build->notes('build_params', $candidates[$ans-1]);

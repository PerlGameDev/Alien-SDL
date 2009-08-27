use Module::Build;
# See perldoc Module::Build for details of how this works
#
use strict;
use warnings;
use inc::Utility;
use Data::Dumper;
use Carp;
#inc::Utility->get_SDL();
#inc::Utility->get_SDL_image();
#inc::Utility->get_SDL_mixer();
#TODO: Make this programmatically find strawberry
my $strawberry = 'C:\\strawberry\\' if( $^O =~ /Win*/);
inc::Utility->get_SDL_deps( $strawberry ) if( $^O =~ /Win*/);


my $build_ref = Module::Build->new
    ( module_name     => 'Alien::SDL',
      license         => 'perl',
      requires	      => {
	      		'File::chdir' => '0.1002'
	      		}
    );
    
    
$build_ref->create_build_script;

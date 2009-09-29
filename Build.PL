use Module::Build;
# See perldoc Module::Build for details of how this works
#
use strict;
use warnings;
use inc::Utility;
use Data::Dumper;
use Carp;
my $strawberry = "$Config::Config{prefix}/../" if( $^O =~ /Win*/);
inc::Utility->get_SDL_deps( $strawberry ) if( $^O =~ /Win*/);
inc::Utility->get_SDL() if( $^O !~ /Win*/ and !inc::Utility->sdl_con_found()) ;



my $build_ref = Module::Build->new
    ( module_name     => 'Alien::SDL',
      license         => 'perl',
      configure_requires	      => {
	      		'File::Fetch' => '0.20',
			'Archive::Extract' => '0.34'
	      	   		}
    );
    
    
$build_ref->create_build_script;

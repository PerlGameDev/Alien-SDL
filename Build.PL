use Module::Build;
# See perldoc Module::Build for details of how this works
#
use inc::Utility;


inc::Utility->get_SDL();
inc::Utility->get_SDL_image();
inc::Utility->get_SDL_mixer();


Module::Build->new
    ( module_name     => 'Alien::SDL',
      license         => 'perl',
      requires	      => {
	      		'File::chdir' => '0.1002'
	      		}
    )->create_build_script;

use Module::Build;
# See perldoc Module::Build for details of how this works
#
use inc::Utility;

print inc::Utility->sdl_installed;

inc::Utility->get_SDL();

Module::Build->new
    ( module_name     => 'Alien::SDL',
      license         => 'perl',
      requires	      => {
	      		'File::chdir' => '0.1002'
	      		}
    )->create_build_script;

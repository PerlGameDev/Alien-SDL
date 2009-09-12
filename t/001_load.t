# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;
use inc::Utility;
BEGIN { use_ok( 'Alien::SDL' ); }

is( 1, inc::Utility->sdl_con_found(), "Trying to find sdl-config" );




# t/003_check_headers.t - test check_header() functionality

use Test::More tests => 4;
use Alien::SDL;

diag("Testing basic headers SDL.h + SDL_version.h + SDL_net.h");
is( Alien::SDL->check_header('SDL.h'), 1, "Testing availability of 'SDL.h'" );
is( Alien::SDL->check_header( 'SDL.h', 'SDL_version.h' ),
    1, "Testing availability of 'SDL.h, SDL_version.h'" );
is( Alien::SDL->check_header('SDL_net.h'),
    1, "Testing availability of 'SDL_net.h'" );

diag 'Core version: '.Alien::SDL->get_header_version('SDL_version.h');
diag 'Mixer version: '.Alien::SDL->get_header_version('SDL_mixer.h');
diag 'GFX version: '.Alien::SDL->get_header_version('SDL_gfxPrimitives.h');
diag 'Image version: '.Alien::SDL->get_header_version('SDL_image.h');
diag 'Net version: '.Alien::SDL->get_header_version('SDL_net.h');
diag 'TTF version: '.Alien::SDL->get_header_version('SDL_ttf.h');
diag 'Smpeg version: '.Alien::SDL->get_header_version('smpeg.h');

pass 'got header versions';
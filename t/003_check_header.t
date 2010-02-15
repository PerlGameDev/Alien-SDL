# t/003_check_headers.t - test check_header() functionality

use Test::More tests => 3;
use Alien::SDL;

diag("Testing basic headers SDL.h + SDL_version.h + SDL_net.h");
is( Alien::SDL->check_header('SDL.h'), 1, "Testing availability of 'SDL.h'" );
is( Alien::SDL->check_header('SDL.h', 'SDL_version.h'), 1, "Testing availability of 'SDL.h, SDL_version.h'" );
is( Alien::SDL->check_header('SDL_net.h'), 1, "Testing availability of 'SDL_net.h'" );

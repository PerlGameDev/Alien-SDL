# t/004_config.t

use Test::More tests => 3;
use Alien::SDL;

like( Alien::SDL->get_header_version('SDL_version.h'), qr/([0-9]+\.)*[0-9]+/, "Testing SDL_version.h" );
like( Alien::SDL->get_header_version('SDL_net.h'), qr/([0-9]+\.)*[0-9]+/, "Testing SDL_net.h" );
like( Alien::SDL->get_header_version('SDL_image.h'), qr/([0-9]+\.)*[0-9]+/, "Testing SDL_image.h" );


# t/001_load.t - test module loading and basic functionality

use Test::More tests => 1;

BEGIN { use_ok( 'Alien::SDL' ); }

diag( "Testing Alien::SDL $Alien::SDL::VERSION, Perl $], $^X" );

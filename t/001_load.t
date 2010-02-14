# t/001_load.t - check module loading and basic functionality

use Test::More tests => 3;
use Data::Dumper;

BEGIN { use_ok( 'Alien::SDL' ); }
like( Alien::SDL->config('version'), qr/([0-9]+\.)*[0-9]+/, "Testing config('version')" );
like( Alien::SDL->config('prefix'), qr/.+/, "Testing config('prefix')" );

# xxx TODO xxx - more tests
# check the existance of prefix directory
# check the existance of prefix/include directory
# check the existance of prefix/include/SDL/SDL.h file
# check the existance of ld_share_libs files
# check the existance of ld_paths dirs
# compile and run sample code
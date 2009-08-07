# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Alien::SDL' ); }

my $object = Alien::SDL->new ();
isa_ok ($object, 'Alien::SDL');



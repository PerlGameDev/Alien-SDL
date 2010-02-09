package My::Builder::Windows;

use strict;
use warnings;
use base 'My::Builder';

sub can_build_binaries_from_sources {
  return 0; # no
}

sub build_binaries {
  die "###ERROR### Building from sources not supported on MS Windows platform";
}

1;

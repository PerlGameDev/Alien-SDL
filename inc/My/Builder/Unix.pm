package My::Builder::Unix;

use strict;
use warnings;
use base 'My::Builder';

use Data::Dumper;

sub can_build_binaries_from_sources {
  return 1; # yes
}

sub build_binaries {
  my $self = shift;
  my $bp = $self->notes('build_params');  
  print STDERR "### Build procedure to be done!\n";
  print STDERR "### params=" . Dumper($bp);
  return 1;
}

1;

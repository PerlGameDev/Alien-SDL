package inc::Utility;
use strict;
use warnings;
use Carp;
use File::chdir;
use File::Fetch;
use Archive::Extract;

#checks to see if sdl-config is availabe
#
sub sdl_con_found
{
	$_ = 1;
	`sdl-config --libs` or $_ = 0;
	return $_;
}

sub sdl_installed($)
{
	my $location = shift;

	if( defined $location )
	{
		carp 'location: '.$location;
		return 0;
	}
	else
	{
		return sdl_con_found;
	}

}

sub get_SDL()
{
	
	my $FF = File::Fetch->new( uri =>'http://www.libsdl.org/release/SDL-devel-1.2.9-mingw32.tar.gz' );
	my $where = $FF->fetch( to => './deps' );
	print "Got archive $where\n";
	my $sdl_ar = Archive::Extract->new(archive => $where);
	$sdl_ar->extract( to => 'deps/' );
	
	$CWD = 'deps/SDL-1.2.9';
	{
	`make`;
	`make install`;
	}
	


}

1;

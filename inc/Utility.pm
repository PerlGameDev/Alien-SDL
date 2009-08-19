package inc::Utility;
use strict;
use warnings;
use Carp;
use File::chdir;
use File::Fetch;
use Archive::Extract;

#checks to see if sdl-config is available
sub sdl_con_found
{
	$_ = 1;
	`sdl-config --libs` or $_ = 0;
	return $_;
}


sub get_url()
{
	my $sdl_site = 'http://www.libsdl.org';
	
	my $sdl_projects_site =  $sdl_site.'/projects';
	  
	$urls = (
	SDL => $sdl_site.'/release/',
	image => $sdl_projects_site.'/SDL_image/release/',
	mixer => $sdl_projects_site.'/SDL_mixer/release/',
	ttf => $sdl_projects_site.'/SDL_ttf/release/',
	net => $sdl_projects_site.'/SDL_net/release/',
	);
	return $urls;
}

sub get_SDL($$)
{
	my $version = shift;
	my $suffix = shift;
	
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

sub get_SDL_image()
{

}

sub get_SDL_mixer()
{

}

sub get_SDL_ttf()
{

}

sub get_SDL_sound()
{

}



1;

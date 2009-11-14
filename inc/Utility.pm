package inc::Utility;
use strict;
use warnings;
use Cwd;
use Carp;
use File::Spec;
use lib '.';
use File::Fetch;
use Archive::Extract;
use Data::Dumper;
#checks to see if sdl-config is available

sub sdl_con_found
{
       my $devnull = File::Spec->devnull();	
       `sdl-config --libs 2>$devnull`;
       return 1 unless ($? >> 8) and return 0;

}



sub get_url()
{
	my $sdl_site = 'http://www.libsdl.org';
	
	my $sdl_projects_site =  $sdl_site.'/projects';
	  
	my $urls = [
	 $sdl_site.'/release/SDL-1.2.13.tar.gz',
	 $sdl_projects_site.'/SDL_image/release/',
	 $sdl_projects_site.'/SDL_mixer/release/',
	 $sdl_projects_site.'/SDL_ttf/release/',
	 $sdl_projects_site.'/SDL_net/release/',
	];
	
	return $urls;
}


#
sub cleanup_deps_folder {
        my $dir = shift;
	local *DIR;
	mkdir $dir;
	opendir DIR, $dir or die "opendir $dir: $!";
	for (readdir DIR) {
	        next if /^\.{1,2}$/;
	        my $path = "$dir/$_";
		unlink $path if (-f $path );
		rmdir $path if (-d $path);
		cleanup_deps_folder($path) if -d $path;
	}
	closedir DIR;
	rmdir $dir;
}

sub get_SDL()
{
	cleanup_deps_folder('deps');
	my $urls = get_url();
	my $sdl = $$urls[0];
	my $FF = File::Fetch->new( uri => $sdl);
	my $where = $FF->fetch( to => 'deps' );
	carp "Got archive $where\n";
	my $sdl_ar = Archive::Extract->new(archive => $where);
	$sdl_ar->extract( to => 'deps' );
	carp "Extracted Archive to $sdl_ar->extract_path \n";
	my $pwd = Cwd::cwd();
      	chdir  $sdl_ar->extract_path;
	
	carp "Configuring SDL \n";
	`./configure`;
	carp "Making SDL \n";
	`make`;
	carp "Installing SDL \n";
	`make install`;
	
			
	 chdir $pwd;
 }

sub get_SDL_deps()
{
	my $self = shift;
	my $location = shift;
	return if(sdl_con_found());
	croak "Require a location to extract to $location" if ( !(-d $location) );
	my $url = 'http://sdl.perl.org/assets/lib-SDL-bin_win32.zip';
	my $FF = File::Fetch->new( uri => $url);
	my $where = $FF->fetch( to => $location );
	print "Got archive $where\n";
	my $sdl_ar = Archive::Extract->new(archive => $where);
	$sdl_ar->extract( to => $location );	
	unlink $where;
}



1;

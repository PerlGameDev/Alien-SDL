package inc::Utility;
use strict;
use warnings;
use Carp;
use File::Spec;
use File::Fetch;
use Archive::Extract;

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
	 $sdl_site.'/release/SDL-1.2.9.tar.gz',
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

	opendir DIR, $dir or die "opendir $dir: $!";
	for (readdir DIR) {
	        next if /^\.{1,2}$/;
	        my $path = "$dir/$_";
		unlink $path if -f $path;
		cleanup_deps_folder($path) if -d $path;
	}
	closedir DIR;
	rmdir $dir or print "error - $!";
}

#sub get_SDL()
#{
	#my $version = shift;
	#my $suffix = shift;
#	cleanup_deps_folder('deps');
#	my $FF = File::Fetch->new( uri =>'http://cloud.github.com/downloads/kthakore/SDL_perl/sdlperl-deps.tar.bz2' );
#	my $where = $FF->fetch( to => 'deps' );
#	print "Got archive $where\n";
#	my $sdl_ar = Archive::Extract->new(archive => $where);
#	$sdl_ar->extract( to => 'deps' );
#	
#	$CWD = 'deps/sdlperl-deps.tar.bz2';
#	{
#	`make`;
#	`make install`;
#	}
	#
#}

sub get_SDL_deps()
{
	my $self = shift;
	my $location = shift;
	return if(sdl_con_found());
	croak "Require a location to extract to $location" if ( !(-d $location) );
	my $url = 'http://svn.ali.as/cpan/users/kmx/strawberry_packs/lib-SDL-bin_20090831+depend-DLLs.zip';
	my $FF = File::Fetch->new( uri => $url);
	my $where = $FF->fetch( to => $location );
	print "Got archive $where\n";
	my $sdl_ar = Archive::Extract->new(archive => $where);
	$sdl_ar->extract( to => $location );	
	unlink $where;
}



1;

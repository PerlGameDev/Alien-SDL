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
use WWW::Mechanize;
#checks to see if sdl-config is available

sub sdl_con_found
{
       my $devnull = File::Spec->devnull();	
       `sdl-config --libs 2>$devnull`;
       return 1 unless ($? >> 8) and return 0;

}



sub get_url
{
	my $sdl_site = 'http://www.libsdl.org';

	my $sdl_projects_site =  $sdl_site.'/projects';

	my %urls = (

	sdl => $sdl_site.'/release/',
	image => $sdl_projects_site.'/SDL_image/release/',
	mixer => $sdl_projects_site.'/SDL_mixer/release/',
	ttf => $sdl_projects_site.'/SDL_ttf/release/',
	net => $sdl_projects_site.'/SDL_net/release/',
	gfx => 'http://www.ferzkopp.net/joomla/content/view/19/14/'
	);
	return %urls;
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
 	my %urls = get_url();

	cleanup_deps_folder('deps');
	get_largest_link( $urls{sdl} ); 
	get_largest_link( $urls{image} ); 
	get_largest_link( $urls{mixer} ); 
	get_largest_link( $urls{ttf} ); 
	get_largest_link( $urls{net} ); 
	get_largest_link( $urls{gfx} ); 

};

sub get_largest_link
{
	my $uri = shift;
	my $mech = WWW::Mechanize->new();
	$mech->get($uri);
	my @links = map $_->url, $mech->links;

	my @l_link = ( $links[0],-1, -1, -1);

#printf("%-20s %-8s %-10s %s\n", 'module', 'version', 'arch', 'filetype');
	for my $link (@links)
	{
#	   print $link."\n";
		if($link =~ /([a-zA-Z_\-]+)-([\d\.\-]+)\.(tar\.gz)$/i)
		{
#		printf("%-20s %-8s %-10s %s\n", $1, $2, '', $3);

			my @version = split(/\./, $2); 
			if( $l_link[1] < $version[0] )
			{
#			warn (join '.', @l_link) .' >  '.(join '.',@version) ;

				@l_link = ($link, @version); 

			}
			elsif( $l_link[1] == $version[0] and 
				$l_link[2] < $version[1])
			{
#			warn (join '.', @l_link) .' >  '.(join '.',@version) ;

				@l_link = ($link, @version);
			}
			elsif ( $l_link[1] == $version[0] and                                                
				$l_link[2] == $version[1] and
				$l_link[3] < $version[2] )
			{
#			warn (join '.', @l_link) .' >  '.(join '.',@version) ;

				@l_link = ($link, @version);
			}

		}
	}
	
	warn 'No link found!' and return if $l_link[1] == -1 ; 
	$uri = 'http://www.ferzkopp.net' if $l_link[0] =~ /joomla/;
	$uri .= $l_link[0];
	print 'Getting package: '.$uri."\n";

	compile($uri);
	return $uri;

}

sub compile
{

	my $sdl = shift;
	my $FF = File::Fetch->new( uri => $sdl);
	my $where = $FF->fetch( to => 'deps' );
	carp "Got archive $where\n";
	my $sdl_ar = Archive::Extract->new(archive => $where);
	$sdl_ar->extract( to => 'deps' );
	carp "Extracted Archive to ".$sdl_ar->extract_path." \n";
	my $pwd = Cwd::cwd();
      	chdir  $sdl_ar->extract_path;
	
	carp "Configuring $sdl \n";
	`./configure`;
	carp "Making $sdl \n";
	`make`;
	carp "Installing $sdl \n";
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

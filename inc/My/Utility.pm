package My::Utility;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(ut_arch_file ut_install_arch_file
                    ut_arch_dir ut_install_arch_dir
		    check_config_script check_prebuilt_binaries check_src_build);
use Cwd;
use Carp;
use File::Spec;
use lib '.';
use File::Fetch;
use Archive::Extract;
use Data::Dumper;
use WWW::Mechanize;
use Config;
#checks to see if sdl-config is available

#### packs with prebuilt binaries
# - all regexps has to match: arch_re ~ $Config{archname}, cc_re ~ $Config{cc}, os_re ~ $^O
# - the order matters, we offer binaries to user in the same order (1st = preffered)
my $prebuilt_binaries = [
    {
      title    => 'Binaries MSWin/32bit SDL-1.2.4 + SDL_gfx, SDL_sound, ...',
      url      => 'http://strawberryperl.com/package/kmx/sdl/lib-SDL-bin_20090831+depend-DLLs.zip',
      sha1sum  => '9a56dc79fe0980567fc2309b8fb80a5daed04871',
      arch_re  => qr/^MSWin32-x86-multi-thread$/,
      os_re    => qr/^MSWin32$/,
      cc_re    => qr/gcc/,
    },
    {
      title    => 'Broken binaries',
      url      => 'http://strawberryperl.com/package/kmx/sdl/lib-SDL-bin_20090831+depend-DLLsxxx.zip',
      sha1sum  => '9a56dc79fe0980567fc2309b8fb80a5daed04871',
      arch_re  => qr/^MSWin32-x86-multi-thread$/,
      os_re    => qr/^MSWin32$/,
      cc_re    => qr/gcc/,
    },
 ];

#### tarballs with source codes
my $source_packs = [
  {
    title   => 'Source code build SDL-1.2.14 + SDL_(image|mixer|ttf|net|gfx)',
    members     => [
      {
        pack => 'SDL',
        dirname => 'SDL-1.2.14',
        url => 'http://www.libsdl.org/release/SDL-1.2.14.tar.gz',
	sha1sum  => 'ba625b4b404589b97e92d7acd165992debe576dd',
	patches => [
	  'test1.patch',
	  'test2.patch',
	],
      },
      {
        pack => 'SDL_image',
        dirname => 'SDL_image-1.2.10',
        url => 'http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.10.tar.gz',
	sha1sum  => '6bae71fdfd795c3dbf39f6c7c0cf8b212914ef97',
	patches => [ ],
      },
      {
        pack => 'SDL_mixer',
        dirname => 'SDL_mixer-1.2.11',
        url => 'http://www.libsdl.org/projects/SDL_mixer/release/SDL_mixer-1.2.11.tar.gz',
	sha1sum  => 'ef5d45160babeb51eafa7e4019cec38324ee1a5d',
	patches => [ ],
      },
      {
        pack => 'SDL_ttf',
        dirname => 'SDL_ttf-2.0.9',
        url => 'http://www.libsdl.org/projects/SDL_ttf/release/SDL_ttf-2.0.9.tar.gz',
	sha1sum  => '6bc3618b08ddbbf565fe8f63f624782c15e1cef2',
	patches => [ ],
      },
      {
        pack => 'SDL_net',
        dirname => 'SDL_net-1.2.7',
        url => 'http://www.libsdl.org/projects/SDL_net/release/SDL_net-1.2.7.tar.gz',
	sha1sum  => 'b46c7e3221621cc34fec1238f1b5f0ce8972274d',
	patches => [ ],
      },
      {
        pack => 'SDL_gfx',
        dirname => 'SDL_gfx-2.0.20',
        url => 'http://www.ferzkopp.net/Software/SDL_gfx-2.0/SDL_gfx-2.0.20.tar.gz',
	sha1sum  => '077f7e64376c50a424ef11a27de2aea83bda3f78',
	patches => [ ],
      },
    ],
  },
];


sub check_config_script
{
  my $script = shift || 'sdl-config';
  print "Gonna check config script...\n";
  print "(scriptname=$script)\n";
  my $devnull = File::Spec->devnull();	
  my $version = `$script --version 2>$devnull`;
  return if($? >> 8);
  my $prefix = `$script --prefix 2>$devnull`;
  return if($? >> 8);
  $version =~ s/[\r\n]*$//;
  $prefix =~ s/[\r\n]*$//;
  #returning HASHREF
  return {
    title     => "Already installed SDL ver=$version path=$prefix",
    buildtype => 'use_config_script',
    script    => $script,
  };
}

sub check_prebuilt_binaries
{
  print "Gonna check availability of prebuilt binaries ...\n";
  print "(os=$^O archname=$Config{archname} cc=$Config{cc})\n";
  my @good = ();
  foreach my $b (@{$prebuilt_binaries}) {
    if ( ($^O =~ $b->{os_re}) && 
         ($Config{archname} =~ $b->{arch_re}) && 
	 ($Config{cc} =~ $b->{cc_re}) ) {
      $b->{buildtype} = 'use_prebuilt_binaries';
      push @good, $b;
    }
  }
  #returning ARRAY of HASHREFs (sometimes more than one value)
  return \@good;
}

sub check_src_build
{
  print "Gonna check possibility for building from sources ...\n";
  print "(os=$^O archname=$Config{archname} cc=$Config{cc})\n";
  foreach my $p (@{$source_packs}) {
    $p->{buildtype} = 'build_from_sources';
  }
  return $source_packs;
}

sub get_url
{
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


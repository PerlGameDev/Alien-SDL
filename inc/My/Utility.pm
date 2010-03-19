package My::Utility;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(check_config_script check_prebuilt_binaries check_src_build find_SDL_dir find_file sed_inplace);
use Config;
use File::Spec::Functions qw(splitdir catdir splitpath catpath rel2abs);
use File::Find qw(find);
use File::Copy qw(cp);
use Cwd qw(realpath);

#### packs with prebuilt binaries
# - all regexps has to match: arch_re ~ $Config{archname}, cc_re ~ $Config{cc}, os_re ~ $^O
# - the order matters, we offer binaries to user in the same order (1st = preffered)
my $prebuilt_binaries = [
    {
      title    => "Binaries Win/32bit SDL-1.2.14 (20090831) RECOMMENDED\n" .
                  "\t(gfx, image, mixer, net, smpeg, ttf)",
      url      => 'http://strawberryperl.com/package/kmx/sdl/lib-SDL-bin_win32_v2.zip',
      sha1sum  => 'eaeeb96b0115462f6736de568de8ec233a2397a5',
      arch_re  => qr/^MSWin32-x86-multi-thread$/,
      os_re    => qr/^MSWin32$/,
      cc_re    => qr/gcc/,
    },
    {
      title    => "Binaries Win/32bit SDL-1.2.14 (extended, 20100319)\n" .
                  "\t(gfx, image, mixer, net, smpeg, ttf, sound, svg, rtf, Pango)",
      url      => 'http://strawberryperl.com/package/kmx/sdl/Win32_SDL-1.2.14-extended-bin_20100319.zip',
      sha1sum  => 'fc968684900f09fb7656735edc6472fe961ec536',
      arch_re  => qr/^MSWin32-x86-multi-thread$/,
      os_re    => qr/^MSWin32$/,
      cc_re    => qr/gcc/,
    },
    {
      title    => "Binaries Win/64bit SDL-1.2.14 (experimental, 20100301)\n" .
                  "\t(gfx, image, mixer, net, smpeg, ttf, sound, svg, rtf, Pango)",
      url      => 'http://strawberryperl.com/package/kmx/sdl/Win64_SDL-1.2.14-extended-bin_20100301.zip',
      sha1sum  => '4576dfeb812450fce5bb22b915985ec696ea699f',
      arch_re  => qr/^MSWin32-x64-multi-thread$/,
      os_re    => qr/^MSWin32$/,
      cc_re    => qr/gcc/,
    },
 ];

#### tarballs with source codes
my $source_packs = [
## the first set for source code build will be a default option
  {
    title   => "Source code build: SDL-1.2.14 & co. (RECOMMENDED)\n" .
               "\tbuilds: SDL, SDL_(image|mixer|ttf|net|gfx)\n" .
	       "\tneeds preinstalled: libpng-devel, jpeg-devel, freetype2-devel",
    members     => [
      {
        pack => 'SDL',
        dirname => 'SDL-1.2.14',
        url => 'http://www.libsdl.org/release/SDL-1.2.14.tar.gz',
        sha1sum  => 'ba625b4b404589b97e92d7acd165992debe576dd',
        patches => [
          'test1.patch',
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
## another src build set
  {
    title   => "Source code build: SDL-1.2.14 & co. + all prereq. libraries\n" .
               "\tbuilds: zlib, jpeg, png, freetype, SDL, SDL_(image|mixer|ttf|net|gfx)",
    members     => [
      {
        pack => 'zlib',
        dirname => 'zlib-1.2.4',
        url => 'http://www.zlib.net/zlib-1.2.4.tar.gz',
        sha1sum  => '22965d40e5ca402847f778d4d10ce4cba17459d1',
      },
      {
        pack => 'jpeg',
        dirname => 'jpeg-8a',
        url => 'http://www.ijg.org/files/jpegsrc.v8a.tar.gz',
        sha1sum  => '78077fb22f0b526a506c21199fbca941d5c671a9',
        patches => [ 'jpeg-8a_cygwin.patch' ],
      },
      {
        pack => 'libpng',
        dirname => 'libpng-1.4.1',
        url => 'http://downloads.sourceforge.net/libpng/libpng-1.4.1.tar.gz',
        sha1sum  => '7a3488f5844068d67074f2507dd8a7ed9c69ff04',
      },
      {
        pack => 'freetype',
        dirname => 'freetype-2.3.12',
        url => 'http://mirror.lihnidos.org/GNU/savannah/freetype/freetype-2.3.12.tar.gz',
        sha1sum  => '0082ec5e99fec5a1c6d89b321a7e2f201542e4b3',
      },
      {
        pack => 'SDL',
        dirname => 'SDL-1.2.14',
        url => 'http://www.libsdl.org/release/SDL-1.2.14.tar.gz',
        sha1sum  => 'ba625b4b404589b97e92d7acd165992debe576dd',
        patches => [
          'test1.patch',
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
    prefix    => $prefix,
  };
}

sub check_prebuilt_binaries
{
  print "Gonna check availability of prebuilt binaries ...\n";
  print "(os=$^O cc=$Config{cc} archname=$Config{archname})\n";
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
  print "(os=$^O cc=$Config{cc})\n";
  foreach my $p (@{$source_packs}) {
    $p->{buildtype} = 'build_from_sources';
  }
  return $source_packs;
}

sub find_file {
  my ($dir, $re) = @_;
  my @files;
  $re ||= qr/.*/;
  find({ wanted => sub { push @files, rel2abs($_) if /$re/ }, follow => 1, no_chdir => 1 }, $dir);
  return @files;
}

sub find_SDL_dir {
  my $root = shift;
  my ($version, $prefix, $incdir, $libdir);
  return unless $root;

  # try to find SDL_version.h
  my ($found) = find_file($root, qr/SDL_version\.h$/i ); # take just the first one
  return unless $found;

  # get version info
  open(DAT, $found) || return;
  my @raw=<DAT>;
  close(DAT);
  my ($v_maj) = grep(/^#define[ \t]+SDL_MAJOR_VERSION[ \t]+[0-9]+/, @raw);
  $v_maj =~ s/^#define[ \t]+SDL_MAJOR_VERSION[ \t]+([0-9]+)[.\r\n]*$/$1/;
  my ($v_min) = grep(/^#define[ \t]+SDL_MINOR_VERSION[ \t]+[0-9]+/, @raw);
  $v_min =~ s/^#define[ \t]+SDL_MINOR_VERSION[ \t]+([0-9]+)[.\r\n]*$/$1/;
  my ($v_pat) = grep(/^#define[ \t]+SDL_PATCHLEVEL[ \t]+[0-9]+/, @raw);
  $v_pat =~ s/^#define[ \t]+SDL_PATCHLEVEL[ \t]+([0-9]+)[.\r\n]*$/$1/;
  return if (($v_maj eq '')||($v_min eq '')||($v_pat eq ''));
  $version = "$v_maj.$v_min.$v_pat";

  # get prefix dir
  my ($v, $d, $f) = splitpath($found);
  my @pp = reverse splitdir($d);
  shift(@pp) if(defined($pp[0]) && $pp[0] eq '');
  shift(@pp) if(defined($pp[0]) && $pp[0] eq 'SDL');
  if(defined($pp[0]) && $pp[0] eq 'include') {
    shift(@pp);
    @pp = reverse @pp;
    return (
      $version,
      catpath($v, catdir(@pp), ''),
      catpath($v, catdir(@pp, 'include'), ''),
      catpath($v, catdir(@pp, 'lib'), ''),
    );
  }
}

sub sed_inplace {
  # we expect to be called like this:
  # sed_inplace("filename.txt", 's/0x([0-9]*)/n=$1/g');
  my ($file, $re) = @_;
  if (-e $file) {
    cp($file, "$file.bak") or die "###ERROR### cp: $!";
    open INPF, "<", "$file.bak" or die "###ERROR### open<: $!";
    open OUTF, ">", $file or die "###ERROR### open>: $!";
    binmode OUTF; # we do not want Windows newlines
    while (<INPF>) {
     eval( "$re" );
     print OUTF $_;
    }
    close INPF;
    close OUTF;
  }
}

1;

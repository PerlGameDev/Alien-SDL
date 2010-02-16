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
      title    => 'Binaries Win/32bit SDL-1.2.13 + gfx,image,mixer,net,smpeg,ttf',
      url      => 'http://strawberryperl.com/package/kmx/sdl/SDL-bin-20090831+depend-DLLs.zip',
      sha1sum  => '9a56dc79fe0980567fc2309b8fb80a5daed04871',
      arch_re  => qr/^MSWin32-x86-multi-thread$/,
      os_re    => qr/^MSWin32$/,
      cc_re    => qr/gcc/,
    },
    {
      title    => 'Binaries Win/32bit SDL-1.2.14 + gfx,image,mixer,net,smpeg,ttf,sound,rtf (experimental)',
      url      => 'http://strawberryperl.com/package/kmx/sdl/SDL-bin-20100214-w32.zip',
      sha1sum  => '5c2ea3c31f7a84be84bba650583981eec9ce103d',
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
  return unless ($v_maj && $v_min && $v_pat);
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

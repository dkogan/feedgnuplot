use strict;
use warnings;
use ExtUtils::MakeMaker;

sub parseversion
{
# grab the version number from the debian changelog file. I look for lines line
#
# libpackage-perl (0.02) unstable; urgency=low
#
# I parse out the 0.02 part
  open DCH, 'debian/changelog' or die "Couldn't open debian/changelog";
  my ($version) = <DCH> =~ /^\S+ \s* \( ([0-9\.]+) \)/x
    or die "Couldn't parse version from debian/changelog";
  close DCH;

  return $version;
}

sub MY::libscan
{
    package MY;

    my ($self, $file) = @_;

    # Don't install the README.pod or any non-feedgnuplot .pl file
    return undef if $file !~ /feedgnuplot.pl/ && $file =~ /\.pl$|^README.pod/;

    return $self->SUPER::libscan ($file);
}

WriteMakefile
  (
   NAME                       => 'feedgnuplot',
   AUTHOR                     => q{Dima Kogan <dima@secretsauce.net>},
   VERSION                    => parseversion(),
   ABSTRACT_FROM              => 'bin/feedgnuplot',
   ($ExtUtils::MakeMaker::VERSION >= 6.3002
    ? ('LICENSE'              => 'perl')
    : ()),
   PL_FILES                   => {},
   EXE_FILES                  => [ 'bin/feedgnuplot' ],
   PREREQ_PM                  => { 'Test::Script::Run' => 0},
   dist                       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   clean                      => { FILES => 'feedgnuplot-*' },
  );

use strict;
use warnings;
use ExtUtils::MakeMaker;


sub MY::libscan
{
    package MY;

    my ($self, $file) = @_;

    # Don't install the README.pod or any non-feedGnuplot .pl file
    return undef if $file !~ /feedGnuplot.pl/ && $file =~ /\.pl$|^README.pod/;

    return $self->SUPER::libscan ($file);
}

WriteMakefile
  (
   NAME                       => 'feedGnuplot',
   AUTHOR                     => q{Dima Kogan <dkogan@cds.caltech.edu>},
   VERSION_FROM               => 'bin/feedGnuplot',
   ABSTRACT_FROM              => 'bin/feedGnuplot',
   ($ExtUtils::MakeMaker::VERSION >= 6.3002
    ? ('LICENSE'              => 'perl')
    : ()),
   PL_FILES                   => {},
   EXE_FILES                  => [ 'bin/feedGnuplot' ],
   PREREQ_PM                  => { 'Test::Script::Run' => 0},
   dist                       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   clean                      => { FILES => 'feedGnuplot-*' },
  );

# reroute the main POD into a separate README.pod if requested. This is here
# purely to generate a README.pod for the github front page
if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
  open SCRIPT, 'bin/feedGnuplot' or die "Couldn't open main script";
  open README, '>README.pod'     or die "Couldn't open README.pod";
  while (<SCRIPT>)
  {
    if (/^=/../^=cut/)
    { print README; }
  }
}

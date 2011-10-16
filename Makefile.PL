use strict;
use warnings;
use ExtUtils::MakeMaker;


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
   AUTHOR                     => q{Dima Kogan <dkogan@cds.caltech.edu>},
   VERSION_FROM               => 'bin/feedgnuplot',
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

# reroute the main POD into a separate README.pod if requested. This is here
# purely to generate a README.pod for the github front page
if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
  open SCRIPT, 'bin/feedgnuplot' or die "Couldn't open main script";
  open README, '>README.pod'     or die "Couldn't open README.pod";
  while (<SCRIPT>)
  {
    if (/^=/../^=cut/)
    { print README; }
  }
}

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'feedGnuplot',
    license             => 'perl',
    dist_author         => q{Dima Kogan <dkogan@cds.caltech.edu>},
    dist_version_from   => 'bin/feedGnuplot',
    build_requires => {
        'Test::Script::Run' => 0,
    },
    add_to_cleanup      => [ 'feedGnuplot-*' ],
    create_makefile_pl => 'traditional',
    script_files => ['bin/feedGnuplot'],
);

$builder->create_build_script();

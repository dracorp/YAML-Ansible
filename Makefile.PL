use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'YAML::Ansible',
    AUTHOR           => q{Piotr Rogoza <piotr.r.public at gmail.com>},
    VERSION_FROM     => 'lib/YAML/Ansible.pm',
    ABSTRACT_FROM    => 'lib/YAML/Ansible.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'YAML'              => 0,
    },
    "test" => {
        "TESTS" => "t/*.t"
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'YAML-Ansible-*' },
);

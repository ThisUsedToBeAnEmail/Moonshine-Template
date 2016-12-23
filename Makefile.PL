use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Moonshine::Template',
    AUTHOR           => q{lnation <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Moonshine/Template.pm',
    ABSTRACT_FROM    => 'lib/Moonshine/Template.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
    	'Moonshine::Element' => '0.2',
	'UNIVERSAL::Object' => '0.2',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Moonshine-Template-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/Moonshine-Template.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/Moonshine-Template',
            },
        },
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
    },

);    

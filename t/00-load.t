#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'YAML::Ansible' ) || print "Bail out!\n";
}

diag( "Testing YAML::Ansible $YAML::Ansible::VERSION, Perl $], $^X" );

#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::Smartling' ) || print "Bail out!\n";
}

diag( "Testing WebService::Smartling $WebService::Smartling::VERSION, Perl $], $^X" );

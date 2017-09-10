#!/usr/bin/env perl6

use v6;

use lib 'lib';

use Log::ZMQ::LogCatcher;

sub MAIN( Str :$uri, Str :$level = 'info', Str :$prefix = '', Bool :$debug = False,   *@domains  ) {

  my $catcher = $uri.defined ?? LogCatcher.new(:$uri, :$debug) !! LogCatcher.new( :$debug);
  $catcher.set-level-filter( $level);
  $catcher.set-domains-filter(| @domains) if @domains;

  $catcher.run($prefix);

}



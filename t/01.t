#!/usr/bin/env perl6

use v6;

use lib 'lib';

use Test;

BEGIN %*ENV<PERL6_TEST_DIE_ON_FAIL> = 1;

# plan 1;

say "testing Logger";

use Net::ZMQ::Context:auth('github:gabrielash');
use Net::ZMQ::Socket:auth('github:gabrielash');

use Log::ZMQ::Logger;

my $ip = "tcp://127.0.0.1:";
my $port = 4000; 
my $prefix = 'test';

my $uri = $ip ~ ++$port;
my $logsys = Logging::instance($uri
                                , :prefix( $prefix )
                                , :default-level('info')
                                , :format('yaml')
                                , :domain-list( 'dom1', 'dom2') );


$logsys.suppress-level = 'critical';
$logsys.set-suppress-level :info;
#dies-ok { $logsys.set-suppress-level( :info , :critical) } ;
$logsys.unset-suppress-level;

my $log2 = Logging::instance;


sleep 1;

my $logger = $logsys.logger;
my $logger2 = $log2.logger;


sleep 1; 


my $cnt = 0;
my $promise = start { 

      my $ctx = Context.new:throw-everything;
      my $s1 = Socket.new($ctx, :subscriber, :throw-everything);
      ok $s1.connect($uri).defined, "log subscriber connected to $uri";
      ok $s1.subscribe($prefix).defined, "log filtered on dom1" ;
      say "log subscriber ready"; 
      loop {
          my $m = $s1.receive(:slurp) ; 
          say "LOG SUBS\n { $m.perl}";
          $cnt++;
          last if $m ~~ / critical /;
          sleep 1;
      }
    }


sleep 1;
$logger.log('nice day', :dom1 );
$logger2.log('you will never see this', :debug, :dom2 );
$logger.log('another nice day', :critical, :dom1);


await $promise;
ok $cnt == 3, "correct messages seen";


done-testing;

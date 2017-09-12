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


for ^3 { 

my $uri = $ip ~ ++$port;
my $logsys = Logging::logging($uri);
sleep 1;
my $logger = $logsys.logger(:$prefix);
my $logger2 = $logsys.logger(:prefix("--$prefix"), :debug);

ok $logger.defined , 'got logger test';

lives-ok { $logger.domains('dom1', 'dom2' ); } ,"set domains";
lives-ok { $logger.default-level(:info); } ,"set level info";
lives-ok { $logger.target('syslog'); } ,"set target syslog";
lives-ok { $logger.format(:yaml);} ,"set format yaml";
lives-ok { $logger2.format(:yaml);} ,"set format yaml";
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
#          say "LOG SUBS\n { $m.perl}";
          $cnt++;
          last if $m ~~ / critical /;
          sleep 1;
      }
    }


sleep 1;
$logger.log('nice day' );
$logger2.log('you will never see this', :debug );
$logger.log('another nice day', :critical);

await $promise;
ok $cnt == 2, "correct messages seen";

}

done-testing;

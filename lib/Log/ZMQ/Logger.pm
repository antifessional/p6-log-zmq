#!/usr/bin/env perl6

unit module Log::ZMQ::Logger;

use v6;
use JSON::Tiny;

use Net::ZMQ::Context:auth('github:gabrielash');
use Net::ZMQ::Socket:auth('github:gabrielash');
use Net::ZMQ::Message:auth('github:gabrielash');

use Log::ZMQ::Common;


my Str $level = 'warning';
my Str $target = 'user';
my Str $format = 'simple';
my Str $default-domain = 'none';
my %domains = %('none' => 1);

class Logger {...}
class Logging {...}

role yaml-format {
  method yaml-format(:$builder, :$prefix, :$timestamp, :$level, :$domain, :$content, :$target ) {
    $builder.add(qq:to/END_YAML/)
      timestamp: $timestamp
      prefix: "$prefix"
      level: $level
      domain: $domain
      target: $target
      content: "$content"
      END_YAML
      #:
  }
}

role zmq-format {
  method zmq-format(:$builder, :$prefix, :$timestamp, :$level, :$domain, :$content, :$target) {
    $builder.add($content)\
    .add($timestamp)\
    .add($target);
  }
}

role json-format {
  method json-format(:$builder, :$prefix, :$timestamp, :$level, :$domain, :$content, :$target ) {
    my %h = qqw/prefix $prefix level $level domain $domain target $target/;
    %h{'content'}  = $content;
    %h{'timestamp'} = $timestamp;
    $builder.add(to-json(%h));
  }
}

my Logging $log-publisher;

class Logging is export {

  has Str $.uri = $log-uri;
  has Channel $!queue;
  has Promise $!worker;

  our sub logging(Str $uri = $log-uri) is export {
    return $log-publisher if  $log-publisher.defined  &&  $log-publisher.uri eq $uri;
    $log-publisher.DESTROY if $log-publisher.defined;
    $log-publisher = Logging.new(:$uri);
    return $log-publisher;
  }

  method TWEAK()  {
    $!queue .= new;
    $!worker = start {
      my Context $ctx .= new;
      my Socket $socket .= new( $ctx , :publisher );
      $socket.bind( $!uri );
      .send($socket) for $!queue.list;
      $socket.unbind.close;
      $ctx.shutdown;
    }
  }

  method logger(:$prefix!, :$debug) {
       return  Logger.new(
                        :$level
                        , :$target
                        , :$format
                        , :$default-domain
                        , :$prefix
                        , :%domains
                        , :$debug
                        , :$!queue
                        , :logging(self)
                        );

  }

  submethod DESTROY()  {
    $!queue.close;
    await $!worker;
  }

}

class Logger does yaml-format does zmq-format does json-format is export {
  has Logging $.logging is required;
  has Str $.prefix is required;
  has Channel $.queue is required;

  has Str $.level = 'warning';
  has Str $.target = 'user';
  has Str $.format = 'yaml';
  has Str $.default-domain = 'none';
  has %.domains = %('none' => 1);
  has $.debug = False;

  has %!formats;



 method TWEAK {
   my %methods = self.WHAT.^methods.map( { [ $_.name, $_ ] } ).flat;
   %!formats = %methods.keys.grep(/ \-format$ / )\
                                .map( { $_ ~~ m/(.+) \-format$  /;
                                        [ "$0", %methods{$_}] }  )\
                                .flat;
 }

  method default-level(*%h ) { #say  %h.keys[0];
    die "level must be one of { %LEVELS.keys }" unless %h.elems == 1 and  %LEVELS{ %h.keys[0] }:exists;
    $!level = %h.keys[0];
    return self;
  }

  method domains(*@domains) {
    die "at least one domain is required"   unless @domains.elems > 0;
    %!domains = zip(@domains.flat
                      .map( { die "domain $_ is not a String" unless $_.isa(Str) ;$_ }  )
                        , (1 for 0..^@domains.flat.elems)).flat;
    $!default-domain = @domains[0];
    say %!domains;
    return self;
  }

  method target(Str $target) {
    $!target = $target;
    return self;
  }

  method format(*%h) {
    die "format must be one of { %!formats.keys }" unless %h.elems == 1 and  %!formats{ %h.keys[0] }:exists;
    $!format = %h.keys[0];
    return self;
  }

  method log(Str $content, *%h) {
    my $argc =  %h.elems;
    my $err = "you can specifiy a level ({ %LEVELS.keys }) and a domain ({ %!domains.keys })\n ({ %h.keys }) makes no sense";
    die $err unless $argc <= 2;
    my $domain = $!default-domain;
    my $level = $!level;

    for %h.keys  -> $k {
      if %!domains{$k}:exists {
        $domain = $k;
        --$argc;
        last;
      }
    }
    for %h.keys  -> $k {
      if %LEVELS{$k}:exists {
        $level = $k;
        --$argc;
        last
      }
    }

    die $err unless $argc == 0;
    # args checked

    my $timestamp = DateTime.new(now).Str;
    my $builder = MsgBuilder.new\
        .add($!prefix)\
        .add($domain)\
        .add($level)\
        .add($!format)\
        .add(:empty);

    my Method $m = %!formats{$!format};
    $builder = self.$m(:$builder, :$!prefix, :$timestamp
                                            , :$level, :$domain, :$!target, :$content );

    # say "SENT $builder";
    $!queue.send($builder.finalize);
    #$builder.finalize.send( $!logging!Logging::socket );
  }


}

END { $log-publisher.DESTROY if $log-publisher.defined; }

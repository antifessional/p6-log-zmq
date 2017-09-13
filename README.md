# Net::ZMQ

## SYNOPSIS

Log::ZMQ is a Perl6 Logger that used zeromq to log over tcp/ip

## Introduction

The looging is decoupled in a client server architecture. The client sends
log meesages from the application to a LogCatcher listening on a tcp port.

#### Status

In development. This is my learning process of perl6 and ZMQ. I have a lot to learn so use with care.


#### Portability
  depends on Net::ZMQ:auth('github:gabrielash');

## Example Code

#### A
    my $l = Logging::instance( :prefix('example') ).logger;
    $l.log 'an important message';

#### B
    my $logger = Logging::instance('tcp://78.78.1.7:3301')\
                                , :prefix('example')\
                                , :default-level( :warning )\
                                , :domain-list( < database engine front-end nativecall > )\
                                , :format( :json ))\
                          .logger;      

  $logger.log( 'a very important message', :critical, :front-end );

#### C
    # on the command line
    ./log-catcher.pl --uri 'tcp://78.78.1.7:3301' --prefix example --level debug database frontend

## Documentation

#### Log::ZMQ::Logging

  The logging framework based on ZMQ. Usually a singleton summoned with

    my $log-system = Logging::instance(:prefix('prefix')) ;
    my $log-system = Logging.new( 'tcp://127.127.8.17:8022', :prefix('prefix') );

    The default uri is 'tcp://127.0.0.1:3999'

    Attributes
    prefix;   required
    default-level; (default = info)
    format;   default yaml
    domain-list; default ('--')            ;if left blank no domain is required below

  Methods
    logger()  ; returns a Logger
    set-supress-level(:level)               ;silences logging globally
    unset-supress-level()
    add-formatter()                         ;see below
    set-format()                            ;must use this after adding a formatter


#### Log::ZMQ::Logger

The logger

    Methods
      log( log-message, :level, :domain )
        ; level is optional.
        ; domain is optional only if a domain list is not set


The logging uses a publisher socket. All protocols send 5 frames
  1. prefix
  2. domain
  3. level
  4. format [ zmq | yaml | json | ... ]
  5. empty frame

followed with frames that depend on the format.
For zmq:
  6. content
  7. timestamp
  8. target

for yaml/json:
  6. yaml/json formatted  

To add custom formatter, use instance.add-formatter.  
  :(MsgBuilder :builder, :prefix, :timestamp, :level, :domain,  :content
                        --> MsgBuilder ) {
  ... your code here ...
  return $builder;
  }
    the builder should be returned unfinalized.
  then set the format:
    set-format('name');

#### Log::ZMQ::catcher

handles the logging backend, listening to zmq messages.

The wrapper script log-catcher.pl can be invoked from the cli. to see options:
    log-catcher.pl --help

This is the body of the MAIN sub

    my $c = $uri.defined ?? LogCatcher::instance(:$uri, :debug )
                          !! LogCatcher::instance( :$debug );
    $c.set-level-filter( $level);
    $c.set-domains-filter(| @domains) if @domains;
    $c.run($prefix);

current implemention print the received messaged to stdin. other backends can be added
with the following methods:

  add-zmq-handler( &f:(:$content, :$timestamp, :$level, :$domain, :$target) )
  add-handler( Str $format,  &f:(Str:D $content) )


## LICENSE

All files (unless noted otherwise) can be used, modified and redistributed
under the terms of the Artistic License Version 2. Examples (in the
documentation, in tests or distributed as separate files) can be considered
public domain.

ⓒ 2017 Gabriel Ash

# Net::ZMQ

## SYNOPSIS

Log::ZMQ is a Perl6 Logger that used zeromq to log ober tcp/ip

## Introduction

The looging is decoupled in a client server architecture. The client sends
log meesages from the application to a LogCatcher that operates as a server,
listening on a tcp port.

#### Status

In development. This is my learning process of perl6 and ZMQ. I have a lot to learn so use with care.


#### Alternatives

#### Versions

#### Portability
  depends on my Net::ZMQ;

## Example Code

#### A
    my $l = Logging::logging.logger;
    $l.log 'an important message';

#### B
    my $logger = Logging::logging('tcp://78.78.1.7')\
                                .logger\
                                .default-level( :warning )\
                                .domains( < database engine front-end nativecall > )\
                                .target( 'debug' )\
                                .format(:json);

  $logger.log( 'a very important message', :critical, :front-end );


## Documentation

#### Log::ZMQ::Logging

  The logging framework based on ZMQ. Usually a singleton summoned with

    my $log-system = Logging::logging;
    my $log-system = Logging.new( 'tcp://127.127.8.17:8022' );

    The default uri is 'tcp://127.0.0.1:3999'

  Methods
    logger(:prefix)  ; returns a Logger

#### Log::ZMQ::Logger

The logger

    Attributes
      prefix;   required
      level; (default level  = warning)
      target; (default target = user )
      format;   defaulr yaml
      default-domain; default 'none';
      %domains ; keys are legit domain
      debug ;  default False;

    setters
      default-level
      domains( @list)
      target
      format

    Methods
      log( log-message, :level, :domain )

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

To add your own formatter, add a role to the logger with a method
  method name-format(MsgBuilder :builder, :prefix, :timestamp, :level, :domain, :target, :content
                        --> MsgBuilder ) {
  ... your code here ...
  return $builder;
  }
the builder should be returned unfinalized.
then set the format to name:
  $logger.format('name');

#### Log::ZMQ::catcher

handles the logging backend, listening to zmq messages.

The wrapper script log-catcher.pl can be invoked from the cli. to see options:
    log-catcher.pl --help

This is the body of the MAIN sub

    my $c = $uri.defined ?? LogCatcher.instance(:$uri, :$debug )
                          !! LogCatcher.instance( :$debug );
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

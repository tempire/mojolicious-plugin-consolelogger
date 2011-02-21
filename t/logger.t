use Test::More tests => 21;
use Test::Mojo;

# Make sure sockets are working
plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;    # Test server

use Mojolicious::Lite;

plugin 'console_logger';

get '/:template' => sub {
    my $self = shift;
    app->log->info('info');
    app->log->debug('debug');
    app->log->error('error');
    app->log->fatal({json => 'structure'});

    $self->render($self->stash->{template})
      if $self->stash->{template};

    # Template not found, generates exception
    $self->rendered;
};

# Tests
my $client = app->client;
my $t      = Test::Mojo->new;

$t->get_ok($_)->status_is(200)->element_exists('script')
  ->content_like(
    qr/console\.group\("info"\);.*?console\.log\("info"\);.*?console\.groupEnd\("info"\);/
  )
  ->content_like(
    qr/console\.group\("debug"\);.*?console\.log\("debug"\);.*?console\.groupEnd\("debug"\);/
  )
  ->content_like(
    qr/console\.group\("error"\);.*?console\.log\("error"\);.*?console\.groupEnd\("error"\);/
  )
  ->content_like(
    qr/console\.group\("fatal"\);.*?console\.log\({"json":"structure"}\);.*?console\.groupEnd\("fatal"\);/
  )

  for qw| /with_body /without_body /exception |;

__DATA__

@@ with_body.html.ep
<html>
<body>
</body>
</html>

@@ without_body.html.ep
<p></p>

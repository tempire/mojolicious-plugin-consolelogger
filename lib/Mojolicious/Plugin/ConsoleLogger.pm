package Mojolicious::Plugin::ConsoleLogger;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream;
use Mojo::JSON;

our $VERSION = 0.04;

has logs => sub {
  return {
    fatal => [],
    info  => [],
    debug => [],
    error => [],
  };
};

sub register {
  my ($plugin, $app) = @_;

  # override Mojo::Log->log
  no strict 'refs';
  my $stash = \%{"Mojo::Log::"};
  my $orig  = delete $stash->{"log"};

  *{"Mojo::Log::log"} = sub {
    push @{$plugin->logs->{$_[1]}} => $_[-1];

    # Original Mojo::Log->log
    $orig->(@_);
  };

  $app->hook(
    after_dispatch => sub {
      my $self = shift;
      my $logs = $plugin->logs;

      # Leave static content untouched
      return if $self->stash('mojo.static');

      my $str = "\n<!-- Mojolicious logging -->\n<script>\n"
        . "if (window.console) {";

      for (sort keys %$logs) {
        next if !@{$logs->{$_}};
        $str .= "\nconsole.group(\"$_\");";
        $str .= "\n" . _format_msg($_) for splice @{$logs->{$_}};
        $str .= "\nconsole.groupEnd(\"$_\");\n";
      }

      $str .= "}</script>\n";

      $self->res->body($self->res->body . $str);
    }
  );
}

sub _format_msg {
  my $msg = shift;

  return ref($msg)
    ? "console.log(" . Mojo::JSON->new->encode($msg) . "); "
    : "console.log(" . Mojo::ByteStream->new($msg)->quote . "); ";
}

1;

=head1 NAME

Mojolicious::Plugin::ConsoleLogger - Console logging in your browser

=head1 DESCRIPTION

L<Mojolicious::Plugin::ConsoleLogger> pushes Mojolicious log messages to your browser's console tool.

=head1 USAGE

    use Mojolicious::Lite;

    plugin 'console_logger';

    get '/' => sub {

        app->log->debug("Here I am!");
        app->log->error("This is bad");
        app->log->fatal("This is really bad");
        app->log->info("This isn't bad at all");
        app->log->info({json => 'structure'});

        shift->render(text => 'Ahm in ur browzers, logginz ur console');
    };

    app->start;

=head1 METHODS

L<Mojolicious::Plugin::ConsoleLogger> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

    $plugin->register;

Register condition in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>

=head1 DEVELOPMENT

L<http://github.com/tempire/mojolicious-plugin-consolelogger>

=head1 VERSION

0.04

=head1 CREDITS

Implementation stolen from L<Plack::Middleware::ConsoleLogger>

=head1 AUTHOR

Glen Hinkle tempire@cpan.org

Andrew Kirkpatrick

=cut

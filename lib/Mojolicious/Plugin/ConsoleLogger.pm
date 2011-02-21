package Mojolicious::Plugin::ConsoleLogger;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream;
use Mojo::JSON;

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

    # send logs to browser after rendering
    $app->hook(
        after_dispatch => sub {
            my $self = shift;
            my $body = $self->res->body;

            # has body tag
            if ($body =~ m|</body>|) {
                $body =~ s|</body>|_js_log($plugin->logs) . '</body>'|ei;
            }

            # no body tag
            else { $body .= _js_log($plugin->logs) }

            $self->res->body($body);
        }
    );
}

sub _js_log {
    my $logs = shift;

    my $str = "<!-- Mojolicious logging -->\n<script>";

    for (sort keys %$logs) {
        next if !@{$logs->{$_}};
        $str .= "console.group(\"$_\");";
        $str .= _format_msg($_) for @{$logs->{$_}};
        $str .= "console.groupEnd(\"$_\");";
    }

    $str .= "</script>\n";
}

sub _format_msg {
    my $msg = shift;

    return "console.log(" . Mojo::JSON->new->encode($_) . ");" if ref $msg;

    return "console.log(" . Mojo::ByteStream->new($_)->quote . ");";
}

1;

=head1 NAME

Mojolicious::Plugin::ConsoleLogger

=head1 DESCRIPTION

Browser console logging for webkit dev tools/firebug

=head1 USAGE

    use Mojolicious::Lite;

    plugin 'console_logger';

    get '/' => sub {

        app->log->debug("Here I am!");
        app->log->error("This is bad");
        app->log->fatal("This is really bad");
        app->log->info("This isn't bad at all");

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

0.01

=head1 CREDITS

Implementation stolen from L<Plack::Middleware::ConsoleLogger>

=head1 AUTHOR

Glen Hinkle tempire@cpan.org

=cut

package AsyncExample::Controller::AnyEvent::Echo;

use Moose;
use MooseX::MethodAttributes;
use Protocol::WebSocket::Handshake::Server;
use AnyEvent::Handle;

extends 'Catalyst::Controller';

sub start : ChainedParent
 PathPart('echo') CaptureArgs(0) { }

  sub index :Chained('start') PathPart('') Args(0)
  {
    my ($self, $c) = @_;
    my $url = $c->uri_for_action($self->action_for('ws'));
    
    $url->scheme('ws');
    $c->stash(websocket_url => $url);
    $c->forward($c->view('HTML'));
  }

  sub ws :Chained('start') Args(0)
  {
    my ($self, $c) = @_;
    my $io = $c->req->io_fh;
    my $hs = Protocol::WebSocket::Handshake::Server
      ->new_from_psgi($c->req->env);

    $hs->parse($io);

    my $hd = AnyEvent::Handle->new(fh => $io);
    $hd->push_write($hs->to_string);
    $hd->push_write($hs->build_frame(buffer => "Echo Initiated")->to_bytes);

    $hd->on_read(sub {
      (my $frame = $hs->build_frame)->append($_[0]->rbuf);
      while (my $message = $frame->next) {
        $message = $hs->build_frame(buffer => $message)->to_bytes;
        $hd->push_write($message);
      }
    });
  }

__PACKAGE__->meta->make_immutable;


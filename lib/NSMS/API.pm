
package NSMS::API;

use Moose;
use Moose::Util::TypeConstraints;
use Carp;
use Data::Dumper;

use URI::Escape;
use HTTP::Request::Common;
use HTTP::Response;
use LWP::UserAgent;
use JSON;

# ABSTRACT: API para enviar SMS através da NSMS (http://www.nsms.com.br/)

our $VERSION = '0.001'; # VERSION


has ua => (
    is      => 'rw',
    isa     => 'Object',
    lazy    => 1,
    default => sub { LWP::UserAgent->new }
);


has username => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);


has password => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);


has baseurl => (
    is      => 'rw',
    isa     => 'Str',
    default => 'http://api.nsms.com.br/api',
);


has debug => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);


subtype 'NSMS_Number' => as 'Str' => where { $_ =~ /^[0-9]{10}$/ } =>
  message { "The number you provider, $_, was not a mobile number" };

has to => (
    is  => 'rw',
    isa => 'NSMS_Number'
);


subtype 'NSMS_Message' => as 'Str' => where { length($_) < 140 } =>
  message { "The lenght of message has more then 140 chars." };

has text => (
    is  => 'rw',
    isa => 'NSMS_Message'
);

has url_auth => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        join( '/', $self->baseurl, 'auth', $self->username, $self->password );
    }
);

has url_sendsms => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        join( '/', $self->baseurl, 'get', 'json' )
          . '?to=55'
          . $self->to
          . '&content='
          . uri_escape( $self->text );

    }
);


has has_auth => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);

sub _json_to_struct {
    my ( $self, $ret ) = @_;
    $ret = $ret->content if ref($ret) eq 'HTTP::Response';
    my $st = decode_json($ret);
    print Dumper($st) if $self->debug;
    return $st;
}


sub auth {
    my $self = shift;
    warn $self->url_auth if $self->debug;
    my $content = $self->ua->get( $self->url_auth );
    my $ret     = $self->_json_to_struct($content);
    return '' unless $ret->{sms}{ok};
    $self->has_auth(1);
    return $ret->{sms}{ok};
}


sub send {
    my ( $self, $to, $text ) = @_;
    $self->to($to)     if $to;
    $self->text($text) if $text;
    $self->auth unless $self->has_auth;
    warn $self->url_sendsms if $self->debug;
    my $content = $self->ua->get( $self->url_sendsms );
    my $ret     = $self->_json_to_struct($content);
    return $ret->{sms}{ok} || '';
}

1;


__END__
=pod

=head1 NAME

NSMS::API - API para enviar SMS através da NSMS (http://www.nsms.com.br/)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use NSMS::API;

    my $sms = NSMS::API->new(
        username => 'user',
        password => 'pass',
        debug => 0
    );

    $sms->to('1188220000');
    $sms->text('teste de sms');

    # ou

    print $sms->send('1188888888', 'teste de sms');

=head1 DESCRIÇÃO

NSMS::API é uma simples API para enviar sms através da plataforma oferecida pela NSMS, com este módulo você pode usufruir de pequenas operações para facilitar a integração com o seu sistema de forma rápida.

Para mais informações sobre a empresa e o produto, veja L<http://www.nsms.com.br>

=head1 ATRIBUTOS

=head2 ua

Você pode utilizar um user-agent alternativo. (Padrão: LWP::UserAgent)

=head2 username

Usuário NSMS.

=head2 password

Senha NSMS.

=head2 baseurl

URL para requisição na NSMS, não há por que alterar este atributo a não ser que você tenha certeza do que esteja fazendo.

=head2 debug

Opção para imprimir informações relacionada as requisições.

=head2 to

Número de destino. (DDD + Número)

=head2 text

Mensagem para ser enviada, até 140 caracteres.

=head2 has_auth

Verificar se já esta autenticado.

=head1 MÉTODOS

=head2 auth

Autenticar.

=head2 send

send(to, text)

Enviar SMS, opcionalmente pode passar dois parametros, o número de destino e o texto. Porém, caso você não passe estes valores, você deve ter setado eles anteriormente através dos atributos to e text.

=head1 AUTHOR

Thiago Rondon <thiago@nsms.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by NSMS, Thiago Rondon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


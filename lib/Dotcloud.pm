package Dotcloud;

use strict;
use warnings;

use Digest::HMAC_SHA1 qw(hmac_sha1_hex);
use JSON;
use LWP::UserAgent;
use Time::Piece;
use Try::Tiny;
use URI;

use Dotcloud::Config;

my $CLI_VERSION = '0.4.3';
my $USER_AGENT  = "dotcloud/cli (version: $CLI_VERSION)";

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{config} ||= Dotcloud::Config->new->load;

    return $self;
}

sub run {
    my $self = shift;
    my (@cmd) = @_;

    if (@cmd == 1 && $cmd[0] eq 'setup') {
        $self->{config}->setup;
        exit(0);
    }

    my $cmd = encode_json([@cmd]);

    my $uri     = $self->_build_uri($cmd);
    my $headers = $self->_build_headers($self->{config}->{apikey},
        'GET', $uri->path_query);

    my $res = $self->_make_request('GET', $uri, $headers);

    my $content;
    try {
        $content = decode_json($res->{content});
        $content = $content->{data};
        if (ref $content) {
            die 'TODO';
        }
    }
    catch {
        $content = $res->{content};
    };

    print $content, "\n";
}

sub _make_request {
    my $self = shift;
    my ($method, $uri, $headers) = @_;

    my $ua = LWP::UserAgent->new;

    my $res = $ua->get($uri, %$headers);

    $headers = {};
    foreach my $header ($res->headers->header_field_names) {
        $headers->{$header} = $res->headers->header($header);
    }

    return {
        status  => $res->code,
        headers => $headers,
        content => $res->content,
    };
}

sub _build_uri {
    my $self = shift;
    my ($cmd) = @_;

    my $config = $self->{config};

    my $uri    = URI->new($config->{url});
    my $apikey = $config->{apikey};

    $uri->path('run');
    $uri->query_form(q => $cmd);

    return $uri;
}

sub _build_headers {
    my $self = shift;
    my ($apikey, $method, $query) = @_;

    my ($access_key, $secret_key) = split ':', $apikey;

    my $date = Time::Piece->new->strftime('%a, %d %b %Y %H:%M:%S GMT');

    my $signature = join ':', $method, $query, $date;
    $signature = hmac_sha1_hex($signature, $secret_key);

    my $headers = {
        'User-Agent'               => $USER_AGENT,
        'X-DotCloud-Access-Key'    => $access_key,
        'X-DotCloud-Auth-Version'  => '1.0',
        'X-DotCloud-Date'          => $date,
        'X-DotCloud-Authorization' => $signature,
        'X-DotCloud-Version'       => $CLI_VERSION
    };

    return $headers;
}

1;

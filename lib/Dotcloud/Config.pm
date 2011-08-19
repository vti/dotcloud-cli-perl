package Dotcloud::Config;

use strict;
use warnings;

use File::HomeDir;
use File::Spec;
use JSON;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub load {
    my $self = shift;

    if (!-e $self->_config_path) {
        return $self->setup;
    }

    my $config = $self->_slurp($self->_config_path);

    return try {
        my $config = decode_json($config);

        die unless exists $config->{url} && exists $config->{apikey};

        return $config;
    }
    catch {
        die
          'Configuration file not valid. Please run "dotcloud setup" to create it.';
    };
}

sub setup {
    my $self = shift;

    if (!-e $self->_config_dir) {
        mkdir $self->_config_dir, 0700 or die $!;
    }

    my $config = {
        url    => 'https://api.dotcloud.com/',
        apikey => $self->_prompt(
            'Enter your api key (You can find it at http://www.dotcloud.com/accounts/settings): '
        )
    };

    unless ($config->{apikey} =~ m/^\w{20}:\w{40}$/) {
        die('Not a valid api key.');
    }

    my $json = encode_json($config);
    open my $fh, '>', $self->_config_path or die $!;
    print $fh $json;
    close $fh;

    if ($^O ne 'MSWin32') {
        chmod 0600, $self->_config_path;
    }

    unlink $self->_config_key;

    return $config;
}

sub _prompt {
    my $self = shift;
    my ($prompt) = @_;

    print $prompt;
    my $input = <STDIN>;
    chomp $input;

    return $input;
}

sub _config_path {
    my $self = shift;

    return File::Spec->catfile($self->_config_dir, $self->_config_file);
}

sub _config_key {
    my $self = shift;

    my $file = $ENV{DOTCLOUD_CONFIG_FILE} || 'dotcloud';

    return File::Spec->catfile($self->_config_dir, $file . '.key');
}

sub _config_dir {
    my $self = shift;

    return File::Spec->catfile(File::HomeDir->my_home, '.dotcloud');
}

sub _config_file {
    my $self = shift;

    return $ENV{DOTCLOUD_CONFIG_FILE} || 'dotcloud.conf';
}

sub _slurp {
    my $self = shift;
    my ($file) = @_;

    local $/;
    open my $fh, '<', $file or die $!;
    return <$fh>;
}

1;

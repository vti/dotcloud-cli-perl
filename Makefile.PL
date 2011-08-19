#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install;

name 'Dotcloud';

version_from 'lib/Dotcloud.pm';
author 'Viacheslav Tykhanovskyi <vti@cpan.org>';
abstract 'dotCloud cli';
license 'artistic_2';
perl_version '5.008007';

requires 'Carp';

requires 'Digest::HMAC_SHA1';
requires 'File::HomeDir';
requires 'File::Spec';
requires 'JSON';
requires 'LWP::UserAgent';
requires 'Time::Piece';
requires 'Try::Tiny';
requires 'URI';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';

no_index directory => 't';

resources
  bugtracker => 'http://github.com/vti/dotcloud-cli-perl/issues',
  repository => 'http://github.com/vti/dotcloud-cli-perl/',
  license    => 'http://dev.perl.org/licenses/';

auto_install;

WriteAll;

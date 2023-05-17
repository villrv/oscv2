#!/usr/bin/perl -w
use strict;
use Search::Elasticsearch;
use Data::Dumper;

my($creds) = $ENV{'ELASTIC_CREDS'};

my($node);
$node  = {'scheme'    => 'https',
              'host'      => 'localhost',
              'port'      => 9200,
              'path'      => '/',
              'userinfo'  => $creds
};
my($nodes) = [$node];
my($e) = Search::Elasticsearch->new(nodes => $nodes,
                                    trace_to => ['File', 'trace.txt'],
                                    log_to   => ['File', 'log.txt']);

my($results) = $e->indices->create(index=>'supernovae');

print Dumper($results);

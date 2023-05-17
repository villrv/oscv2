#!/usr/bin/perl -w                                                                                                                                                                                                                                                                                                                                                                 
use strict;                                                                                                                                                                                                                                                                                                                                                                        
use FileHandle;                                                                                                                                                                                                                                                                                                                                                                    
use JSON;
use Search::Elasticsearch;
use Data::Dumper;
use Getopt::Long;

my($repoDir) = "/sdb/osc";
my($index) = 'supernovae';

my($opt_Help);
my($opt_RepoUrl);
my($opt_LocalDir);
GetOptions("help"       => \$opt_Help,
           "repoURL=s" => \$opt_RepoUrl,
           "dir=s"  => \$opt_LocalDir);


if (!defined($opt_RepoUrl)) {
    fatalError("No repo specified.\n");
}

if (!defined($opt_LocalDir)) {
    fatalError("No localdir specified.");
}

my($localDirFullPath) = sprintf("%s/%s", $repoDir, $opt_LocalDir);
if (! -d $localDirFullPath) {
    fatalError("Local repo does not exist: %s\n", $localDirFullPath);
}
my($dir)   = $localDirFullPath;
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

my($dh);
opendir($dh, $dir);
my($f);
my($path);
while ($f = readdir($dh)) {
    if ($f =~ /\.json$/) {
        $path = sprintf("%s/%s", $dir, $f);
        indexFile($e, $index, $f, $path, $opt_LocalDir, $opt_RepoUrl);
    }
}

exit(0);
###
###
###
sub indexFile {
    my($e)        = shift;
    my($index)    = shift;
    my($file)     = shift; #The file in the repo.
    my($path)     = shift; #The full path in file system.
    my($localdir) = shift; #Subdir where repo is stored.
    my($repoUrl)  = shift; #URL of repo.
    printf("inserting file: %s\n", $path);
    my($body);
    my(@lines) = `cat '$path'`;
    chomp(@lines);
    $body = join("\n", @lines);
#    printf("body: %s\n", $body);
    my($json) = JSON->new->allow_nonref;
    my($jref) = $json->decode($body);

    my($doc);
    my(@oldSources);
    my(@keys) = keys(%{$jref});
    if (scalar(@keys) != 1) {
        fatalError("Number of top-level keys not equal to 1: %s\n", $path);
    }
    my($key) = pop(@keys);
    my($j) = $jref->{$key};
    
    $doc->{'name'} = $j->{'name'};

    ##
    ## Collect aliases.
    ##
    my($aliases) = $j->{'alias'};
    my($aliasStr) = "";
    my($a);
    for $a (@{$aliases}) {
        $aliasStr .= $a->{'value'} . "\n";
    }
    $doc->{'aliases'} = $aliasStr;

    ##
    ## Collect claimed types.
    ##
    my($types) = $j->{'claimedtype'};
    my($typesStr) = "";
    my($t);
    for $t (@{$types}) {
        $typesStr .= $t->{'value'} . "\n";
    }
    $doc->{'types'} = $typesStr;

    ##
    ## Find RA value.
    ##
    my($ra, @raFields);
    my($h, $m, $s);
    if (defined($j->{'ra'})) {
        $ra = firstValueWithUnit($j->{'ra'}, "hours");
        if (defined($ra)) {
            ($h, $m, $s) = split(':', $ra);
            defined($s) || ($s = 0);
            defined($m) || ($m = 0);        
            $doc->{'ra'} = $ra;
            $doc->{'ra_degrees'} = 15.0 * ($h + ($m/60.0) + ($s/(60.0*60.0)));
        }
    }
    
    ##
    ## Find DEC value.
    ##
    my($dec, @decFields);
    my($deg);
    if (defined($j->{'dec'})) {
        $dec = firstValueWithUnit($j->{'dec'}, "degrees");
        ($deg, $m, $s) = split(':', $dec);
        defined($s) || ($s = 0);
        defined($m) || ($m = 0);
        $doc->{'dec'} = $dec;
        $doc->{'dec_degrees'} = $deg + $m/60.0 + $s/3600.0;
    }

    ##
    ## Num spectra
    ##
    if (defined($j->{'spectra'})) {
        $doc->{'num_spectra'} = scalar(@{$j->{'spectra'}});
    }

    ##
    ## Num photometry
    ##
    if (defined($j->{'photometry'})) {
        $doc->{'num_photometry'} = scalar(@{$j->{'photometry'}});
    }

    copyFirstValue('maxvisualband', $j, $doc);
    copyFirstValue('maxvisualappmag', $j, $doc);
    copyFirstValue('maxvisualabsmag', $j, $doc);
    copyFirstValue('maxappmag', $j, $doc);
    
    copyFirstValueDate('maxvisualdate', $j, $doc);
    copyFirstValueDate('maxdate', $j, $doc);

    copyFirstValueDate('discoverdate', $j, $doc);
    
    copyFirstValue('host', $j, $doc);
    copyFirstValueNumeric('redshift', $j, $doc);

    copyFirstValueWithUnitNumeric('velocity', 'km/s', $j, $doc);
    copyFirstValueWithUnitNumeric('lumdist', 'Mpc', $j, $doc);
    
    $doc->{'filename'} = $file;
    $doc->{'dirname'}  = $localdir;
    $doc->{'repo'}     = $repoUrl;
    my($jsonDoc) = $json->encode($doc);

    my($result) = $e->index('index' => $index,
                            'type'  => '_doc',
                            'body'  => $doc);
}


sub fatalError {
    my($format) = shift;
    printf(STDERR "Error: " . $format . "\n", @_);
    printf(STDERR "Exiting.\n");
    exit(-1);
}

sub firstValueWithUnit {
    my($listRef) = shift;
    my($unit)    = shift;

    my($e);
    for $e (@{$listRef}) {
        if (defined($e->{'u_value'})) {
            if ($e->{'u_value'} eq $unit) {
                return $e->{'value'};
            }
        }
    }
    return;
}

sub firstValue {
    my($listRef) = shift;

    my($e);
    for $e (@{$listRef}) {
        if (defined($e->{'value'})) {
            return $e->{'value'};           
        }
    }
    return;
}

##
## Given a variable, try to copy the first value of the variable
## in the array of values from the given hash to the doc hash.
##
sub copyFirstValue {
    my($var)  = shift;
    my($j)    = shift;
    my($doc)  = shift;
    my($val);
    if (defined($j->{$var})) {
        $val = firstValue($j->{$var});
        if (defined($val)) {
            $doc->{$var} = $val;
        }
    }
}

sub copyFirstValueDate {
    my($var)  = shift;
    my($j)    = shift;
    my($doc)  = shift;
    my($val);
    my($year, $month, $mday);
    my($maxDays) = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (defined($j->{$var})) {
        $val = firstValue($j->{$var});
        if (defined($val)) {
            $val =~ s/^\s*//;
            $val =~ s/\s*$//;
#           if ($val =~ /^[1-9][0-9]{,3}\/[01][1-9]\/[01][0-9]$/) {
            if ($val =~ /^([1-9][0-9]{3})\/([01][0-9])\/([0-3][0-9])$/) {
                $year  = $1;
                $month = $2;
                $mday  = $3;
                $month =~ s/^0//;
                $mday  =~ s/^0//;
                if ($mday <= $maxDays->[$month]) {
                    $doc->{$var} = $val;
                } else {
                    printf("   IGNORING date (%s) because of value: %s\n", $var, $val);
                }
            } else {
                printf("   IGNORING date (%s) malformed: %s\n", $var, $val);
            }
        }
    }
}


##
## Require that the value contain a digit.
##
sub copyFirstValueNumeric {
    my($var)  = shift;
    my($j)    = shift;
    my($doc)  = shift;
    my($val);
    if (defined($j->{$var})) {
        $val = firstValue($j->{$var});
        if (defined($val)) {
            if ($val =~ /[0-9]+/) {
                $doc->{$var} = $val;
            }
        }
    }
}


##
## Given a variable and a unit, try to copy the first value with matching
## unitof the variable in the array of values from the given hash to the doc hash.
##
sub copyFirstValueWithUnit {
    my($var)  = shift;
    my($unit) = shift;
    my($j)    = shift;
    my($doc)  = shift;
    my($val);
    if (defined($j->{$var})) {
        $val = firstValueWithUnit($j->{$var}, $unit);
        if (defined($val)) {
            $doc->{$var} = $val;
        }
    }
}


sub copyFirstValueWithUnitNumeric {
    my($var)  = shift;
    my($unit) = shift;
    my($j)    = shift;
    my($doc)  = shift;
    my($val);
    if (defined($j->{$var})) {
        $val = firstValueWithUnit($j->{$var}, $unit);
        if (defined($val)) {
            if ($val =~ /[0-9]+/) {
                $doc->{$var} = $val;
            }
        }
    }
}

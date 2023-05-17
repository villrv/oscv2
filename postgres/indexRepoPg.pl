#!/usr/bin/perl -w
###
### Author: rdt12@psu.edu
### Date:   Feb 1, 2023
### Desc: Ingest supernova data into a Postgres DB. Note that the db info is hard coded.
###       Also hard coded is a directory where local clones of the git repos can be found.
###
### Usage:  ./indexRepo.pl  --dir=LOCAL_CLONE_DIR  --repoURL=REPO_URL
###
### Example:  ./indexRepo.pl  --dir=sne-2010-2014 --repoURL='https://github.com/astrocatalogs/sne-2010-2014.git'
###
###
use strict;
use DBI;
use FileHandle;
use Cpanel::JSON::XS;
use JSON::MaybeXS;
use Data::Dumper;
use Getopt::Long;

my($repoDir) = "/sdb/osc";
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


my($dh);
opendir($dh, $dir);

my($dbh) = DBI->connect("dbi:Pg:dbname=sdb;host=localhost;port=5432", 'sdb', 'REDACTED_PASSWORD', {AutoCommit => 0, RaiseError => 1, PrintError => 0});
$dbh->trace(1, 'postgreslog.txt');

my($sth) = $dbh->prepare("insert into sdbapp_sdbentry (" .
			 "filename, dirname, \"repoUrl\", aliases, types, " .
			 "ra, ra_degrees, dec, dec_degrees, lumdist, " .
			 "num_spectra, num_photometry, maxabsmag, maxappmag, maxband, " .
			 "maxdate, maxvisualabsmag, maxvisualappmag, maxvisualband, maxvisualdate, " .
			 "host, hostra, hostra_degrees, hostdec, hostdec_degrees, " .
			 "hostoffsetdist, hostoffsetang, redshift, velocity, name" .
			 ") values (" .
			 "?, ?, ?, ?, ?, " .
			 "?, ?, ?, ?, ?, " .
			 "?, ?, ?, ?, ?, " .
			 "?, ?, ?, ?, ?, " .
			 "?, ?, ?, ?, ?, " .
			 "?, ?, ?, ?, ?" .
			 ")");

my($f);
my($path);
			 
while ($f = readdir($dh)) {
    if ($f =~ /\.json$/) {
        $path = sprintf("%s/%s", $dir, $f);
        indexFile($sth, $f, $path, $opt_LocalDir, $opt_RepoUrl);
	$dbh->commit();
    }
}

exit(0);
###
###
###

sub indexFile {
    my($sth)      = shift;
    my($file)     = shift; #The file in the repo.
    my($path)     = shift; #The full path in file system.
    my($localdir) = shift; #Subdir where repo is stored.
    my($repoUrl)  = shift; #URL of repo.
    printf("inserting file: %s\n", $path);
    my($body);
    my(@lines) = `cat '$path'`;
    chomp(@lines);
    $body = join("\n", @lines);
    my($json) = JSON->new->allow_nonref;
    my($jref) = $json->decode($body);
    my(@keys) = keys(%{$jref});
    my($key) = pop(@keys);
    my($j) = $jref->{$key};

#    print STDERR Dumper($j);
    
    ## filename
    $sth->bind_param(1, $file);
    ## dirname
    $sth->bind_param(2, $localdir);
    ## repoUrl
    $sth->bind_param(3, $repoUrl);

    ##
    ## Collect aliases.
    ##
    my($aliases) = $j->{'alias'};
    my($aliasStr) = "";
    my($a);
    for $a (@{$aliases}) {
        $aliasStr .= $a->{'value'} . "\n";
    }
    $sth->bind_param(4, $aliasStr);

    ##
    ## Collect claimed types.
    ##
    my($types) = $j->{'claimedtype'};
    my($typesStr) = "";
    my($t);
    for $t (@{$types}) {
        $typesStr .= $t->{'value'} . "\n";
    }
    $sth->bind_param(5, $typesStr);

    ##
    ## Find RA value.
    ##
    ## Units are "hours" -- hours:min:seconds
    ##
    my($raSet) = 0;
    my($ra, @raFields);
    my($h, $m, $s);
    my($sign);
    if (defined($j->{'ra'})) {
        $ra = firstValueWithUnit($j->{'ra'}, "hours");
        if (defined($ra)) {
            ($h, $m, $s) = split(':', $ra);
	    $sign = 1;
	    if ($h < 0) {
		$sign = -1;
		$h = abs($h);
	    }
            defined($s) || ($s = 0);
            defined($m) || ($m = 0);
	    $sth->bind_param(6, $ra);
	    $sth->bind_param(7, $sign * (15.0 * ($h + ($m/60.0) + ($s/(60.0*60.0)))));
	    $raSet = 1;
        }
    }
    if (!$raSet) {
	    $sth->bind_param(6, undef);
	    $sth->bind_param(7, undef);
    }


    ##
    ## Find DEC value.
    ##
    ## Units are "degrees" -- degreeshours:min:seconds
    ##
    ##
    my($decSet) = 0;
    my($dec, @decFields);
    my($deg);
    if (defined($j->{'dec'})) {
        $dec = firstValueWithUnit($j->{'dec'}, "degrees");
        ($deg, $m, $s) = split(':', $dec);
	$sign = 1;
	if ($deg < 0) {
	    $sign = -1;
	    $deg = abs($deg);
	}
        defined($s) || ($s = 0);
        defined($m) || ($m = 0);
	$sth->bind_param(8, $dec);
	$sth->bind_param(9, $sign * ($deg + $m/60.0 + $s/3600.0));
	$decSet = 1;
    }
    if (!$decSet) {
	    $sth->bind_param(8, undef);
	    $sth->bind_param(9, undef);
    }

    # lumdist
    bindFirstValueWithUnitNumeric($sth, 10, 'lumdist', 'km/s', $j);

    ##
    ## Num spectra 11
    ##
    if (defined($j->{'spectra'})) {
	$sth->bind_param(11, scalar(@{$j->{'spectra'}}));
    } else {
	$sth->bind_param(11, undef);
    }

    ##
    ## Num photometry 12
    ##
    if (defined($j->{'photometry'})) {
	$sth->bind_param(12, scalar(@{$j->{'photometry'}}));
    } else {
	$sth->bind_param(12, undef);
    }
    
    bindFirstValue($sth, 13, 'maxabsmag', $j);
    bindFirstValue($sth, 14, 'maxappmag', $j);
    bindFirstValue($sth, 15, 'maxband', $j);
    bindFirstValueDate($sth, 16, 'maxdate', $j);
    bindFirstValue($sth, 17, 'maxvisualabsmag', $j);
    bindFirstValue($sth, 18, 'maxvisualappmag', $j);
    bindFirstValue($sth, 19, 'maxvisualband', $j);
    bindFirstValueDate($sth, 20, 'maxvisualdate', $j);

    bindFirstValue($sth, 21,'host', $j);

    ##
    ## Find Host RA value.
    ##  hostra     - 22
    ##  hostra_deg - 23
    ##
    my($hostRaSet) = 0;
    my($hostRa, @hostRaFields);
    if (defined($j->{'hostra'})) {
        $hostRa = firstValueWithUnit($j->{'hostra'}, "hours");
        if (defined($hostRa)) {
            ($h, $m, $s) = split(':', $hostRa);
	    $sign = 1;
	    if ($h < 0) {
		$h = abs($h);
		$sign = -1;
	    }
            defined($s) || ($s = 0);
            defined($m) || ($m = 0);
	    $sth->bind_param(22, $hostRa);
	    $sth->bind_param(23, $sign * (15.0 * ($h + ($m/60.0) + ($s/(60.0*60.0)))));
	    $hostRaSet = 1;
        }
    }
    if (!$hostRaSet) {
	    $sth->bind_param(22, undef);
	    $sth->bind_param(23, undef);
    }

    ##
    ## Find Host DEC value.
    ##  hostdec     - 24
    ##  hostdec_deg - 25
    ##
    my($hostDecSet) = 0;
    my($hostDec, @hostDecFields);
    if (defined($j->{'hostdec'})) {
        $hostDec = firstValueWithUnit($j->{'hostdec'}, "degrees");
        if (defined($hostDec)) {
            ($deg, $m, $s) = split(':', $hostDec);
	    $sign = 1;
	    if ($deg < 0) {
		$sign = -1;
		$deg = abs($deg);
	    }
            defined($s) || ($s = 0);
            defined($m) || ($m = 0);
	    $sth->bind_param(24, $hostDec);
	    $sth->bind_param(25, $sign * ($deg + $m/60.0 + $s/3600.0));
	    $hostDecSet = 1;
        }
    }
    if (!$hostDecSet) {
	    $sth->bind_param(24, undef);
	    $sth->bind_param(25, undef);
    }

    bindFirstValueNumeric($sth, 26, 'hostoffsetdist', $j);
    bindFirstValueWithUnit($sth, 27, 'hostoffsetang', 'arcseconds', $j);
    bindFirstValueNumeric($sth, 28, 'redshift', $j);
    bindFirstValueWithUnit($sth, 29, 'velocity', 'km/s', $j);
    
    # name 30
    $sth->bind_param(30, $j->{'name'});

    print("DEBUG 1\n");
    $sth->execute();
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

sub bindFirstValue {
    my($sth) = shift;
    my($num) = shift;
    my($var) = shift;
    my($j)   = shift;
    my($val);
    my($valBound) = 0;
    if (defined($j->{$var})) {
        $val = firstValue($j->{$var});
        if (defined($val)) {
	    $sth->bind_param($num, $val);
	    $valBound = 1;
        }
    }
    if (!$valBound) {
	$sth->bind_param($num, undef);
    }
}

sub bindFirstValueDate {
    my($sth)  = shift;
    my($num)  = shift;
    my($var)  = shift;
    my($j)    = shift;
    my($val);
    my($year, $month, $mday);
    my($maxDays) = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    my($valBound) = 0;
    if (defined($j->{$var})) {
        $val = firstValue($j->{$var});
        if (defined($val)) {
            $val =~ s/^\s*//;
            $val =~ s/\s*$//;
            if ($val =~ /^([1-9][0-9]{3})\/([01][0-9])\/([0-3][0-9])$/) {
                $year  = $1;
                $month = $2;
                $mday  = $3;
                $month =~ s/^0//;
                $mday  =~ s/^0//;
                if ($mday <= $maxDays->[$month]) {
		    $sth->bind_param($num, $val);
		    $valBound = 1;
                } else {
                    printf("   IGNORING date (%s) because of value: %s\n", $var, $val);
                }
            } else {
                printf("   IGNORING date (%s) malformed: %s\n", $var, $val);
            }
        }
    }
    if (!$valBound) {
	$sth->bind_param($num, undef);
    }
}


##
## Require that the value contain a digit.
##
sub bindFirstValueNumeric {
    my($sth)  = shift;
    my($num)  = shift;
    my($var)  = shift;
    my($j)    = shift;
    my($val);
    my($valBound) = 0;
    if (defined($j->{$var})) {
        $val = firstValue($j->{$var});
        if (defined($val)) {
	    if (isNumeric($val)) {
		$sth->bind_param($num, $val);
		$valBound =1;
            }
        }
    }
    if (!$valBound) {
	$sth->bind_param($num, undef);
    }
}

sub bindFirstValueWithUnit {
    my($sth)  = shift;
    my($num)  = shift;
    my($var)  = shift;
    my($unit) = shift;
    my($j)    = shift;
    my($val);
    my($valBound) = 0;
    if (defined($j->{$var})) {
        $val = firstValueWithUnit($j->{$var}, $unit);
        if (defined($val)) {
	    $sth->bind_param($num, $val);
	    $valBound = 1;
        }
    }
    if (!$valBound) {
	$sth->bind_param($num, undef);	
    }
}


sub isNumeric {
    my($val);
    if (defined($val)) {
	if (($val =~ /^[+-]?\d+$/) || ($val =~ /^[+-]?\d+(\.\d+)?$/)) {
	    return 1;
	}
    }
    return 0;
}

sub bindFirstValueWithUnitNumeric {
    my($sth)  = shift;
    my($num)  = shift;
    my($var)  = shift;
    my($unit) = shift;
    my($j)    = shift;
    my($val);
    my($valSet) = 0;
    if (defined($j->{$var})) {
        $val = firstValueWithUnit($j->{$var}, $unit);
        if (defined($val)) {
            if (isNumeric($val)) {
		$sth->bind_param($num, $val);
		$valSet = 1;
            }
        }
    }
    if (!$valSet) {
		$sth->bind_param($num, undef);
    }
}

sub fatalError {
    my($format) = shift;
    printf(STDERR "Error: " . $format . "\n", @_);
    printf(STDERR "Exiting.\n");
    exit(-1);
}

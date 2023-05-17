#!/usr/bin/perl -w
use strict;
use FileHandle;
use JSON::XS;
use Data::Dumper;
use Getopt::Long;

my($dir) = $ARGV[0];

if (!defined($dir)) {
    fatalError("No directory specified.");
}
if (! -d $dir) {
    fatalError("Not a directory: %s", $dir);
}

my($dh);
opendir($dh, $dir);
my($f);
my($path);
#my($json) = JSON->new->allow_nonref;
while ($f = readdir($dh)) {
    if ($f =~ /\.json$/) {
        $path = sprintf("%s/%s", $dir, $f);
        printf("file: %s\n", $f);
        statsForFile($f, $path)
    }
}

exit(0);
###
###
###
sub fatalError {
    my($format) = shift;
    printf(STDERR "Error: " . $format . "\n", @_);
    printf(STDERR "Exiting.\n");
    exit(-1);
}

sub statsForFile {
    my($file) = shift;
    my($path) = shift;
    printf("FILE: %s\n", $file);
    my(@lines) = `cat '$path'`;
    chomp(@lines);
    my($body);
    $body = join("\n", @lines);

    #    my($jref) = $json->decode($body);
    my($jref) = decode_json($body);
    my(@keys) = keys(%{$jref});
    if (scalar(@keys) != 1) {
        fatalError("Number of top-level keys not equal to 1: %s\n", $path);
    }
    my($key) = pop(@keys);
    my($j) = $jref->{$key};
    my(@decs, $v, $uv, $maxdev, $dev, $d, $tot, $davg);
    if (defined($j->{'dec'})) {
        @decs = @{$j->{'dec'}};
        printf("  num decs: %d\n", scalar(@decs));
        if (@decs) {
            $tot = 0;
            for $d (@decs) {
                if (!($d->{'u_value'} eq "degrees")) {
                    fatalError("Unknown u_value: %s", $d->{'u_value'});
                }
                $tot = $tot + $d->{'value'};
            }
            $davg = $tot/scalar(@decs);
            $maxdev = 0;
            for $d (@decs) {
                $dev = abs($davg - $d->{'value'});
                if ($dev > $maxdev) {
                    $maxdev = $dev;
                }
            }
            printf("  avg dec:    %.4f\n", $davg);
            printf("  max decdev: %.4f\n", $maxdev);
        }
    }


    printf("%s:   %d\n", $file, scalar(keys(%{$jref})));

}


exit(0);

###
###
###
sub fatalError {
    my($format) = shift;
    printf(STDERR "Error: " . $format . "\n", @_);
    printf(STDERR "Exiting.\n");
    exit(-1);
}


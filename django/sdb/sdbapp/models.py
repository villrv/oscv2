from django.db import models

# Create your models here.
class SdbEntry(models.Model):
    name            = models.CharField(max_length=512)
    aliases         = models.CharField(max_length=512, null=True)
    types           = models.CharField(max_length=512, null=True)
    host            = models.CharField(max_length=256, null=True)
    hostra          = models.CharField(max_length=32, null=True)
    hostra_degrees  = models.FloatField(null=True)
    hostdec         = models.CharField(max_length=32, null=True)
    hostdec_degrees = models.FloatField(null=True)
    hostoffsetang   = models.FloatField(null=True)
    hostoffsetdist = models.FloatField(null=True)
    ra          = models.CharField(max_length=32, null=True)
    ra_degrees  = models.FloatField(null=True)
    dec         = models.CharField(max_length=32, null=True)
    dec_degrees = models.FloatField(null=True)
    num_spectra = models.IntegerField(null=True)
    num_photometry = models.IntegerField(null=True)
    maxabsmag = models.FloatField(null=True)
    maxappmag = models.FloatField(null=True)
    maxband = models.CharField(max_length=5,null=True)
    maxdate = models.DateTimeField(null=True)
    maxvisualabsmag = models.FloatField(null=True)
    maxvisualappmag = models.FloatField(null=True)
    maxvisualband = models.CharField(max_length=5,null=True)
    maxvisualdate = models.DateTimeField(null=True)
    discoverdate  = models.DateField(null=True)
    discoverer    = models.CharField(max_length=512,null=True)
    redshift      = models.FloatField(null=True)
    velocity      = models.FloatField(null=True)
    lumdist       = models.FloatField(null=True)
    filename      = models.CharField(max_length=1024,null=True)
    dirname       = models.CharField(max_length=2048,null=True)
    repoUrl       = models.CharField(max_length=2048,null=True)
    

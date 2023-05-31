# oscv2
OSC V2

## Authoritative Data

Authoritative Supernova data is stored in git repositories:

* https://github.com/astrocatalogs/sne-pre-1990
* https://github.com/astrocatalogs/sne-1990-1999
* https://github.com/astrocatalogs/sne-2000-2004
* https://github.com/astrocatalogs/sne-2005-2009
* https://github.com/astrocatalogs/sne-2010-2014
* https://github.com/astrocatalogs/sne-2015-2019
* https://github.com/astrocatalogs/sne-2015-2019
* https://github.com/astrocatalogs/sne-2020-2024

At some point, these repositories should be forked so that we can 
write new data.

## Web Frontend

Several web technologies/frameworks were experimented with:

1. Simple CGI 
2. [Hugo](https://gohugo.io/)
3. [Flask](https://flask.palletsprojects.com/en/2.3.x/)
4. [Django](https://www.djangoproject.com/)

Django was chosen because:

1. It has a very easy to use object oriented interface to databases.
2. It has some support for OpenSearch.
3. It is popular. Finding developers to take on task will be much easier than for a bespoke system.

## Online SDB Data

Data from the git repositories is ingested into online databases for use by the SDB website.

Two backend databases have been experimented with: Postgres and OpenSearch. This
repository contains scripts for adding data from the repositories to both Postgres
and OpenSearch.

Initially, the site was to be based on OpenSearch. As the design of the site evolved from
a set of CGI scripts to Django, it became apparent that the least effort method of interfacing
Python/Django to the supernova data would be a standard SQL database.

Postgres was chosen but the choice was not dictated by any requirements. MySQL would probably perform just as well. There may be some differences in text searching. 

## Running Postgres and Opensearch

Docker compose files for running Postgres and Opensearch are in [the docker directory](docker/).

## Development Website Operation

Running the development website is standard for Django, but some basic commands are:


|Task   | Command|
|-------|--------|
|Start the server | `python3 manage.py runserver 0.0.0.0:80` |
|Make migration script after updating a model | `python3 manage.py makemigration` |
|Run the migration script | `python3 manage.py migrate` |
|Interact with the site (python shell) | `python3 manage.py shell` |


## Ingesting data into OpenSearch

The script for indexing a repo in OpenSearch (a fork of ElasticSearch) is [elastic/indexRepoElastic.pl](elastic/indexRepoElastic.pl).

The script currently has some hard coded values that have to be modified. The most important is `repoDir`. You have to specify
a `USERNAME:PASSWORD` string as the environment variable `ELASTIC_CREDS`.

Example command:
```
   export ELASTIC_CREDS=user:pass
   /indexRepoElastic.pl  --dir=sne-2010-2014 --repoURL='https://github.com/astrocatalogs/sne-2010-2014.git'

```
It is better to have the string in a file and do ``ELASTIC_CREDS=`cat foo.creds``` to avoid saving the creds in a shell history file.

## Ingesting data into Postgres

The script for indexing a reop in Postgres is [postgres/indexRepoPg.pl](postgres/indexRepoPg.pl).

The script currently has some hard coded values. Replace the string `REDACTED_PASSWORD` with the password for a dabase named `sdb`.

Example command:
```
    /indexRepoPg.pl  --dir=sne-2010-2014 --repoURL='https://github.com/astrocatalogs/sne-2010-2014.git'
```

### The Supernova Data Model

The model is defined in Django in [django/sdb/sdbapp/models.py](django/sdb/sdbapp/models.py).

If you change the model, you have to do:
```
   python3 manage.py makemigration
   python3 manage.py migrate
```

to update the database structure.

You will then have to modify [postgres/indexRepoPg.pl](postgres/indexRepoPg.pl), drop all of the data and reindex the repos. You could conceivably write a scritp to just insert the data appropriate to the change, but reindexing is probably safer and easier.

While often Django is used to allow users to write the database objects, we don't because the DB isn't
authoritative. Eventually we might want to allow users to submit new data, but when we do, they will
submit it, there will be a review process likely involving a human, and eventually the data will be
added to a git repo and then indexed.

### Completed

1. _Django:_ Project Structure
2. _Model:_ Most of the work on the Model. Some fields may need to be added, but it is reasonably complete. Adding additional fields is straightforward (described above).
3. _Pagination:_ Pagination has been implemented. 
4. _Search:_ The basic search structure has been implemented.

### TODO

1. _Search:_ Complete the implementation of the search functionality.
2. _Search:_ Style the search form.

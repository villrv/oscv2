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

Postgres was chosen but the choice was not dictated by any requirements.

## Development Website Operation

Running the development website is standard for Django, but some basic commands are:


|Task   | Command|
|-------|--------|
|Start the server | `python3 manage.py runserver 0.0.0.0:80` |
|Make migration script after updating a model | `python3 manage.py makemigration` |
|Run the migration script | `python3 manage.py migrate` |
|Interact with the site (python shell) | `python3 manage.py shell` |


## Ingesting data

Example




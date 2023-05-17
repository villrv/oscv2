# Opensearch

Before running ths container, set `opensearch.password` in `opensearch_dashboards.yml` and generate hashes for Opensearch internal users in `opensearch-internal_users.yml`.

You can generate hashes with a docker command like so:
```

   docker run -it --rm opensearchproject/opensearch:2.1.0 /usr/share/opensearch/plugins/opensearch-security/tools/hash.sh

```
You will be prompted for a password to hash and a hash will be printed to stdout.


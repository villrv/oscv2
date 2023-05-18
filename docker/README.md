### Containers

The two directories `/opensearch` and `/postgres` condtain `docker-compose.yml` files for managing running opensearch and postgres 
as containers under using [docker](https://docs.docker.com/compose/) and [docker-compose](https://docs.docker.com/compose/).

Docker-compose used to be distributed as a separate program, `docker-compose`. Recent versions of docker have `compose` available 
as a module. Docker-compose commands are run in a directory containing a file named `docker-compose.yml` and affect only
the contianers mentioned in that file. When using a module, run `docker compose` instead of `docker-compose`.

The configuration of the containers will require some tuning for a new environment.

## Common commands


|Task   | Command|
|-------|--------|
|Start a container | `docker-compose up -d` |
|Stop a container  | `docker-compose down` | 
|List running containers | `docker ps`|
|Get a shell in a container | `docker exec -it CONTAINER_NAME /bin/bash` |





Place in this folder the postgres backups, eg: lavaserver.sql (or lavaserver.sql.gz) script.
Then do:
  docker-compose stop
  docker container rm docker-compose_db_1; docker volume rm lava-server-pgdata
  docker-compose -f docker-compose.yaml -f docker-compose-restore-backup.yaml up -d
  docker logs docker-compose_db_1

In the logs, verify the backup was succesfully restored, with a trace like this:
  /usr/local/bin/docker-entrypoint.sh: running /docker-entrypoint-initdb.d/lavaserver.sql

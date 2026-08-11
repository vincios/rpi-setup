#!/bin/bash

# Use the value of the corresponding environment variable, or the
# default if none exists.
: ${IMMICH_ROOT:="$(pwd)"}
: ${IMMICH_DATABASE_NAME:="immich"}
: ${IMMICH_POSTGRES_CONTAINER:="immich_postgres"}
: ${IMMICH_POSTGRES_USER:="postgres"}

IMMICH_VERSION=$(docker exec -t immich_server immich --version | tr -d '\r' || "n.a.")
POSTGRES_VERSION=$(docker exec ${IMMICH_POSTGRES_CONTAINER} psql -U postgres -c "SELECT version();" | grep PostgreSQL | cut -d " " -f 3 || "n.a.")

BACKUP_DIR_PATH="${IMMICH_ROOT}/data-backups"
BACKUP_FILE_NAME="immich-database-${IMMICH_VERSION}-${POSTGRES_VERSION}.sql"


cd "${IMMICH_ROOT}"
rm -rf ${BACKUP_DIR_PATH}

if [ ! -d $BACKUP_DIR_PATH ]; then
  mkdir $BACKUP_DIR_PATH
fi

docker exec -t ${IMMICH_POSTGRES_CONTAINER} pg_dump --clean --if-exists --dbname=${IMMICH_DATABASE_NAME} --username=${IMMICH_POSTGRES_USER} | gzip > "${BACKUP_DIR_PATH}/${BACKUP_FILE_NAME}.gz"

# To restore see https://docs.immich.app/administration/backup-and-restore/#restore-cli


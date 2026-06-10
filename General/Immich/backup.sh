#!/bin/bash

# Use the value of the corresponding environment variable, or the
# default if none exists.
: ${IMMICH_ROOT:="$(pwd)"}
: ${IMMICH_POSTGRES_CONTAINER:="immich_postgres"}
: ${IMMICH_POSTGRES_USER:="postgres"}

BACKUP_DIR_PATH="${IMMICH_ROOT}/data-backups"
BACKUP_FILE_NAME="immich-database.sql"

cd "${IMMICH_ROOT}"

if [ ! -d $BACKUP_DIR_PATH ]; then
  mkdir $BACKUP_DIR_PATH
fi

docker exec -t ${IMMICH_POSTGRES_CONTAINER} pg_dumpall --clean --if-exists --username=${IMMICH_POSTGRES_USER} | gzip > "${BACKUP_DIR_PATH}/${BACKUP_FILE_NAME}.gz"

# To restore:
#   gunzip -k < "${BACKUP_DIR_PATH}/${BACKUP_FILE_NAME}.gz" | docker exec -i ${IMMICH_POSTGRES_CONTAINER} psql -U ${IMMICH_POSTGRES_USER}


#!/bin/bash

# Use the value of the corresponding environment variable, or the
# default if none exists.
: ${ROOT:="$(pwd)"}
: ${APP_CONTAINER:="outline_server"}
: ${POSTGRES_CONTAINER:="outline_postgres"}
: ${POSTGRES_USER:="postgres"}

APP_VERSION=$(docker exec $APP_CONTAINER cat /opt/outline/package.json | jq -r ".version")

if [ -z "$APP_VERSION" ]; then
    APP_VERSION="N.A."
fi

POSTGRES_VERSION=$(docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -c "SELECT version();" | grep PostgreSQL | cut -d " " -f 3 || "n.a.")

BACKUP_DIR_PATH="${ROOT}/backups"
BACKUP_FILE_NAME="outline-database-${APP_VERSION}-${POSTGRES_VERSION}.sql"

cd "${ROOT}"

echo "Deleting old backups..."
rm -rf ${BACKUP_DIR_PATH}
if [ ! -d $BACKUP_DIR_PATH ]; then
  mkdir $BACKUP_DIR_PATH
fi

echo "Making backup..."
docker exec -t ${POSTGRES_CONTAINER} pg_dumpall -c -U ${POSTGRES_USER} | gzip > "${BACKUP_DIR_PATH}/${BACKUP_FILE_NAME}.gz"

echo "Done"
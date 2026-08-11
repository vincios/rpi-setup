#!/bin/bash

# Use the value of the corresponding environment variable, or the
# default if none exists.
: ${NETBIRD_ROOT:="$(pwd)"}
: ${NB_POSTGRES_CONTAINER:="netbird-database"}
: ${NB_POSTGRES_USER:="postgres"}

: ${NETBIRD_API_TOKEN:=""}

NETBIRD_REQUEST=$(curl -s -f https://netbird.example.com/api/instance/version -H "Accept: application/json" -H "Authorization: Token ${NETBIRD_API_TOKEN}")
NETBIRD_VERSION=$(echo $NETBIRD_REQUEST | jq -r ".management_current_version")


if [ -z "$NETBIRD_VERSION" ]; then
    NETBIRD_VERSION="N.A."
fi

POSTGRES_VERSION=$(docker exec $NB_POSTGRES_CONTAINER psql -U postgres -c "SELECT version();" | grep PostgreSQL | cut -d " " -f 3 || "n.a.")

BACKUP_DIR_PATH="${NETBIRD_ROOT}/backups"
BACKUP_FILE_NAME="netbird-database-${NETBIRD_VERSION}-${POSTGRES_VERSION}.sql"

cd "${NETBIRD_ROOT}"

echo "Deleting old backups..."
rm -rf ${BACKUP_DIR_PATH}
if [ ! -d $BACKUP_DIR_PATH ]; then
  mkdir $BACKUP_DIR_PATH
fi

echo "Making backup..."
docker exec -t ${NB_POSTGRES_CONTAINER} pg_dumpall -c -U ${NB_POSTGRES_USER} | gzip > "${BACKUP_DIR_PATH}/${BACKUP_FILE_NAME}.gz"

echo "Done"
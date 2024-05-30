#!/bin/bash

# Use the value of the corresponding environment variable, or the
# default if none exists.
: ${VAULTWARDEN_ROOT:="$(pwd)"}
: ${SQLITE3:="/usr/bin/sqlite3"}

DATA_DIR="${VAULTWARDEN_ROOT}/vw-data"
BACKUP_DIR_NAME="vw-data-backup"
BACKUP_DIR_PATH="${VAULTWARDEN_ROOT}/${BACKUP_DIR_NAME}"
DB_FILE="db.sqlite3"

rm -rf "${BACKUP_DIR_PATH}"
cd "${VAULTWARDEN_ROOT}"
mkdir -p "${BACKUP_DIR_PATH}"

# Back up the database using the Online Backup API (https://www.sqlite.org/backup.html)
# as implemented in the SQLite CLI. However, if a call to sqlite3_backup_step() returns
# one of the transient errors SQLITE_BUSY or SQLITE_LOCKED, the CLI doesn't retry the
# backup step by default; instead, it stops the backup immediately and returns an error.
#
# Encountering this situation is unlikely, but to be on the safe side, the CLI can be
# configured to retry by using the `.timeout <ms>` meta command to set a busy handler
# (https://www.sqlite.org/c3ref/busy_timeout.html), which will keep trying to open a
# locked table until the timeout period elapses.
busy_timeout=30000 # in milliseconds
${SQLITE3} -cmd ".timeout ${busy_timeout}" \
           "file:${DATA_DIR}/${DB_FILE}?mode=ro" \
           ".backup '${BACKUP_DIR_PATH}/${DB_FILE}'"

backup_files=()
for f in attachments config.json rsa_key.der rsa_key.pem rsa_key.pub.der rsa_key.pub.pem sends; do
    if [[ -e "${DATA_DIR}"/$f ]]; then
        backup_files+=("${DATA_DIR}"/$f)
    fi
done
cp -a "${backup_files[@]}" "${BACKUP_DIR_PATH}"

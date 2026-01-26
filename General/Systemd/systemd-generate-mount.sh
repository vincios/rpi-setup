#!/bin/bash
# Usage: ./systemd-generate-mount.sh [OPTIONS] "<fstab_string>"
# 
# Description:
#   This script generates systemd .mount and .automount unit files in the current
#   directory. It uses 'systemd-escape' to ensure the filename correctly
#   matches the destination path.
# 
# Arguments:
#   "<fstab_string>"  A single string containing: <source> <target> <type> <options> <dump> <pass>
# 
# Options:
#   -h, --help       Show this detailed help message.
# 
# Example:
#   ./systemd-generate-mount.sh "//192.168.1.200/Share /media/mnt cifs credentials=/path/to/creds,uid=1000 0 0"

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS] \"<fstab_string>\""
    echo
    echo "Description:"
    echo "  This script generates systemd .mount and .automount unit files in the current"
    echo "  directory. It uses 'systemd-escape' to ensure the filename correctly"
    echo "  matches the destination path."
    echo
    echo "Arguments:"
    echo "  \"<fstab_string>\"  A single string containing: <source> <target> <type> <options> <dump> <pass>"
    echo
    echo "Options:"
    echo "  -h, --help       Show this detailed help message."
    echo
    echo "Example:"
    echo "  $0 \"//192.168.1.200/Share /media/mnt cifs credentials=/path/to/creds,uid=1000 0 0\""
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Check if an input string was provided
if [ -z "$1" ]; then
    echo "Error: No input provided."
    show_help
    exit 1
fi

read -r WHAT WHERE TYPE OPTIONS REST <<< "$1"
CLEAN_WHERE=$(echo "$WHERE" | sed 's:/*$::')

# Generate filenames [cite: 1, 2]
MOUNT_FILE=$(systemd-escape --suffix=mount -p "$CLEAN_WHERE")
AUTOMOUNT_FILE=$(systemd-escape --suffix=automount -p "$CLEAN_WHERE")

DESC_MOUNT="Mount share $WHAT on $CLEAN_WHERE"
DESC_AUTOMOUNT="Automount for share $WHAT on $CLEAN_WHERE"

echo "Generating files in current directory..."

# 1. Create .mount file 
cat <<EOF > "$MOUNT_FILE"
[Unit]
Description=$DESC_MOUNT
Requires=network-online.target
After=network-online.service

[Mount]
What=$WHAT
Where=$CLEAN_WHERE
Type=$TYPE
Options=$OPTIONS

[Install]
WantedBy=multi-user.target
EOF

# 2. Create .automount file 
cat <<EOF > "$AUTOMOUNT_FILE"
[Unit]
Description=$DESC_AUTOMOUNT

[Automount]
Where=$CLEAN_WHERE

[Install]
WantedBy=multi-user.target
EOF

echo "---"
echo "Files generated:"
echo " - $MOUNT_FILE"
echo " - $AUTOMOUNT_FILE"
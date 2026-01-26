#!/bin/bash
# Usage: sudo ./systemd-install-mount.sh [OPTIONS] "<fstab_string>"
# 
# Description:
#   This script generates systemd .mount and .automount unit files based on a
#   string formatted like an /etc/fstab entry. It automatically installs them
#   to /etc/systemd/system/ and reloads the systemd manager.
# 
# Arguments:
#   "<fstab_string>"  A single string containing: <source> <target> <type> <options> <dump> <pass>
# 
# Options:
#   -h, --help       Show this detailed help message.
# 
# Example:
#   sudo ./systemd-install-mount.sh "//192.168.1.200/Share /media/mnt cifs credentials=/path/to/creds,uid=1000 0 0"


# Function to display help
show_help() {
    echo "Usage: sudo $0 [OPTIONS] \"<fstab_string>\""
    echo
    echo "Description:"
    echo "  This script generates systemd .mount and .automount unit files based on a"
    echo "  string formatted like an /etc/fstab entry. It automatically installs them"
    echo "  to /etc/systemd/system/ and reloads the systemd manager."
    echo
    echo "Arguments:"
    echo "  \"<fstab_string>\"  A single string containing: <source> <target> <type> <options> <dump> <pass>"
    echo
    echo "Options:"
    echo "  -h, --help       Show this detailed help message."
    echo
    echo "Example:"
    echo "  sudo $0 \"//192.168.1.200/Share /media/mnt cifs credentials=/path/to/creds,uid=1000 0 0\""
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Root privilege check
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root (use sudo)."
   exit 1
fi

# Check if an input string was provided
if [ -z "$1" ]; then
    echo "Error: No input provided."
    show_help
    exit 1
fi

TARGET_DIR="/etc/systemd/system"
read -r WHAT WHERE TYPE OPTIONS REST <<< "$1"
CLEAN_WHERE=$(echo "$WHERE" | sed 's:/*$::')

# Generate filenames
MOUNT_FILE=$(systemd-escape --suffix=mount -p "$CLEAN_WHERE")
AUTOMOUNT_FILE=$(systemd-escape --suffix=automount -p "$CLEAN_WHERE")

DESC_MOUNT="Mount share $WHAT on $CLEAN_WHERE"
DESC_AUTOMOUNT="Automount for share $WHAT on $CLEAN_WHERE"

echo "--- Systemd Unit Generation ---"
echo "Target: $CLEAN_WHERE"

# 1. Create .mount file 
cat <<EOF > "$TARGET_DIR/$MOUNT_FILE"
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
cat <<EOF > "$TARGET_DIR/$AUTOMOUNT_FILE"
[Unit]
Description=$DESC_AUTOMOUNT

[Automount]
Where=$CLEAN_WHERE

[Install]
WantedBy=multi-user.target
EOF

echo "Files created in $TARGET_DIR:"
echo " - $MOUNT_FILE"
echo " - $AUTOMOUNT_FILE"

echo "Setting permissions..."
chmod 644 "$TARGET_DIR/$MOUNT_FILE" "$TARGET_DIR/$AUTOMOUNT_FILE"

echo "Reloading systemd (daemon-reload)..."
systemctl daemon-reload

echo "Operation completed successfully."
echo "You can now enable the automount with:"
echo "   systemctl enable --now $AUTOMOUNT_FILE"

echo "Also, you can:"
echo "  - mount the share: systemctl start $MOUNT_FILE"
echo "  - enable mount on boot: systemctl enable $MOUNT_FILE"

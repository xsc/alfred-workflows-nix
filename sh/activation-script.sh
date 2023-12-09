#!/bin/sh
#
set -eu

WORKDIR=$(readlink -f $(dirname "$0"))
WORKFLOW_NAME=$(basename "$WORKDIR")
TARGET_DIR="$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/$WORKFLOW_NAME"

mkdir -p "$TARGET_DIR"

# Backup settings
if [ -f "$TARGET_DIR/info.plist" ]; then
    mv -f "$TARGET_DIR/info.plist" "$TARGET_DIR/info.plist.backup"
fi

# Symlink workflow
ln -sf $WORKDIR/workflow/* "$TARGET_DIR"

# Restore backed up settings
# OR Replace the symlinked settings with a mutable file
if [ -f "$TARGET_DIR/info.plist.backup" ]; then
    mv -f "$TARGET_DIR/info.plist.backup" "$TARGET_DIR/info.plist"
else
    rm "$TARGET_DIR/info.plist"
    cp -fL $WORKDIR/workflow/info.plist "$TARGET_DIR"
fi
chmod 644 "$TARGET_DIR/info.plist"

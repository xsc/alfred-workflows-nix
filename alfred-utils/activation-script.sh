#!/bin/sh
#
set -eu

WORKDIR=$(readlink -f $(dirname "$0"))
WORKFLOW_NAME=$(basename "$WORKDIR")
TARGET_DIR="$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/$WORKFLOW_NAME"

# Backup and re-create workflow directory
if [ -d "$TARGET_DIR" ]; then
    mv "$TARGET_DIR" "$TARGET_DIR.backup"
fi
mkdir -p "$TARGET_DIR"

# Symlink workflow
cp -rsf $WORKDIR/workflow/* "$TARGET_DIR"

# Restore backed up settings
# OR Replace the symlinked settings with a mutable file
if [ -f "$TARGET_DIR.backup/info.plist" ]; then
    mv -f "$TARGET_DIR.backup/info.plist" "$TARGET_DIR/info.plist"
else
    rm "$TARGET_DIR/info.plist"
    cp -fL $WORKDIR/workflow/info.plist "$TARGET_DIR"
fi
if [ -f "$TARGET_DIR.backup/prefs.plist" ]; then
    mv -f "$TARGET_DIR.backup/prefs.plist" "$TARGET_DIR/prefs.plist"
fi

# Make directories and settings files
[ ! -f "$TARGET_DIR/info.plist" ] || chmod 644 "$TARGET_DIR/info.plist"
[ ! -f "$TARGET_DIR/prefs.plist" ] || chmod 644 "$TARGET_DIR/prefs.plist"
find "$TARGET_DIR" -type d -exec chmod -f 755 {} \;

# Remove backup
rm -rf "$TARGET_DIR.backup"
echo "Activated Alfred workflow: $WORKFLOW_NAME"

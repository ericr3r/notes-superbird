#/usr/bin/env sh

# Ensure the sudoers.d directory exists
mkdir -p ${TARGET_DIR}/etc/sudoers.d

# Add the superbird user to the sudoers file
echo "superbird ALL=(ALL) NOPASSWD: ALL" >${TARGET_DIR}/etc/sudoers.d/superbird

# Set the correct permissions for the sudoers file
chmod 440 ${TARGET_DIR}/etc/sudoers.d/superbird

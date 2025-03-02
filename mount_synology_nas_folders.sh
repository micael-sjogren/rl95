#!/bin/bash

# Define NAS details
NAS_IP="192.168.6.98"
USERNAME="YOUR_USERNAME"
PASSWORD="YOUR_PASSWORD"

# List of NAS folders and local mount points
declare -A NAS_FOLDERS=(
    ["Micaels"]="/mnt/nas_micaels"
    ["Movies"]="/mnt/nas_movies"
    ["Series"]="/mnt/nas_series"
    ["Musik"]="/mnt/nas_music"
    ["torrent_files"]="/mnt/nas_torrent_files"
    ["rocky_linux"]="/mnt/nas_rocky_linux"
)

# Ensure CIFS utilities are installed
echo "Installing cifs-utils..."
sudo dnf install -y cifs-utils

# Create credentials file securely
CREDENTIALS_FILE="/etc/.smbcredentials"
echo "Creating credentials file at $CREDENTIALS_FILE..."
sudo bash -c "echo 'username=$USERNAME' > $CREDENTIALS_FILE"
sudo bash -c "echo 'password=$PASSWORD' >> $CREDENTIALS_FILE"
sudo chmod 600 $CREDENTIALS_FILE

# Unmount existing mounts and clean up /etc/fstab
echo "Unmounting existing NAS mounts..."
for FOLDER in "${!NAS_FOLDERS[@]}"; do
    LOCAL_PATH="${NAS_FOLDERS[$FOLDER]}"

    # Unmount if already mounted
    if mount | grep -q "$LOCAL_PATH"; then
        echo "Unmounting $LOCAL_PATH..."
        sudo umount -l "$LOCAL_PATH"
    fi

    # Remove old fstab entry if it exists
    sudo sed -i "\|//$NAS_IP/$FOLDER|d" /etc/fstab
done

# Add mounts back to /etc/fstab and remount
echo "Configuring /etc/fstab..."
for FOLDER in "${!NAS_FOLDERS[@]}"; do
    LOCAL_PATH="${NAS_FOLDERS[$FOLDER]}"
    
    # Create mount directory if it doesn't exist
    sudo mkdir -p "$LOCAL_PATH"

    # Set proper permissions (change 1000 to your user ID if needed)
    sudo chown 1000:1000 "$LOCAL_PATH"
    sudo chmod 775 "$LOCAL_PATH"

    # Add to /etc/fstab
    echo "//$NAS_IP/$FOLDER $LOCAL_PATH cifs credentials=$CREDENTIALS_FILE,vers=3.0,rw,uid=1000,gid=1000,file_mode=0777,dir_mode=0777,nofail,x-systemd.automount 0 0" | sudo tee -a /etc/fstab
done

# Reload systemd and remount all shares
echo "Reloading systemd and remounting all shares..."
sudo systemctl daemon-reload
sudo mount -a

echo "✅ All NAS folders have been unmounted and remounted successfully!"

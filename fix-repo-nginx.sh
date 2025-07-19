#!/bin/bash

set -e

REPO_FILE="/etc/apt/sources.list.d/nginx.list"
KEYRING_PATH="/usr/share/keyrings/nginx-archive-keyring.gpg"
DISTRO="jammy"

echo "[+] Fixing NGINX APT source..."

# Remove broken repo line if it exists
if grep -q 'nginx.org' "$REPO_FILE" 2>/dev/null; then
    echo "[-] Removing invalid repo entry..."
    sudo rm -f "$REPO_FILE"
fi

# Add official GPG key
echo "[+] Adding NGINX GPG key..."
curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo gpg --dearmor -o "$KEYRING_PATH"

# Add corrected repo
echo "[+] Writing correct NGINX repo..."
echo "deb [signed-by=$KEYRING_PATH] https://nginx.org/packages/mainline/ubuntu $DISTRO nginx" | sudo tee "$REPO_FILE" > /dev/null

# Update and upgrade
echo "[+] Updating packages..."
sudo apt update && sudo apt upgrade -y

echo "[✓] NGINX repo fixed and system updated."

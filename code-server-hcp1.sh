#!/bin/bash
# Richard's all-in-one HCP1 dev cockpit installer
# Sets hostname, installs code-server, GitHub CLI, Tailscale, and fish
# Copyright (c) 2025 Richard Knowles

set -e

# === 1. Hostname Setup ===
echo "[*] Setting hostname to hcp1.dev.alisium.run"
sudo hostnamectl set-hostname hcp1
echo "hcp1.dev.alisium.run" | sudo tee /etc/hostname
echo "127.0.1.1 hcp1.dev.alisium.run hcp1" | sudo tee -a /etc/hosts

# === 2. Install Prerequisites ===
echo "[*] Installing packages..."
sudo apt update
sudo apt install -y curl git software-properties-common

# === 3. Install code-server ===
echo "[*] Installing code-server..."
curl -fsSL https://code-server.dev/install.sh | sh

echo "[*] Creating config directory..."
mkdir -p ~/.config/code-server

cat <<EOF > ~/.config/code-server/config.yaml
bind-addr: 0.0.0.0:8080
auth: password
password: richrules
cert: false
EOF

echo "[*] Enabling code-server systemd service..."
sudo systemctl enable --now code-server@$USER

# === 4. Install GitHub CLI ===
echo "[*] Installing GitHub CLI..."
type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
  sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
  sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y

# === 5. Install Fish Shell ===
echo "[*] Installing fish..."
sudo apt install -y fish
chsh -s /usr/bin/fish

# === 6. Optional: Install Tailscale ===
echo "[*] Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
echo "[*] To connect, run: sudo tailscale up"

# === 7. MOTD Bling ===
echo "[*] Adding MOTD message..."
echo -e "\n💻 Welcome back, Commander Knowles. Your cockpit awaits. 💻\n" | sudo tee /etc/motd

# === 8. Finish ===
echo -e "\n✅ DONE! Visit your cockpit at: http://hcp1.dev.alisium.run:8080"
echo "👉 Default password: richrules"
echo "👉 Recommend: Add this domain to your Tailscale DNS or Cloudflare!"

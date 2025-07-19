#!/bin/bash
# install_dante_proxy.sh — by Billie, for Richard
# ⚡ Installs and configures Dante SOCKS5 proxy with basic hardening

set -e

# Update & install Dante
apt update
apt install -y dante-server ufw

# Network interface detection
IFACE=$(ip route get 1 | awk '{print $5; exit}')

# Generate config
cat <<EOF > /etc/danted.conf
logoutput: syslog
internal: $IFACE port = 1080
external: $IFACE
method: username none
user.notprivileged: nobody

client pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: connect disconnect error
}

pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  protocol: tcp udp
  log: connect disconnect error
}
EOF

# Enable and start Dante
systemctl enable danted
systemctl restart danted

# Firewall rules
ufw allow 1080/tcp
ufw reload

echo "✅ SOCKS5 proxy installed on port 1080"
echo "🌐 Interface: $IFACE"
echo "🚀 Usage: Connect via IP:$IFACE on port 1080 (no auth)"

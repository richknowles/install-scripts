#!/bin/bash

DOMAIN="git.richknowles.com"
USER="webmonster"
PORT_HTTP=3000
LOCAL_IP="127.0.0.1"

echo "=== DNS Check ==="
nslookup $DOMAIN || echo "⚠️  DNS lookup failed. Make sure the domain points to this server's public IP."

echo -e "\n=== Docker Check ==="
docker ps | grep gitea || echo "⚠️  Gitea container is not running."

echo -e "\n=== Gitea HTTP Check ==="
curl -I http://$LOCAL_IP:$PORT_HTTP || echo "⚠️  Gitea not responding on $LOCAL_IP:$PORT_HTTP"

echo -e "\n=== NGINX Proxy Config Check ==="
CONFIG_FILE="/home/$USER/conf/web/$DOMAIN/nginx.forcessl.conf"
if [ -f "$CONFIG_FILE" ]; then
  echo "[+] Found proxy config:"
  cat "$CONFIG_FILE"
else
  echo "⚠️  Proxy config file not found at $CONFIG_FILE"
fi

echo -e "\n=== Restarting NGINX ==="
systemctl restart nginx && echo "[+] NGINX restarted successfully."

echo -e "\n=== Let's Encrypt SSL Check ==="
LE_PATH="/home/$USER/conf/web/$DOMAIN/ssl"
if [ -f "$LE_PATH/$DOMAIN.crt" ]; then
  echo "[+] SSL cert found for $DOMAIN"
else
  echo "⚠️  SSL cert not found. Attempting to reissue..."
  export PATH=$PATH:/usr/local/hestia/bin
  v-delete-letsencrypt-domain $USER $DOMAIN
  v-add-letsencrypt-domain $USER $DOMAIN
fi

echo -e "\n=== Final Beep Check ==="
for i in {1..3}; do echo -ne '\007'; sleep 0.2; done

echo -e "\n[✓] Health check complete for $DOMAIN"

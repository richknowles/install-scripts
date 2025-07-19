#!/bin/bash

DOMAIN="git.richknowles.com"
PORT_HTTP=3000
PORT_SSH=222

# Set Hestia path
export PATH=$PATH:/usr/local/hestia/bin

echo "[+] Updating system and installing Docker"
apt purge -y containerd || true
apt update && apt install -y docker.io

echo "[+] Installing Docker Compose manually"
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose || sudo chmod +x /usr/local/bin/docker-compose

# Move to fallback location if /usr/local/bin fails
if ! docker-compose --version &> /dev/null; then
    mv /usr/local/bin/docker-compose /usr/bin/docker-compose
    chmod +x /usr/bin/docker-compose
fi

echo "[+] Adding domain to Hestia"
v-add-web-domain admin $DOMAIN

echo "[+] Creating Gitea folders"
mkdir -p /home/admin/web/$DOMAIN/docker/gitea/data
chown -R 1000:1000 /home/admin/web/$DOMAIN/docker

echo "[+] Writing Docker Compose file"
cat <<EOF > /home/admin/web/$DOMAIN/docker/docker-compose.yml
version: "3"

services:
  gitea:
    image: gitea/gitea:latest
    container_name: gitea
    environment:
      - USER_UID=1000
      - USER_GID=1000
    restart: always
    networks:
      - gitea
    volumes:
      - ./gitea/data:/data
    ports:
      - "$PORT_HTTP:3000"
      - "$PORT_SSH:22"

networks:
  gitea:
    external: false
EOF

echo "[+] Starting Gitea container"
cd /home/admin/web/$DOMAIN/docker
docker-compose up -d

echo "[+] Writing NGINX proxy config"
PROXY_CONF="/home/admin/conf/web/$DOMAIN/nginx.forcessl.conf"
mkdir -p $(dirname "$PROXY_CONF")

cat <<EOF > "$PROXY_CONF"
location / {
    proxy_pass http://127.0.0.1:$PORT_HTTP;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
}
EOF

echo "[+] Requesting Let's Encrypt SSL cert"
v-add-letsencrypt-domain admin $DOMAIN

echo "[+] Restarting NGINX"
systemctl restart nginx

echo "[+] Installing Fail2Ban"
apt install -y fail2ban

echo "[+] Adding Fail2Ban jail for Gitea SSH"
cat <<EOF > /etc/fail2ban/jail.d/gitea-ssh.conf
[gitea-ssh]
enabled = true
port = $PORT_SSH
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
EOF

echo "[+] Restarting Fail2Ban"
systemctl restart fail2ban

# Metal-style terminal celebration
for i in {1..3}; do echo -ne '\007'; sleep 0.2; done

echo -e "\n\n"
echo "        (\__/)"
echo "        (•ㅅ•)   "
echo "        / 　 づ  "
sleep 0.5
echo -e "\n\n"
echo "    (╯°□°）╯︵ ┻━┻  "
sleep 0.5
echo -e "\n\n"
echo -e "        ( ︶︿︶)_╭∩╮"
sleep 0.5
echo -e "\n\n"
echo -e "███████╗██╗   ██╗ ██████╗██╗  ██╗"
echo -e "██╔════╝██║   ██║██╔════╝██║ ██╔╝"
echo -e "███████╗██║   ██║██║     █████╔╝ "
echo -e "╚════██║██║   ██║██║     ██╔═██╗ "
echo -e "███████║╚██████╔╝╚██████╗██║  ██╗"
echo -e "╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝"
sleep 0.5
echo -e "\n\n"
echo -e "        GITEA DEPLOYED LIKE A LEGEND."
echo -e "        Access it at: https://$DOMAIN"
echo -e "        SSH Git on port $PORT_SSH"
echo -e "\n\n"
echo -e "               ╭∩╮(︶︿︶)╭∩╮  "
echo -e "                FUCK YEA."
echo ""

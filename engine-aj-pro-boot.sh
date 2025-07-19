#!/bin/bash

# SYSTEM UPDATE & BASIC HARDENING
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git ufw fail2ban tmux python3 python3-pip python3-venv unzip

# OPTIONAL: Create a new user (you can skip this if you're happy with ubuntu user)
# sudo adduser ajadmin
# sudo usermod -aG sudo ajadmin

# FIREWALL CONFIG
sudo ufw allow OpenSSH
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable

# FAIL2BAN STARTUP
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# PYTHON ENV SETUP FOR ENGINE-AJ
mkdir -p ~/engine-aj
cd ~/engine-aj
python3 -m venv venv
source venv/bin/activate

# GIT CLONE YOUR PROJECT (replace with your actual repo)
git clone https://github.com/richknowles/ENGINE-AJ.git .
pip install --upgrade pip
pip install -r requirements.txt

# OPTIONAL: Set up Gunicorn (for Flask app serving)
pip install gunicorn

# CREATE START SCRIPT
cat <<EOF > start_engine-aj.sh
#!/bin/bash
source ~/engine-aj/venv/bin/activate
exec gunicorn -b 0.0.0.0:8000 app:app
EOF

chmod +x start_engine-aj.sh

# FINAL REMINDERS
echo -e "\nDONE! To start ENGINE-AJ:"
echo "cd ~/engine-aj && ./start_engine-aj.sh"

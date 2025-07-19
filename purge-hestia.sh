#!/bin/bash

echo "🧨 Purging HestiaCP..."

# Stop Hestia service (if still running)
systemctl stop hestia >/dev/null 2>&1
systemctl disable hestia >/dev/null 2>&1

# Remove directories
rm -rf /usr/local/hestia
rm -rf /etc/hestia
rm -rf /home/admin/web
rm -rf /var/log/hestia
rm -rf /var/lib/hestia
rm -rf /var/backups/hestia

# Remove nginx confs Hestia may have modified
rm -f /etc/nginx/conf.d/hestia.conf
rm -f /etc/nginx/conf.d/*.vhost
rm -rf /etc/nginx/conf.d/hestia*
rm -rf /etc/nginx/templates

# Remove web root junk		
rm -rf /home/admin/conf
rm -rf /home/*/web
rm -rf /home/*/conf/web
rm -rf /var/www/html/index.html

# Remove cron jobs
rm -f /etc/cron.d/hestia
crontab -l | grep -v 'hestia' | crontab -

# Check and clean systemd leftovers
rm -f /etc/systemd/system/hestia.service

# Reload systemd and nginx
systemctl daemon-reexec
systemctl daemon-reload
systemctl restart nginx

echo "✅ HestiaCP purge complete. You are now clean, uncluttered, and in full control."

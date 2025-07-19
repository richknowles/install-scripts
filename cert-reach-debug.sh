#!/bin/bash
# cert-reach-debug.sh — Diagnose Let's Encrypt failures like a boss

PUBLIC_IP=$(curl -s ifconfig.me)
DOMAIN="hcp1.dev.alisium.run"

echo "🔍 Checking public IP: $PUBLIC_IP"
echo

echo "🧠 STEP 1: Is Caddy listening on ports 80 and 443?"
ss -tulnp | grep -E ':80|:443' || echo "❌ Not listening on 80/443"

echo
echo "🧱 STEP 2: Current iptables rules"
iptables -L -n -v

echo
echo "🧱 STEP 3: Current nftables rules"
nft list ruleset || echo "No nftables rules found."

echo
echo "🌐 STEP 4: DNS resolution for $DOMAIN"
dig +short $DOMAIN

echo
echo "🌐 STEP 5: Local curl test to $DOMAIN on port 80"
curl -I --connect-timeout 5 http://$DOMAIN || echo "❌ Failed curl to http://$DOMAIN"

echo
echo "🌐 STEP 6: Local curl to raw IP on port 80"
curl -I --connect-timeout 5 http://$PUBLIC_IP || echo "❌ Failed curl to http://$PUBLIC_IP"

echo
echo "💡 Summary:"
echo "If 80/443 are listening but curl fails → OCI routing or firewall"
echo "If everything looks fine here, try curl from an external VPS"

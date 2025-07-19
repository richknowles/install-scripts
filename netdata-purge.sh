#!/usr/bin/env bash
#
# netdata-purge.sh
# Completely uninstall Netdata (kickstart or package) and remove every trace.

set -eo pipefail

# ─── Ensure we’re root ───────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo "⚠️  Please run this script as root."
  exit 1
fi

# ─── Kill any stray processes ───────────────────────────────────────────────────
echo "🔍 Killing any running Netdata processes…"
killall netdata >/dev/null 2>&1 || true

# ─── Official uninstaller (if reachable) ─────────────────────────────────────────
TMPDIR="$(mktemp -d)"
UNINSTALLER_URL="https://raw.githubusercontent.com/netdata/netdata/master/packaging/installer/netdata-uninstaller.sh"

echo "🔍 Downloading official Netdata uninstaller…"
if curl -fsSL "$UNINSTALLER_URL" -o "$TMPDIR/netdata-uninstaller.sh"; then
  chmod +x "$TMPDIR/netdata-uninstaller.sh"
  echo "🗑️  Running official uninstaller (force/yes)…"
  if ! bash "$TMPDIR/netdata-uninstaller.sh" --yes --force; then
    echo "⚠️  Official uninstaller failed—continuing with manual purge."
  fi
else
  echo "⚠️  Could not fetch uninstaller—skipping to manual purge."
fi

# ─── Remove distro packages ──────────────────────────────────────────────────────
echo "📦 Purging Netdata packages…"
if command -v apt-get &>/dev/null; then
  apt-get remove --purge -y 'netdata*' || true
  apt-get autoremove -y            || true
elif command -v yum &>/dev/null; then
  yum remove -y 'netdata*'         || true
fi

# ─── Disable any systemd units ───────────────────────────────────────────────────
echo "🔧 Stopping & disabling systemd services…"
systemctl stop  netdata.service netdata.socket    2>/dev/null || true
systemctl disable netdata.service netdata.socket  2>/dev/null || true
systemctl unmask  netdata.service                 2>/dev/null || true
rm -f /etc/systemd/system/netdata.*               2>/dev/null
systemctl daemon-reload

# ─── Remove netdata user/group ──────────────────────────────────────────────────
echo "👤 Removing Netdata user & group…"
id netdata     &>/dev/null && userdel -r netdata 2>/dev/null || true
getent group netdata &>/dev/null && groupdel netdata     2>/dev/null || true

# ─── Manually scrub leftovers ───────────────────────────────────────────────────
echo "🗄️  Deleting leftover files & directories…"
declare -a paths=(
  /etc/netdata
  /var/lib/netdata
  /var/cache/netdata
  /var/log/netdata
  /usr/lib/netdata
  /usr/libexec/netdata
  /opt/netdata
  /etc/cron.d/netdata*
  /etc/init.d/netdata
  /etc/default/netdata
  /usr/sbin/netdata
  /usr/bin/netdata
  /usr/local/bin/netdata
  /etc/logrotate.d/netdata*
  /etc/rsyslog.d/21-netdata.conf
  /var/lib/dpkg/info/netdata*
  /var/lib/apt/lists/packagecloud.io_netdata*
  /usr/share/netdata
)

for p in "${paths[@]}"; do
  rm -rf $p 2>/dev/null || true
done

# ─── Cleanup ────────────────────────────────────────────────────────────────────
echo "🧹 Cleaning up temporary files…"
rm -rf "$TMPDIR"

echo "✅  Netdata has been completely purged."
exit 0

#!/usr/bin/env bash
#
# Linux server hardening cheatsheet.
# Not meant to be run end-to-end unattended — walk through it step by step, as sudo.

set -euo pipefail

# ---------------------------------------------------------------------------
# 1. Base packages: SSH server, security audit tool, brute-force jail
# ---------------------------------------------------------------------------
apt update && apt upgrade -y
apt install openssh-server lynis fail2ban -y

systemctl enable --now ssh
systemctl status ssh

# ---------------------------------------------------------------------------
# 2. Harden SSH
# ---------------------------------------------------------------------------
nano /etc/ssh/sshd_config
# - change Port to a custom, non-standard port (e.g., 7587)
# - set PasswordAuthentication no (key-based auth only)
systemctl restart ssh

# ---------------------------------------------------------------------------
# 3. Firewall (ufw)
# ---------------------------------------------------------------------------
ufw allow ssh

# Rate-limit the custom SSH port: blocks an IP after 6 connection attempts
# within 30 seconds.
ufw limit 7587/tcp
# Alternative: restrict the port to a single known IP instead of rate-limiting.
ufw allow from "$MY_IP_ADDRESS" to any port 7587 proto tcp

ufw enable
ufw status
ufw reload

# ---------------------------------------------------------------------------
# 4. Network config (wifi/wlan via netplan)
# ---------------------------------------------------------------------------
# Reference config with placeholders: ../extra/network-config.yaml
# Copy it into place (adjust interface names/addresses first), then apply.
cp ../extra/network-config.yaml /etc/netplan/01-netcfg.yaml
nano /etc/netplan/01-netcfg.yaml   # fill in real addresses/nameservers/wifi creds
netplan generate
netplan try
netplan apply

# ---------------------------------------------------------------------------
# 5. fail2ban: ban IPs after repeated failed SSH logins
# ---------------------------------------------------------------------------
cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local

# Add an [sshd] section to jail.local (not fail2ban.local) to enable the jail:
nano /etc/fail2ban/jail.local

# [sshd]
# enabled = true
#
# [DEFAULT]
# bantime  = 600   # seconds an IP stays banned
# findtime = 600   # window in which maxretry failures are counted
# maxretry = 3     # failures allowed before a ban
# backend  = auto
# usedns   = warn

systemctl restart fail2ban

# ---------------------------------------------------------------------------
# 6. Audit
# ---------------------------------------------------------------------------
# Review the findings and fix at least a few of the reported warnings/suggestions.
lynis audit system
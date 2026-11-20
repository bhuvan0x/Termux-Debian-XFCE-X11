#!/usr/bin/env bash
set -Eeuo pipefail
MODE="${1:-plan}"
case "$MODE" in plan|apply) ;; *) echo "Usage: $0 [plan|apply]" >&2; exit 2;; esac
[ "$(id -u)" -eq 0 ] || { echo "Run this script as Debian root inside PRoot." >&2; exit 1; }
echo "== Package consistency =="; apt-get check
echo "== Upgrade preview =="; apt-get update; apt-get -s full-upgrade
echo "== Autoremove preview =="; apt-get -s autoremove --purge
echo "== APT cache =="; du -sh /var/cache/apt/archives 2>/dev/null || true
[ "$MODE" = plan ] && { echo "PLAN ONLY: no package changes made. Rerun with apply after reviewing."; exit 0; }
read -r -p "Apply full-upgrade, autoremove and apt clean? Type MAINTAIN: " answer
[ "$answer" = MAINTAIN ] || { echo "Cancelled."; exit 0; }
export DEBIAN_FRONTEND=readline
apt-get full-upgrade
apt-get autoremove --purge
apt-get clean
apt-get check

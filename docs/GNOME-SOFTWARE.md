# GNOME Software migration notice

GNOME Software was replaced by KDE Discover for this Debian 13 XFCE PRoot setup.

Use:

\`\`\`bash
bash scripts/install-discover.sh
\`\`\`

The installer replaces the GNOME Software launcher and installs Discover with the Flatpak backend. The session-scoped system-D-Bus design and PRoot limitations are documented in [DISCOVER.md](DISCOVER.md).

The old installer path remains as a compatibility wrapper so existing local workflows migrate safely to Discover.

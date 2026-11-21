# Security Policy

PrimeBook / Termux Debian X11 is a desktop setup for Termux, Debian, PRoot-Distro and Termux:X11.

## Supported versions

Security fixes are generally made against the latest code on the default branch. Older commits and local forks may not receive updates.

## Reporting a vulnerability

Please **do not publish exploitable vulnerability details in a public issue**.

1. Open this repository's **Security** tab.
2. If private vulnerability reporting is enabled, use **Report a vulnerability**.
3. If that option is unavailable, contact the maintainer through GitHub [@bhuvan0x](https://github.com/bhuvan0x) and request a private channel before sharing technical details.

Include a description and impact, affected files/versions, device and Termux package versions, reproduction steps, and a suggested mitigation where possible. Do not include passwords, tokens, SSH keys, personal data, or full backups.

Please allow reasonable time for investigation and a fix before public disclosure. Do not access, modify, or expose another person's data while testing.

## Security boundaries

- PRoot is not a virtual machine or a kernel-isolated container. It shares the Android kernel and app UID.
- This project does not provide a host firewall, kernel hardening, SELinux policy, or a guarantee of isolation from Android.
- Electron compatibility launchers using `--no-sandbox` weaken Chromium's normal renderer isolation. Use only trusted applications.
- Package sources, upstream binaries, themes, plugins and optional add-ons retain their own security and licensing policies.
- A successful project audit is not a guarantee that a device or installation is secure.

For security-sensitive use, review scripts before execution, keep Android and Termux updated, and maintain backups.

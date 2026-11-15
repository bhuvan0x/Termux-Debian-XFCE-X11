# Security policy

## Supported setup

Security fixes and hardening guidance apply to the current `main` branch. The workstation runs Debian userspace under Termux PRoot on Android; it is not a conventional Linux VM or a separate kernel.

## Reporting a vulnerability

Please do not publish credentials, personal data, exploitable proof-of-concept details, or an unpatched vulnerability in a public issue. Use GitHub's private vulnerability reporting feature for this repository when it is available. Otherwise, contact the repository maintainer privately through GitHub and include:

- A concise description of the affected script or component.
- The affected commit or package version.
- Reproduction steps using a test device and non-sensitive sample data.
- The impact and any suggested mitigation.

Do not include passwords, access tokens, SSH private keys, or complete personal backups in a report.

## Security assumptions

- Android is the host security boundary; PRoot does not provide kernel-level isolation.
- Scripts must not embed passwords, API keys, SSH private keys, GitHub tokens, or other secrets.
- Changes to startup, bind mounts, sudoers, CUPS, or package sources must preserve the documented local-only service model.
- A clean script audit is not proof that an Android device or Debian rootfs is free of compromise.

# Contributing to PrimeBook

Thanks for your interest in improving Termux Debian X11 / PrimeBook. Contributions, forks, experiments and constructive feedback are welcome.

## Ways to contribute

- Report reproducible bugs and documentation mistakes.
- Improve installation, rollback, uninstall and diagnostic scripts.
- Improve XFCE integration, accessibility, performance and ARM64 compatibility.
- Add translations or improve existing translations.
- Submit tested fixes through pull requests.

## Before opening a pull request

1. Check existing Issues and Pull Requests for related work.
2. Keep changes focused and explain the problem they solve.
3. Test scripts on a disposable/test PRoot installation when possible.
4. Include the Android version, Termux source/build, Debian release and relevant package versions when reporting environment-specific behavior.
5. Document destructive actions and preserve confirmation safeguards.
6. Never commit credentials, access tokens, private keys, personal backups, or private device data.

## Shell script expectations

- Use `set -Eeuo pipefail` where appropriate.
- Quote variable expansions and validate paths before destructive operations.
- Prefer idempotent changes and explicit rollback paths.
- Do not silently weaken PRoot isolation, service binding, APT verification, or CUPS network restrictions.
- Do not claim that PRoot is a VM or kernel-isolated container.
- Keep shared Termux packages and user data outside the uninstall scope unless a change explicitly documents and confirms otherwise.

## Pull requests

Describe the change, why it is needed, how it was tested, and any known limitations. Add or update documentation when user-facing behavior changes.

## Working together

If you want to collaborate on the project or develop a larger feature together, contact the maintainer through GitHub [@bhuvan0x](https://github.com/bhuvan0x).

By contributing, you agree that your contributions are submitted under the repository's [MIT License](LICENSE), unless you clearly state otherwise and the maintainer agrees.

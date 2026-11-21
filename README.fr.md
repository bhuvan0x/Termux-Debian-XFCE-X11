# Termux Debian X11 — PrimeBook

[English](README.md) · **Français**

> Lancez un bureau Debian + XFCE dans Termux sur Android, sans accès root.

![Logo PrimeBook](primebook-logo.svg)

## Fonctionnalités
- Debian avec Termux, Termux:X11 et PRoot-Distro.
- Bureau XFCE et applications Linux utiles.
- Accès limité au dossier Downloads d’Android.
- KDE Discover, thème WhiteSur et prise en charge facultative des imprimantes.
- Commandes de démarrage/arrêt, contrôles de sécurité et scripts de maintenance.

## Installation
Installez Termux, Termux:X11, Termux:API et, facultativement, Termux:Widget depuis des sources compatibles. Dans Termux :

```bash
pkg update && pkg upgrade -y
pkg install -y git
git clone https://github.com/bhuvan0x/Termux-Debian-X11.git
cd Termux-Debian-X11
bash scripts/setup-termux.sh
bash scripts/install-debian.sh
bash scripts/harden-debian.sh
bash scripts/security-audit.sh
```

Ouvrez Termux:X11 puis lancez `start-all`.

## Désinstallation
**Attention :** cette commande supprime la distribution Debian PRoot et tous les fichiers qu’elle contient.

```bash
uninstall-primebook
```

Pour supprimer également le dépôt cloné : `bash scripts/uninstall.sh --remove-repo`

## Sécurité et limites
PRoot n’est ni une machine virtuelle complète ni un conteneur isolé au niveau du noyau. Consultez [SECURITY.md](SECURITY.md) et la [licence](LICENSE).

## Contributions et collaboration
N’hésitez pas à utiliser, forker, améliorer et modifier ce projet. Contribuez via les Issues et Pull Requests. Vous souhaitez travailler avec moi ? Contactez-moi sur GitHub : [@bhuvan0x](https://github.com/bhuvan0x).

[Guide d’installation](docs/INSTALLATION.md) · [Dépannage](docs/TROUBLESHOOTING.md) · [README anglais](README.md)

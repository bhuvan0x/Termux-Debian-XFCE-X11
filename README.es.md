# Termux Debian X11 — PrimeBook

[English](README.md) · **Español**

> Ejecuta un escritorio Debian + XFCE dentro de Termux en Android, sin acceso root.

![Logotipo de PrimeBook](primebook-logo.svg)

## Características
- Debian mediante Termux, Termux:X11 y PRoot-Distro.
- Escritorio XFCE y aplicaciones Linux útiles.
- Acceso limitado a la carpeta Downloads de Android.
- KDE Discover, tema WhiteSur y soporte opcional para impresoras.
- Comandos de inicio y parada, comprobaciones de seguridad y mantenimiento.

## Instalación
Instala Termux, Termux:X11, Termux:API y, opcionalmente, Termux:Widget desde fuentes compatibles. Después, en Termux:

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

Abre Termux:X11 y ejecuta `start-all`.

## Desinstalación
**Advertencia:** elimina la distribución Debian PRoot y todos los archivos que contiene.

```bash
uninstall-primebook
```

Para eliminar también el repositorio clonado: `bash scripts/uninstall.sh --remove-repo`

## Seguridad y límites
PRoot no es una máquina virtual completa ni un contenedor aislado a nivel del kernel. Consulta [SECURITY.md](SECURITY.md) y la [licencia](LICENSE).

## Contribuir y colaborar
Siéntete libre de usar, bifurcar, mejorar y modificar este proyecto. Contribuye mediante Issues y Pull Requests. ¿Te gustaría colaborar conmigo? Contáctame en GitHub: [@bhuvan0x](https://github.com/bhuvan0x).

[Guía de instalación](docs/INSTALLATION.md) · [Solución de problemas](docs/TROUBLESHOOTING.md) · [README en inglés](README.md)

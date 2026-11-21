# Termux Debian X11 — PrimeBook

[English](README.md) · **日本語**

> Android 上の Termux で、root 権限なしに Debian + XFCE デスクトップを動かします。

![PrimeBook logo](primebook-logo.svg)

## 主な機能
- Termux、Termux:X11、PRoot-Distro 上の Debian。
- XFCE デスクトップと実用的な Linux アプリ。
- Android の Downloads フォルダーへの限定アクセス。
- KDE Discover、WhiteSur テーマ、オプションのプリンター対応。
- 起動・停止コマンド、セキュリティ確認、保守スクリプト。

## インストール
互換性のある配布元から Termux、Termux:X11、Termux:API（任意で Termux:Widget）をインストールし、Termux で実行します。

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

Termux:X11 アプリを開いてから `start-all` を実行します。

## アンインストール
**注意:** Debian PRoot 環境と、その中のすべてのファイルが削除されます。

```bash
uninstall-primebook
```

リポジトリも削除する場合: `bash scripts/uninstall.sh --remove-repo`

## セキュリティと制限
PRoot は完全な VM やカーネル分離コンテナではありません。詳細は [SECURITY.md](SECURITY.md)、ライセンスは [LICENSE](LICENSE) を参照してください。

## 貢献・協力
自由に利用、fork、改善、改変してください。Issue や Pull Request で貢献できます。一緒に開発したい場合は GitHub の [@bhuvan0x](https://github.com/bhuvan0x) までご連絡ください。

[インストールガイド](docs/INSTALLATION.md) · [トラブルシューティング](docs/TROUBLESHOOTING.md) · [English README](README.md)

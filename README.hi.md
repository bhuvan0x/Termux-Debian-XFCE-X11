# Termux Debian X11 — PrimeBook

[English](README.md) · **हिन्दी**

> Android पर Termux के अंदर Debian + XFCE Linux डेस्कटॉप चलाएँ — बिना root access के।

![PrimeBook logo](primebook-logo.svg)

## विशेषताएँ
- Termux, Termux:X11 और PRoot-Distro के साथ Debian।
- XFCE डेस्कटॉप और उपयोगी Linux ऐप्स।
- Android Downloads फ़ोल्डर तक सीमित पहुँच।
- KDE Discover, WhiteSur थीम और वैकल्पिक प्रिंटर सपोर्ट।
- Start/Stop कमांड, सुरक्षा जाँच और रखरखाव स्क्रिप्ट।

## इंस्टॉलेशन
Termux, Termux:X11, Termux:API और वैकल्पिक Termux:Widget को संगत स्रोत से इंस्टॉल करें। फिर Termux में:

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

Termux:X11 ऐप खोलें और चलाएँ: `start-all`

## हटाना
**चेतावनी:** यह Debian PRoot वातावरण और उसमें मौजूद सभी फ़ाइलें मिटा देता है।

```bash
uninstall-primebook
```

रिपॉज़िटरी भी हटाने के लिए: `bash scripts/uninstall.sh --remove-repo`

## सुरक्षा और सीमाएँ
PRoot पूर्ण VM या kernel-isolated container नहीं है। सुरक्षा विवरण के लिए [SECURITY.md](SECURITY.md) और लाइसेंस के लिए [LICENSE](LICENSE) पढ़ें।

## योगदान और सहयोग
इस प्रोजेक्ट को उपयोग करने, fork करने, सुधारने और अपने हिसाब से बदलने के लिए आपका स्वागत है। Issues और Pull Requests के माध्यम से योगदान दें। साथ मिलकर काम करना चाहते हैं? GitHub पर [@bhuvan0x](https://github.com/bhuvan0x) से संपर्क करें।

[स्थापना गाइड](docs/INSTALLATION.md) · [समस्या निवारण](docs/TROUBLESHOOTING.md) · [मुख्य README](README.md)

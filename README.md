# HAVEN — Private Chat That Lives On Your Machine

> **Your server. Your rules. No cloud. No accounts with Big Tech. No one reading your messages.**

![Version](https://img.shields.io/badge/version-2.2.3-blue)
![License](https://img.shields.io/badge/license-MIT--NC-green)
![Node](https://img.shields.io/badge/node-%3E%3D18-brightgreen)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey)

Haven is a self-hosted Discord alternative. Run it on your machine. Invite friends with a link. No cloud. No email signup. No tracking. Free forever.

<img width="1917" height="911" alt="Screenshot 2026-02-16 013038" src="https://github.com/user-attachments/assets/79b62980-0822-4e9d-b346-c5a93de95862" />

---

## Quick Start — Docker (Recommended)

**Pre-built image:**
```bash
docker pull ghcr.io/ancsemi/haven:latest
docker run -d -p 3000:3000 -v haven_data:/data ghcr.io/ancsemi/haven:latest
```

**Build from source:**
```bash
git clone https://github.com/ancsemi/Haven.git
cd Haven
docker compose up -d
```

Open `https://localhost:3000` (or your custom port), register an account join a server via link and enjoy!

> Certificate warning is normal — click **Advanced → Proceed**. Haven uses a self-signed cert for encryption.

**Invite Links:** Every server gets an auto-generated invite code. Share the invite link (shown in Admin → Server Settings) or set the `DOMAIN` variable in `.env` for pretty URLs like `https://yourdomain.com/invite/abc12345`.

---

## Quick Start — Windows

1. Download and unzip this repository
2. Double-click **`Start Haven.bat`**
3. If Node.js isn't installed, the launcher will offer to install it automatically

The batch file handles Node.js detection, dependency installation, SSL certificate generation, and opens your browser.

---

## Quick Start — Linux / macOS

```bash
chmod +x start.sh
./start.sh
```

Or manually: `npm install && node server.js`

---

## Documentation

For detailed setup instructions, configuration reference, feature documentation, administration guide, and troubleshooting steps, see the **[Complete User Guide](GUIDE.md)**.

The guide covers everything: port forwarding, Cloudflare tunnels, HTTPS/SSL setup, TURN server configuration for voice chat, the role and permission system, Discord import, end-to-end encryption details, keyboard shortcuts, backup procedures, and more.

---

<img width="1919" height="908" alt="Screenshot 2026-02-16 013319" src="https://github.com/user-attachments/assets/f061491e-d998-4160-9971-b846cea83cd4" />

<img width="1918" height="945" alt="Screenshot 2026-02-13 174344" src="https://github.com/user-attachments/assets/a1925091-46de-4fa6-bb8d-788985c974be" />

---

## License

MIT-NC — free to use, modify, and share. **Not for resale.** See [LICENSE](LICENSE).

Original project: [github.com/ancsemi/Haven](https://github.com/ancsemi/Haven)

---

<p align="center">
  <b>Haven</b> — Because your conversations are yours.
</p>

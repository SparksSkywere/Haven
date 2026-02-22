# Haven — Complete User Guide

Welcome to Haven, your private self-hosted chat server. This guide is written for anyone, from first-time server operators to experienced system administrators. It walks through every step of setting up, configuring, and running Haven, and documents every feature the software offers. If something is not covered here, it probably does not exist yet.

Haven is a self-hosted alternative to Discord. You run it on your own hardware, you control who can join, and nobody else can read your messages. There is no cloud service, no email signup, no tracking, and no subscription fee. You download the code, start the server, and invite your friends with a short code.

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation on Windows](#installation-on-windows)
3. [Installation on Linux and macOS](#installation-on-linux-and-macos)
4. [Installation with Docker](#installation-with-docker)
5. [First Launch and the Setup Wizard](#first-launch-and-the-setup-wizard)
6. [The Data Directory](#the-data-directory)
7. [Configuration Reference](#configuration-reference)
8. [Channels and Sub-Channels](#channels-and-sub-channels)
9. [Inviting Friends on the Same Network](#inviting-friends-on-the-same-network)
10. [Inviting Friends Over the Internet](#inviting-friends-over-the-internet)
11. [Cloudflare Tunnel — No Port Forwarding Needed](#cloudflare-tunnel--no-port-forwarding-needed)
12. [HTTPS and SSL Certificates](#https-and-ssl-certificates)
13. [User Accounts and Profiles](#user-accounts-and-profiles)
14. [Messaging](#messaging)
15. [Slash Commands](#slash-commands)
16. [Reactions and Pins](#reactions-and-pins)
17. [Direct Messages and End-to-End Encryption](#direct-messages-and-end-to-end-encryption)
18. [Voice Chat](#voice-chat)
19. [Screen Sharing](#screen-sharing)
20. [Music Sharing](#music-sharing)
21. [Themes and Visual Effects](#themes-and-visual-effects)
22. [Notification Sounds](#notification-sounds)
23. [Push Notifications](#push-notifications)
24. [GIF Search with GIPHY](#gif-search-with-giphy)
25. [Custom Emojis](#custom-emojis)
26. [Custom Notification Sounds](#custom-notification-sounds)
27. [Importing from Discord](#importing-from-discord)
28. [Webhooks and Bot Integrations](#webhooks-and-bot-integrations)
29. [Games](#games)
30. [Administration Guide](#administration-guide)
31. [The Role and Permission System](#the-role-and-permission-system)
32. [Server Invite System](#server-invite-system)
33. [Whitelist — Restricting Registration](#whitelist--restricting-registration)
34. [Auto-Cleanup](#auto-cleanup)
35. [Keyboard Shortcuts](#keyboard-shortcuts)
36. [Backing Up Your Data](#backing-up-your-data)
37. [Updating Haven](#updating-haven)
38. [Troubleshooting](#troubleshooting)
39. [Router-Specific Notes](#router-specific-notes)

---

## System Requirements

Haven is designed to run on virtually any modern computer. The server itself is lightweight and can handle dozens of concurrent users on modest hardware.

You need one of the following operating systems: Windows 10 or later, macOS 10.15 (Catalina) or later, or any modern Linux distribution. Haven requires Node.js version 18 or newer. If you prefer not to install Node.js, you can run Haven inside a Docker container instead, which bundles everything for you.

Disk space requirements are minimal. The application itself is under 50 megabytes. The database and uploaded files will grow over time depending on how actively your community uses the server, but a fresh installation uses almost no space at all.

Haven works best in a modern web browser. Chrome, Edge, Firefox, and Safari 16 or later are all supported. Voice chat and push notifications require a secure HTTPS connection, which Haven generates automatically if OpenSSL is available on your system.

---

## Installation on Windows

The simplest way to run Haven on Windows is by using the included batch launcher. Download or clone the Haven repository to any folder on your computer, then double-click the file called **Start Haven.bat** inside that folder.

The batch file performs every step of the setup process automatically. It begins by checking whether Node.js is installed on your system. If Node.js is not found, the launcher will display a prompt asking whether you would like to install it automatically. If you type Y and press Enter, it downloads and runs the official Node.js installer for you. After Node.js is installed, you will need to close the terminal window and double-click Start Haven.bat again so that the new terminal session recognises the Node.js installation.

If Node.js is already installed, the launcher moves on to installing the required packages using npm. This step only takes significant time on the first launch. On subsequent starts, npm verifies that everything is already in place and finishes in a few seconds.

Next, the launcher checks whether SSL certificates exist in your data directory. If they do not, and if OpenSSL is available on your system, Haven generates a self-signed SSL certificate so that the server can run over HTTPS. This is important because voice chat and push notifications require a secure connection. If OpenSSL is not installed, Haven starts in plain HTTP mode instead. Everything still works for local use, but voice chat will only function on localhost.

Finally, the launcher starts the server and opens your default web browser to the Haven login page. The terminal window must remain open for the server to keep running. Closing it shuts down the server.

If you prefer to start the server manually without the batch file, open a terminal in the Haven folder and run:

```
npm install
node server.js
```

---

## Installation on Linux and macOS

Haven includes a shell script called **start.sh** that provides the same automated experience as the Windows batch launcher. Make the script executable and run it:

```bash
chmod +x start.sh
./start.sh
```

The script checks for Node.js, installs dependencies if needed, generates SSL certificates if OpenSSL is available, kills any previously running Haven process on your configured port, and starts the server. It also creates your data directory at **~/.haven** if it does not already exist.

For manual startup, the process is the same as Windows:

```bash
npm install
node server.js
```

The server binds to the port configured in your `.env` file (default 3000). On most Linux distributions, ports below 1024 require root privileges, but high-numbered ports like 3000 do not, so you can run Haven as a normal user.

---

## Installation with Docker

Docker is the recommended approach if you want a clean, isolated installation that does not require Node.js on your host system. Haven provides both a pre-built container image and a Dockerfile for building from source.

**Using the pre-built image:**

```bash
docker pull ghcr.io/ancsemi/haven:latest
docker run -d -p 3000:3000 -v haven_data:/data ghcr.io/ancsemi/haven:latest
# Change both 3000s to match your PORT in .env if you use a custom port
```

**Building from source:**

```bash
git clone https://github.com/ancsemi/Haven.git
cd Haven
docker compose up -d
```

When the container starts for the first time, it automatically generates self-signed SSL certificates inside the data volume, creates the database, and starts the server. The container runs as a non-root user for security and is configured to restart automatically if it crashes.

All persistent data — the database, configuration file, SSL certificates, and uploaded files — is stored in a Docker volume called **haven_data**. This means you can rebuild or replace the container without losing any data.

If you prefer to store data in a specific folder on your host filesystem rather than a Docker volume, edit the **docker-compose.yml** file and change the volume mapping:

```yaml
volumes:
  - /path/to/your/haven-data:/data
```

This is especially useful on NAS devices like Synology where you want the data in a known, browsable location.

To customise the container, edit **docker-compose.yml** and uncomment the environment variables you want to change. You can set the port, server name, admin username, GIPHY API key, TURN server details, and more. The file includes comments explaining each option.

To update a Docker installation:

```bash
git pull
docker compose build --no-cache
docker compose up -d
```

Your data is safe because it lives in the volume, not inside the container image.

---

## First Launch and the Setup Wizard

When you open Haven in your browser for the first time, you will see a login page. Click **Register** and create an account. The **first account registered** on the server automatically becomes the server owner with full administrative privileges. You can choose any username you like.

After logging in for the first time as the owner, Haven displays a setup wizard that walks you through the essential configuration steps. The wizard includes naming your server, creating your first channel, checking whether your server is accessible from the internet, and sharing your server's invite link. You can skip any step and return to it later from the Settings panel.

All other users join your server using the **invite link**. Share the link shown in Server Settings (or the setup wizard's final step) with friends. When they open the link, they are taken to the registration page. After registering, they are automatically added to all public channels — exactly like joining a Discord server.

If you set the **DOMAIN** variable in your `.env` file, invite links will use your custom domain (e.g. `https://haven.example.com/invite/abc12345`). Otherwise, links use the server's IP and port.

---

## The Data Directory

Haven stores all user data — the database, uploaded files, configuration, and SSL certificates — in a dedicated directory that is separate from the application code. This design ensures that you can update, reinstall, or move the Haven application without affecting your data.

The default data directory locations are:

| Operating System | Location |
|:---|:---|
| All (Portable) | `./data/` (relative to the Haven application directory) |
| Docker | `/data` inside the container (mapped to a volume or host folder) |

You can override this location by setting the **HAVEN_DATA_DIR** environment variable in your `.env` file or your system environment before starting the server.

Inside the data directory you will find:

**haven.db** is the SQLite database that contains all messages, user accounts, channel definitions, reactions, pins, roles, bans, and every other piece of server state.

**`.env`** is the configuration file. It is created automatically from a template on first launch and contains settings like the port number, server name, JWT secret, and optional features like TURN server credentials.

**certs/** contains the auto-generated SSL certificate and private key. These are regenerated if you delete them and restart the server.

**uploads/** contains every file that users have uploaded through the chat, including avatars, images, documents, and custom emojis and sounds.

If Haven detects data files in the old location (inside the application folder itself, which was used in earlier versions), it automatically migrates them to the new external data directory on startup.

---

## Configuration Reference

All server settings are stored in the `.env` file inside your data directory. The file is plain text and follows the standard `KEY=VALUE` format. After making changes, you must restart the server for them to take effect.

The following settings are available:

**PORT** controls which network port the server listens on. The default is 3000. If another application on your computer is already using that port, change this to any available port number. All the launchers, firewall rules, and documentation examples assume you are using this value.

**HOST** determines which network interface the server binds to. The default value of 0.0.0.0 means it listens on all interfaces, which is what you want for accepting connections from other devices. If you set this to 127.0.0.1, only connections from the same machine will be accepted.

**SERVER_NAME** is the display name shown in the Haven interface, particularly in the sidebar and multi-server views. It defaults to "Haven" but you should change it to something that identifies your server.

**JWT_SECRET** is the cryptographic key used to sign authentication tokens. Haven generates a strong random secret automatically on first launch. You should not need to change this, but if you do, be aware that all existing login sessions will be invalidated.

**SSL_CERT_PATH** and **SSL_KEY_PATH** allow you to specify custom SSL certificate and private key files. Paths are relative to the data directory. If these are not set, Haven looks for cert.pem and key.pem in the certs subdirectory of the data directory.

**FORCE_HTTP** can be set to true if you are running Haven behind a reverse proxy like Caddy or nginx that handles SSL termination. When this is set, Haven will not attempt to use HTTPS even if certificates are present, and the HSTS header is disabled.

**DOMAIN** is an optional setting for servers accessible via a custom domain name. When set, invite URLs use `https://DOMAIN/invite/CODE` instead of `http://HOST:PORT/invite/CODE`. This makes invite links shorter and more professional, similar to Discord's `discord.gg` links. Example: `DOMAIN=haven.example.com`.

**HAVEN_DATA_DIR** overrides the default data directory location. Set this to an absolute path if you want your data stored somewhere specific.

**TURN_URL**, **TURN_SECRET**, **TURN_USERNAME**, and **TURN_PASSWORD** configure a TURN relay server for voice chat. Without a TURN server, voice chat only works between users on the same local network or behind simple NATs. See the Voice Chat section for detailed setup instructions.

**GIPHY_API_KEY** enables the built-in GIF search feature. See the GIF Search section for how to obtain a free API key.

**VAPID_EMAIL** sets the contact email used for web push notification registration. This defaults to admin@haven.local and can be changed to your own email address.

**VAPID_PUBLIC_KEY** and **VAPID_PRIVATE_KEY** are the cryptographic keys for web push notifications. Haven generates these automatically on first launch. Do not change them unless you understand the implications — changing them invalidates all existing push subscriptions.

---

## Channels and Sub-Channels

All conversations in Haven take place inside channels. A channel is analogous to a room or a group chat. Each channel has a unique eight-character code that serves as its invitation key.

**Public channels** (the default) are automatically visible to all server members. When someone joins the server via invite link, they get access to all public channels. When a new public channel is created, all current server members are automatically added as members. This mirrors Discord's behaviour where everyone in a server can see all public channels.

**Private channels** require users to enter the channel's unique code to gain access. They are invisible in the sidebar to non-members.

Any user with the create_channel permission can create channels. By default, all users have this permission. To create a channel, use the channel creation area in the sidebar, give the channel a name, and Haven will generate its unique code automatically. The channel creator has full management rights over their channel, including the ability to delete it.

Channels also support an optional topic, which is a short description displayed in the channel header. Any user with the **set_channel_topic** permission can change the topic.

### Sub-Channels

Sub-channels allow you to organise discussions beneath a parent channel. Right-click or use the menu on any channel to create a sub-channel. Sub-channels appear indented under their parent in the sidebar. They have their own separate message history and their own unique invite code. Haven supports one level of nesting — you cannot create a sub-channel beneath another sub-channel.

When you create a sub-channel, all current members of the parent channel are automatically added to it. When someone new joins the parent channel later, they are also automatically added to all non-private sub-channels belonging to that parent.

### Private Sub-Channels

Private sub-channels work differently from regular sub-channels. When creating a sub-channel, you can check the Private option. Private sub-channels only add the creator as a member. They are invisible to other users in the sidebar and can only be joined by entering the sub-channel's code directly. Use private sub-channels for admin-only discussions, sensitive topics, or breakout groups within a larger channel.

### Channel Code Settings

Each channel's invite code can be configured by the admin with additional security options. The code visibility can be set to Public, where all members can see the code, or Private, where only admins see the real code and everyone else sees a masked placeholder.

The code mode can be set to Static, where the code never changes, or Dynamic, where the code rotates automatically. In Dynamic mode, you choose a rotation trigger: time-based rotation changes the code at a set interval of minutes, while join-based rotation changes the code after a specified number of new members have joined. You can also rotate the code manually at any time.

Dynamic codes are useful for communities where you want to limit how long a shared invite link remains valid. After rotation, old codes stop working.

### Categories and Ordering

The admin can assign a category label to any channel, which visually groups channels in the sidebar under a shared heading. Channels can be manually reordered by dragging them or using move-up and move-down controls. Sub-channels within a parent can be sorted alphabetically, by creation date, or in manual order.

---

## Inviting Friends on the Same Network

If you and your friends are on the same WiFi network or local area network, connecting is straightforward. Start your Haven server and note the address shown in the terminal window. It will look something like `https://192.168.1.50:PORT` where the IP address is your computer's local network address and PORT is the value from your `.env` file (default 3000).

Share this address with your friends. They open it in their web browser, register an account, and then enter the channel code you give them. The channel code is the eight-character string shown next to the channel name in the sidebar header. Copy it and send it to your friends through any convenient means — a text message, another chat app, or by simply reading it aloud.

If your friends see a certificate warning in their browser, this is expected behaviour. Haven uses a self-signed SSL certificate, which browsers flag because it was not issued by a well-known certificate authority. The connection is still fully encrypted. Tell them to click **Advanced** and then **Proceed to site** (the exact wording varies by browser).

---

## Inviting Friends Over the Internet

If your friends are not on your local network, you need to make your server reachable from the internet. There are two approaches: traditional port forwarding on your router, or using a Cloudflare tunnel which requires no router configuration at all.

### Finding Your Public IP Address

Visit [whatismyip.com](https://whatismyip.com) to find your public IP address. This is the address your friends will use to connect to your server from the internet. It will be a series of numbers like 203.0.113.50.

### Finding Your Local IP Address

You also need to know your computer's local IP address for the port forwarding configuration. On Windows, open Command Prompt and type `ipconfig`. Look for the IPv4 Address listed under your active Ethernet or WiFi adapter — it will be something like 192.168.1.50 or 10.0.0.60. On Linux and macOS, use `ip addr` or `ifconfig` instead.

### Configuring Port Forwarding on Your Router

Port forwarding tells your router to send incoming traffic on a specific port to your computer. Every router interface is different, but the general process is the same.

Log into your router's administration panel. This is usually accessible at http://192.168.1.1 or http://10.0.0.1 in your browser. The default login credentials are often printed on a label on the bottom or back of the router. Consult your router's documentation if you are unsure.

Find the Port Forwarding section in your router settings. Depending on your router brand, it may be called NAT, Virtual Servers, Applications, Port Mapping, or something similar. Create a new forwarding rule with the following settings: set the external port to your Haven port (the PORT value from your `.env`, default 3000), the internal port to the same value, the protocol to TCP, and the destination IP to your computer's local IP address. Save the rule and apply the changes.

### Configuring the Windows Firewall

On Windows, the server also needs permission to accept incoming connections through the firewall. The simplest method is to open PowerShell as Administrator and run the following command:

```powershell
New-NetFirewallRule -DisplayName "Haven Chat" -Direction Inbound -LocalPort YOUR_PORT -Protocol TCP -Action Allow
```

Replace `YOUR_PORT` with the port number from your `.env` file (default 3000).

Alternatively, you can configure this through the graphical interface. Open the Start Menu, search for "Windows Defender Firewall", and click on it. Select "Advanced settings" on the left side, then click "Inbound Rules" in the left panel, followed by "New Rule" on the right. Select Port as the rule type, choose TCP, enter your Haven port as the specific local port, select "Allow the connection", apply the rule to all profiles (Domain, Private, and Public), and give it a recognisable name such as "Haven Chat".

### Sharing the Connection Address

Send your friends the URL with your public IP address:

```
https://YOUR_PUBLIC_IP:YOUR_PORT
```

Replace `YOUR_PORT` with your configured port (default 3000).

If this all works out you will see the following page from another computer outside of your internal network

<img width="1917" height="948" alt="Screenshot 2026-02-14 102013" src="https://github.com/user-attachments/assets/0c85ca6c-f811-43db-a26b-9b66c418830e" />

Remind them that they will see a certificate warning because Haven uses a self-signed SSL certificate. They should click Advanced and then Proceed to site. The connection is fully encrypted despite the warning.

If your internet service provider assigns you a dynamic IP address, which is common with residential connections, your public IP may change periodically. You can use a free dynamic DNS service to get a stable hostname that always points to your current IP address.

---

## Cloudflare Tunnel — No Port Forwarding Needed

If you do not want to configure port forwarding or expose your home IP address to visitors, a Cloudflare tunnel is an excellent alternative. Cloudflare acts as an intermediary, giving your server a public URL while keeping your actual IP address hidden. No router configuration and no firewall rules are required.

### Installing Cloudflared

The Cloudflare tunnel client needs to be installed on the same machine that runs Haven.

On Windows, install it using winget:

```powershell
winget install cloudflare.cloudflared
```

On macOS, install it through Homebrew:

```bash
brew install cloudflared
```

On Linux, download the binary directly:

```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared
```

After installation, verify that cloudflared is accessible by running `cloudflared --version` in your terminal. If the command is not recognised, you may need to close and reopen your terminal window so that the system PATH is refreshed.

### Enabling the Tunnel in Haven

Start Haven normally using the batch launcher or manually with `node server.js`. Log in as the admin account and open the Settings panel. Scroll down to the Tunnel section. Select **Cloudflare** as the tunnel provider and flip the toggle to enable it. Haven launches cloudflared as a background process, establishes an encrypted tunnel to Cloudflare's edge network, and displays a public URL once the tunnel is ready. The URL looks something like `https://abc-def-123.trycloudflare.com`.

Copy this URL and share it with your friends. They can open it in any web browser with no additional setup required. There is no certificate warning because Cloudflare provides a valid, publicly trusted SSL certificate for the tunnel URL.

### How the Tunnel Works

Haven runs cloudflared as a child process that creates an encrypted connection from your machine to Cloudflare's global network. Cloudflare assigns a random public URL and proxies all incoming visitor traffic through this tunnel to your local Haven server. Since the tunnel itself is encrypted, and Haven runs HTTPS locally, the entire chain from visitor to server is secured.

Your home IP address is never exposed to visitors. They only see Cloudflare's IP addresses when they connect.

### Permanent URLs with Named Tunnels

The random URL assigned by Cloudflare changes every time you restart the tunnel. If you want a stable, permanent URL, you can register a free Cloudflare account, set up a named tunnel, and point your own domain name at it. See the Cloudflare documentation at https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/ for detailed instructions on named tunnels.

### Localtunnel as an Alternative

Haven also supports **localtunnel** as a tunnel provider. Localtunnel is an npm package bundled with Haven that requires no additional installation. However, it is generally less reliable than Cloudflare for sustained use and is better suited for quick, temporary sharing sessions.

---

## HTTPS and SSL Certificates

Haven automatically generates a self-signed SSL certificate on first launch, provided that OpenSSL is installed on your system. The certificate is stored in the certs subdirectory of your data directory and is valid for ten years.

Self-signed certificates encrypt traffic just as effectively as certificates from a certificate authority, but browsers display a warning because the certificate was not issued by a trusted third party. This warning is cosmetic — the encryption is real. Your users simply need to click through the warning once.

You can tell whether Haven is running in HTTPS or HTTP mode by looking at the startup banner printed in the terminal. If the URL begins with `https://`, you are in HTTPS mode. If it begins with `http://`, you are in HTTP mode.

If Haven falls back to HTTP mode, it means that SSL certificate generation failed, usually because OpenSSL is not installed. For local-only use, HTTP mode works perfectly well. However, voice chat will only function on localhost in HTTP mode because browsers require a secure context for WebRTC microphone access, and push notifications will not work over plain HTTP either.

To install OpenSSL on Windows, download it from [slproweb.com/products/Win32OpenSSL.html](https://slproweb.com/products/Win32OpenSSL.html). Choose the "Light" version. During installation, select the option labelled "Copy OpenSSL DLLs to the Windows system directory." After installation, restart your computer so that OpenSSL is added to the system PATH. Then delete the certs folder inside your data directory (`./data/certs`) and restart Haven. The server will regenerate the certificates and start in HTTPS mode.

On Linux, OpenSSL is almost always pre-installed. On macOS, it is available through Xcode Command Line Tools or through Homebrew with `brew install openssl`.

If you have your own SSL certificates from a certificate authority such as Let's Encrypt, you can configure Haven to use them by setting **SSL_CERT_PATH** and **SSL_KEY_PATH** in your `.env` file. The paths should be relative to your data directory.

When Haven runs in HTTPS mode, it also starts a secondary HTTP server on the next port number (your configured PORT plus one). This secondary server exists solely to redirect HTTP requests to HTTPS, ensuring that users who accidentally type http:// in their browser are automatically sent to the secure version.

If you are running Haven behind a reverse proxy such as Caddy, nginx, or Traefik that handles SSL termination, set **FORCE_HTTP=true** in your `.env` file. This tells Haven to run in plain HTTP mode without attempting to load certificates, and disables the HSTS header that would otherwise force browsers to use HTTPS directly.

---

## User Accounts and Profiles

Every user on Haven has a profile that they can customise. Clicking the Settings button in the sidebar opens the profile and settings panel.

**Display name** is the name shown next to your messages and in the member list. You can change your display name at any time to anything between two and twenty characters. The display name can contain letters, numbers, underscores, and spaces. You can also change your display name using the `/nick` slash command directly from the chat input.

**Avatar** is your profile picture. Click Upload in the Avatar section to select an image file. Haven accepts JPEG, PNG, GIF, and WebP images up to 2 megabytes in size. Uploaded images are validated at the byte level to ensure they are genuine images and not disguised files. After uploading, you can choose a frame shape for your avatar. The available shapes are circle, rounded square, squircle, hexagon, and diamond. Your chosen shape is visible to everyone and is displayed around your avatar in messages and the member list. To remove your avatar, click Clear, which reverts to a default letter-initial avatar.

**Status** controls how you appear to other users. The available statuses are Online, Away, Do Not Disturb, and Invisible. When you set your status to Invisible, you appear as offline to everyone else, but you can still read and send messages normally. You can also set a custom status text that appears next to your name and status indicator.

**Bio** is a short text description that appears on your user profile card when other users click on your name. It can be up to 190 characters long.

**Password** can be changed at any time from the Settings panel by entering your current password and choosing a new one. Passwords must be between 8 and 128 characters. After changing your password, your current session remains active — you receive a fresh authentication token automatically.

---

## Messaging

The core of Haven is real-time text messaging. Type a message in the input box at the bottom of the screen and press Enter to send it. Messages appear instantly for all connected users in the channel. Messages can be up to 2000 characters long.

**Replies** let you reference a specific earlier message. Click or tap the reply icon on any message, and your next message will be sent with a visible reference to the original, displayed as a clickable quote above your text. This helps maintain conversation context in busy channels.

**Editing** is available for your own messages. Hover over or tap your message to reveal the edit button. Edited messages display an "(edited)" indicator so that other users know the content was modified after it was originally sent.

**Deleting** your own messages is available through the message action buttons, provided your role includes the delete_own_messages permission. Users with moderation permissions can also delete other users' messages, subject to role hierarchy — you can only delete messages from users whose role level is lower than your own.

**Spoiler text** can be sent by wrapping content in double vertical bars `||like this||` or by using the `/spoiler` slash command. Spoiler text is hidden behind a click-to-reveal overlay.

**Message search** is accessible by pressing Ctrl+F or clicking the search icon. The search matches against message content within the current channel and returns up to 25 results.

**Text-to-speech** messages can be sent using the `/tts` slash command. When a TTS message arrives, it is read aloud by the browser's built-in speech synthesis engine for everyone viewing the channel.

**Link previews** are automatically generated when a message contains a URL. Haven fetches the Open Graph metadata from the linked page and displays a compact preview card with the page title, description, and thumbnail image. Link previews are cached for thirty minutes to reduce repeated outbound requests. The preview system includes server-side request forgery (SSRF) protection so it will not fetch URLs that point to private or internal network addresses.

**Typing indicators** appear below the message list when another user in the channel is composing a message, giving you a visual cue that a response is being written.

**Slow mode** can be enabled by the admin on a per-channel basis. When active, each user must wait a specified number of seconds between messages. Users with moderator roles are exempt from slow mode restrictions.

**File uploads** are supported directly in the message input. You can attach images, documents, and other files to your messages. Images are displayed inline with the message, while other file types are presented as downloadable attachments. The maximum upload size is configurable by the admin (default 25 megabytes, with a hard cap of 2 gigabytes). Image uploads are validated at the byte level to confirm they match their claimed file type. Non-image files are served with forced-download headers so that potentially dangerous file types like HTML or SVG cannot execute in the browser.

---

## Slash Commands

Haven supports a set of slash commands that you type directly into the message input. Type a forward slash at the beginning of a message to see the autocomplete suggestions, or type the full command and press Enter to execute it.

**/shrug** appends the shrug emoticon ¯\\\_(ツ)\_/¯ to your message. You can include text before the emoticon by typing `/shrug your text here`.

**/tableflip** appends the table-flipping emoticon (╯°□°)╯︵ ┻━┻ along with any text you provide.

**/unflip** appends the table-restoring emoticon ┬─┬ ノ( ゜-゜ノ) to put the table back where it belongs.

**/lenny** appends the Lenny face ( ͡° ͜ʖ ͡°) to your message.

**/disapprove** appends the look of disapproval ಠ\_ಠ.

**/me** followed by an action posts an italicised action message in the third person. For example, `/me waves hello` displays as "*username waves hello*" in the chat.

**/spoiler** followed by text wraps the entire message in spoiler tags so that other users must click to reveal the content.

**/tts** followed by text sends the message normally and also triggers text-to-speech playback for all users currently viewing the channel.

**/flip** flips a virtual coin and posts the result — either Heads or Tails — in the channel.

**/roll** rolls dice and posts the results. The default is a single six-sided die, but you can specify any combination using the NdS format, where N is the number of dice and S is the number of sides. For example, `/roll 2d20` rolls two twenty-sided dice and shows each individual result plus the total. The maximum allowed is 20 dice with up to 1000 sides each.

**/nick** followed by a name changes your display name. For example, `/nick CaptainHaven` immediately changes your visible name to CaptainHaven.

**/clear** clears the messages from your own screen. This is a local action that only affects your view — no messages are deleted from the server, and other users are not affected.

**/bbs** posts a brief announcement that you will be back soon.

**/brb** posts a brief announcement that you will be right back.

**/afk** posts a brief announcement that you are away from keyboard.

**/hug** followed by a target name posts a message announcing that you hugged that person.

**/wave** posts a message of you waving to the channel.

---

## Reactions and Pins

**Reactions** let you respond to any message with an emoji without sending a separate message. Hover over a message to reveal the reaction button, click it, and select an emoji from the picker. Multiple users can react to the same message, and reactions stack — if several people choose the same emoji, the count is displayed. Clicking your own reaction a second time removes it.

Haven supports both standard Unicode emojis and custom server emojis in reactions. Custom server emojis are uploaded by the admin and can be used in reactions using the `:name:` syntax. A row of quick-reaction emojis is available for one-click reactions without needing to open the full emoji picker.

**Pinning** marks important messages so they can be easily found later. Users with the pin_message permission can pin any message in a channel. Each channel supports up to 50 pinned messages. To view all pinned messages, open the pins panel from the channel header. To remove a pin, click the unpin button next to the pinned message. Pinning and unpinning are visible to all channel members.

---

## Direct Messages and End-to-End Encryption

Haven supports private one-on-one direct messages between any two users. To start a direct message conversation, click on another user's name in the member list and select the option to send them a direct message. A DM channel is created automatically and appears in your sidebar alongside your regular channels.

All direct messages in Haven are protected by end-to-end encryption. The server never has access to the plaintext content of your DMs or the cryptographic keys needed to decrypt them.

### How the Encryption Works

When you first log in, your browser generates an ECDH P-256 key pair — a public key and a private key. The private key is then encrypted (wrapped) using a key derived from your password through the PBKDF2 key derivation function, and the encrypted blob is uploaded to the server for cross-device synchronisation. The crucial point is that the password-derived wrapping key is computed entirely within your browser — it is never transmitted to the server. The server stores only the encrypted private key blob, which it cannot decrypt without your password.

When you send a message to someone, both users' public keys are combined through the ECDH key agreement protocol, then passed through HKDF-SHA256 key derivation to produce a shared AES-256-GCM encryption key unique to that conversation. Every message is encrypted in your browser before it ever leaves your device, and decrypted in the recipient's browser after arrival. The server only ever sees encrypted ciphertext.

### When Your Keys Are Preserved

Your encryption keys survive most everyday scenarios without any user action. Closing the browser tab and reopening it works seamlessly because the keys are cached in your browser's IndexedDB storage, which persists across tab closures and page refreshes. Returning to Haven after your session expired and being auto-logged in also works because IndexedDB retains the cached keys.

If you log in on a new device or a different browser where IndexedDB does not have your keys, Haven prompts you for your password. The password is used to derive the wrapping key, download the server-stored encrypted private key backup, and unwrap it locally. Your message history remains readable.

Changing your password does not break access to old messages. When you change your password, Haven re-wraps your existing private key with a new key derived from the new password and re-uploads it to the server. The underlying ECDH key pair itself does not change, so all existing encrypted conversations remain accessible.

### When Keys Are Lost

There are specific situations where keys can be permanently lost, making old encrypted messages unreadable forever. If you clear all browser data (including site data and IndexedDB) on every device where you are logged in, and you have also changed your password since the server-side backup was last created, the backup becomes undecryptable because the wrapping key no longer matches. In that situation, Haven generates a fresh key pair, and all previous encrypted messages become permanently unreadable.

You can also intentionally reset your encryption keys at any time. In any DM conversation, clicking the reset button in the channel header generates a completely new key pair. All previous messages in that conversation become permanently unreadable for both you and the other person. A timestamped notice is posted in the chat so both parties know exactly when and why old messages became unreadable. You must type the word RESET to confirm this action, as there is no way to undo it.

### Verifying Encryption Integrity

To verify that nobody is intercepting your conversation, click the lock icon in the DM channel header to view your safety number. This is a 60-digit numeric code derived from both users' public keys. Compare this number with your conversation partner through a separate trusted channel — a phone call, a video chat, or an in-person meeting. If the numbers match, you can be confident that no one is intercepting or tampering with the communication.

### Security Model and Limitations

An administrator who directly reads the database cannot decrypt your DMs because the private key stored on the server is wrapped with a key derived from your password, which the admin does not know. An attacker who intercepts network traffic between your browser and the server cannot read messages because they are encrypted client-side before transmission. Someone who steals your JWT authentication token still cannot decrypt messages because the E2E keys reside in your browser's IndexedDB, not in the token, and the server-stored backup requires your password to unwrap.

However, if someone knows both your password and has your JWT token — which is functionally equivalent to having your login credentials — they can derive the wrapping key and decrypt your messages. Additionally, as with every web-based end-to-end encryption system, the encryption is ultimately dependent on the integrity of the JavaScript code served by the server. If the server administrator were to push tampered JavaScript that exfiltrates keys, the encryption could be bypassed. This is a fundamental and well-understood limitation of browser-based E2E encryption that applies to all similar systems.

---

## Voice Chat

Haven includes built-in peer-to-peer voice chat powered by WebRTC. Voice connections are established directly between users' browsers — the server handles only the signalling (coordinating who connects to whom), while the actual audio data flows directly between participants without passing through any server.

To use voice chat, first join a text channel, then click the **Join Voice** button in the channel header. Your browser will request microphone permission, which you must grant. Once connected, you can hear other users who are in the same voice channel, and they can hear you.

The voice interface displays all participants currently in the channel. When someone speaks, their name or avatar glows with a visual indicator showing that they are talking. The talking detection uses a brief hysteresis so the indicator does not flicker during natural speech pauses. Each participant has an individual volume slider that you can adjust to set their loudness relative to others. You can mute your own microphone with the Mute button, and you can deafen yourself to stop hearing all incoming audio.

Voice chat includes a configurable noise gate that helps suppress background noise. You can adjust the noise gate sensitivity from the voice settings — lower values let more sound through, while higher values require louder speech to activate the microphone.

Audio tones play when users join and leave the voice channel, so you always know when someone enters or exits.

### Setting Up a TURN Server for Voice Over the Internet

By default, voice connections use Google's public STUN servers to establish direct peer-to-peer links. STUN works well when both users are on the same network or behind simple, well-behaved NATs. However, STUN alone is not sufficient for connections across restrictive firewalls, symmetric NATs, carrier-grade NAT (common with mobile data and some ISPs), or corporate networks.

For reliable voice connectivity in all network conditions, you need a TURN server. TURN (Traversal Using Relays around NAT) acts as a relay, forwarding audio traffic between users when a direct connection cannot be established. The recommended TURN server software is **coturn**, which is free, open-source, and well-supported.

To install coturn on Ubuntu or Debian:

```bash
sudo apt install coturn
```

Edit the coturn configuration file at /etc/turnserver.conf with the following settings:

```
listening-port=3478
tls-listening-port=5349
realm=your-domain.com
use-auth-secret
static-auth-secret=YOUR_RANDOM_SECRET_HERE
```

Replace YOUR_RANDOM_SECRET_HERE with a long, random string. This string is a shared secret between Haven and coturn — it is used to generate time-limited credentials for each voice session.

Then add the following lines to your Haven `.env` file:

```
TURN_URL=turn:your-server.com:3478
TURN_SECRET=YOUR_RANDOM_SECRET_HERE
```

Restart Haven after saving the changes. Voice connections will now automatically attempt a direct connection first and fall back to the TURN relay when direct connections fail. Haven generates per-session TURN credentials using HMAC-SHA1 that are valid for 24 hours.

If you prefer to use static TURN credentials rather than a shared secret, configure coturn with a fixed username and password, then use the TURN_USERNAME and TURN_PASSWORD environment variables in Haven's `.env` file instead of TURN_SECRET.

For Docker deployments, add the TURN_URL and TURN_SECRET as environment variables in your docker-compose.yml under the haven service's environment section. Examples are included as comments in the default docker-compose.yml file.

If you are hosting coturn on a cloud server such as Oracle Cloud, AWS, or DigitalOcean, make sure that port 3478 (both UDP and TCP) and the port range 49152 through 65535 (UDP) are open in your cloud provider's security group and the server's firewall rules. These ports are necessary for TURN relay traffic to flow.

---

## Screen Sharing

While connected to a voice channel, you can share your entire screen, a specific application window, or a browser tab with other participants. Click the **Share Screen** button in the voice controls and select what you want to share from the browser's screen-sharing dialog.

Your shared screen is visible to everyone currently in the voice channel. Multiple users can share their screens at the same time — when two or more screens are being shared simultaneously, the displays are arranged in a tiled grid layout that adjusts automatically as shares start and stop. Each viewer can individually manage which streams they are watching.

Screen sharing can be enabled or disabled on a per-channel basis by the admin using the channel settings toggle.

---

## Music Sharing

Haven includes a synchronised music player that lets everyone in a voice channel listen to the same music together. While in a voice channel, you can share a YouTube URL to start a shared listening session. A music player appears for all participants, and the host's playback controls — play, pause, seek, skip, previous, and shuffle — are synchronised across all listeners in real time.

If you share a Spotify link instead of a YouTube URL, Haven automatically resolves the track by looking up the song title through Spotify's oEmbed API and then searching for the matching track on YouTube. This is necessary because Spotify embeds only provide 30-second previews to non-premium users.

You can also search for music by name directly from the Haven interface without needing to find a URL first. The search queries YouTube's InnerTube API to find matching tracks.

Music sharing can be enabled or disabled on a per-channel basis by the admin.

---

## Themes and Visual Effects

Haven includes more than twenty visual themes that change the entire look and feel of the interface, from colours and fonts to the overall aesthetic style. Click the theme palette button at the bottom of the sidebar to open the theme picker.

The available themes span a wide range of styles. Haven, the default theme, uses deep blue and purple tones. Discord replicates the familiar dark grey-with-blue-accents look. Matrix renders everything in black and green. Tron brings neon cyan glow on a black background. HALO invokes military green with Mjolnir-inspired styling. Lord of the Rings uses parchment gold and deep earth tones. Cyberpunk combines neon pink with electric yellow. Nord offers calm arctic blues. Dracula features deep purple and crimson. Bloodborne presents a gothic crimson-and-ash palette. Ice uses pale blue and white. Abyss is deep ocean darkness. And there are many more.

Your theme choice is saved in your browser and persists across sessions and page refreshes.

### Visual Effects

In addition to themes, Haven offers stackable visual effect overlays that add animated elements to the interface. Effects are purely atmospheric and do not interfere with usability.

The **CRT** effect simulates a vintage cathode-ray tube display. It renders scanlines across the screen, adds a subtle flicker, and applies a parabolic vignette that darkens the edges to mimic the convex glass curvature of a real CRT monitor. A dedicated slider in the theme settings controls how pronounced the vignette darkening is, ranging from barely visible to a heavy tunnel effect.

The **Matrix** effect overlays cascading columns of green characters, replicating the iconic digital rain visual.

**Snowfall** adds gently falling snowflakes drifting across the screen.

**Campfire** fills the interface with floating ember particles and a warm atmospheric glow.

**Golden Grace** creates drifting golden particles inspired by the Elden Ring aesthetic.

**Blood Vignette** adds dark, slowly pulsing edges to the screen for a foreboding atmosphere.

**Phosphor** applies a Fallout-style green vignette evocative of old terminal screens.

**Water Flow** animates a gentle blue shimmer along the sidebar.

**Frost** produces an ice shimmer with decorative icicle borders.

**Glitch** is a Cyberpunk-themed text scramble effect. Periodically, text elements around the interface — the Haven logo, channel names, section labels, your username, and user names in the member list — briefly "corrupt" into random characters before resolving back to their normal appearance. When this effect is active, a Glitch Frequency slider appears in the theme popup. Slide it left for rare, subtle glitches, or slide it right for near-constant visual chaos.

Additional effects include Candlelight, Ocean Depth, and several sacred-themed overlays.

Each theme has a default associated effect. You can choose the **Auto** option to let the theme pick its own effect, select a specific effect to override the default, or choose **None** to disable effects entirely.

---

## Notification Sounds

Haven uses programmatically generated audio tones and optional custom uploaded sound files to notify you of activity. There are four distinct notification events, each independently configurable: incoming messages from other users, messages that specifically mention you, a user joining the voice channel, and a user leaving the voice channel.

Each event can be assigned a different sound from the available options, which include built-in synthesised tones (ping, bell, chime, drop, and others) as well as any custom sounds uploaded by the admin. Two separate volume controls are available — one for regular message notifications and one for mention notifications — so that you can make mentions louder than ordinary messages.

All notification preferences including the selected sounds, volume levels, and the enabled/disabled toggle are saved in your browser's local storage and persist across sessions.

---

## Push Notifications

Push notifications allow you to receive alerts when someone sends a message to a channel you are a member of, even when the Haven browser tab is in the background, minimised, or completely closed. They appear as native operating system notifications.

### Requirements for Push Notifications

Push notifications require the server to be running over HTTPS. They will not work over a plain HTTP connection, with the sole exception of localhost. You also need a modern browser that supports the Push API — Chrome, Edge, Firefox, or Safari version 16.4 or later all qualify. Haven must be running with SSL certificates generated or configured.

### Enabling Push Notifications

Open Haven in your browser using an `https://` URL. Click the Settings button, scroll to the Push Notifications section, and flip the toggle to enable them. Your browser will prompt you for notification permission — click Allow. The status indicator should then change to show that push notifications are active.

Haven is smart about when it sends push notifications. If you are currently viewing a channel in a focused browser tab, you will not receive push notifications for that channel. Notifications are only sent when the tab is in the background, minimised, or closed.

### Push Notifications on Desktop

On Windows, macOS, and Linux desktop computers, push notifications work in Chrome, Edge, and Firefox without any additional setup. Simply make sure you are accessing Haven through an https:// URL and have granted notification permissions.

### Push Notifications on Android

Open Haven in Chrome or Edge on your Android device using an https:// URL. Enable push notifications in the Settings panel the same way as on desktop. Notifications will appear in your Android notification shade even when the browser is fully closed.

### Push Notifications on iOS and iPadOS

Safari on Apple mobile devices requires iOS 16.4 or later for push notification support, and there is an important additional step. Before enabling push notifications, you must first add Haven to your home screen. Open Haven in Safari, tap the Share button (the square with an upward arrow), and select "Add to Home Screen." Give it a name and tap Add.

Then open Haven from the newly created home screen icon. It will launch as a standalone web app rather than inside Safari. From within this standalone mode, open Settings and enable push notifications. Safari will display the permission prompt for you to accept.

Push notifications will not work through regular Safari tabs on iOS — they only function when Haven has been added to the home screen and launched from there.

---

## GIF Search with GIPHY

Haven includes a built-in GIF picker powered by the GIPHY API. The GIF picker allows all users to search for and send animated GIFs directly in their messages. To use this feature, the admin must first configure it with a free API key.

To obtain a GIPHY API key, visit [developers.giphy.com](https://developers.giphy.com/) and create a free developer account. Once logged in, click Create an App, select the **API** option (not SDK), provide any name and description for the app, and copy the API key displayed on the confirmation page.

In Haven, log in as the admin, click the GIF button in the message input area, and paste your API key into the setup prompt. The key is stored securely on the server in the database. Only the admin can view or change the key.

Once the key is configured, all users can open the GIF picker, search by keyword, browse trending GIFs, and insert them into their messages with a single click. GIPHY's free API tier provides generous request limits that a private chat server will never approach under normal use.

---

## Custom Emojis

Admins can upload custom emojis that become available to all users on the server. Custom emojis appear in the emoji picker alongside the standard Unicode emojis and can be used in both messages and reactions.

To upload a custom emoji, open the admin section of the Settings panel and locate the Custom Emojis area. Upload an image file in PNG, GIF, WebP, or JPEG format, with a maximum file size of 256 kilobytes. Give the emoji a descriptive name. Users can then type `:name:` in a message to insert the custom emoji, or select it from the emoji picker.

Custom emojis can be deleted by the admin at any time.

---

## Custom Notification Sounds

Admins can upload custom notification sounds that all users can select as their notification tones for different events (messages, mentions, voice join, voice leave).

The supported audio formats are WAV, MP3, OGG, and WebM, with a maximum file size of 1 megabyte per sound. Upload custom sounds through the admin section of the Settings panel. Once uploaded, the sounds appear in every user's notification settings dropdown alongside the built-in synthesised tones.

Custom sounds can be deleted by the admin, which will revert any users who had selected them back to the default tone.

---

## Importing from Discord

Haven can import your entire Discord server's message history directly from within the application. This is useful if you are migrating a community from Discord to Haven and want to preserve all your chat history. Only the admin can perform imports.

There are two import methods available, both accessible from the Settings panel under the Import Discord History section.

### Method One — Direct Connect

The Direct Connect method connects to Discord's API using your personal Discord user token and downloads message history in real time. This is the most convenient method because it handles everything automatically.

To obtain your Discord token, open Discord in your web browser (or in the desktop app with developer tools enabled). Press F12 to open the browser's developer tools. Navigate to the Application tab in the developer tools panel. In the left sidebar, expand Local Storage and click on the entry for https://discord.com. Look through the key-value pairs for an entry called "token" and copy its value, making sure not to include the quotation marks.

In Haven, go to Settings, find the Import Discord History section, and click the Connect to Discord tab. Paste your token and click Connect. Haven validates the token and presents a grid showing all Discord servers your account is a member of. Select the server you want to import from.

The next screen shows all available channels in that server, including text channels, announcement channels, forum channels, media channels, and both active and archived threads. Select the channels and threads you want to import.

Click Fetch Messages. Haven begins downloading all selected messages from Discord, handling Discord's rate limits automatically. Depending on the volume of messages, this can take some time for large servers. When the download completes, you see a preview screen showing each channel's name and message count. You can rename any channel before importing it into Haven.

Click Import to execute the final import. Haven creates the corresponding channels and inserts all messages with their original timestamps, reply threading, attachments (as links), reactions, pins, and the original Discord author's username and avatar.

### Method Two — File Upload

If you prefer not to use your Discord token, you can export your Discord data externally and upload the files to Haven.

The first option is to use the **DiscordChatExporter** tool (available at https://github.com/Tyrrrz/DiscordChatExporter) to export channels in JSON format. This gives you a JSON or ZIP file containing the full message history of the channels you selected.

The second option is to use Discord's built-in data request feature. Go to Discord Settings, then Privacy & Safety, and request a copy of your data. Discord will email you a ZIP file containing your message history in CSV format. Note that official Discord data packages only contain messages you personally sent.

In Haven, go to Settings, find the Import section, click the Upload File tab, and select your JSON or ZIP file (up to 500 megabytes). Haven parses the export, recognises the format automatically, and displays a preview. Rename channels as needed and click Import.

### What Gets Imported

The import preserves messages, replies, embeds, attachments (as markdown links), reactions, pins, forum tags, and the original Discord user avatars. Imported messages appear under their original Discord usernames and display a visual indicator showing they were imported. All imported messages are stored under the admin account on the Haven server.

The import covers message history only. Discord-specific constructs like roles, permissions, bots, webhooks, and server settings are not imported, as Haven has its own independent implementations of these features.

Your Discord token is used only for the duration of the import session. It is held in memory during the fetch process and discarded when the import is complete. Haven does not store Discord tokens in the database or in any file.

---

## Webhooks and Bot Integrations

Webhooks enable external services, scripts, and bots to post messages into Haven channels programmatically. Each webhook is tied to a specific channel and identified by a unique 64-character token.

Admins can create webhooks from the channel settings or from the webhook management section of the admin panel. When creating a webhook, you give it a name and optionally upload an avatar image. The name and avatar are used as the sender identity when messages are posted through the webhook.

External services send messages by making an HTTP POST request to the webhook endpoint:

```
POST https://your-server:YOUR_PORT/api/webhooks/YOUR_WEBHOOK_TOKEN
Content-Type: application/json

{
  "content": "Hello from the bot!",
  "username": "Optional Name Override",
  "avatar_url": "https://optional-avatar-override.png"
}
```

The **content** field is required and contains the message text. The **username** and **avatar_url** fields are optional and override the webhook's default name and avatar for that specific message.

Webhook messages appear in the channel with a [BOT] badge and a distinct square avatar shape to distinguish them from messages sent by human users. Webhooks can be enabled, disabled, renamed, reassigned to different channels, or deleted by the admin at any time.

---

## Games

Haven includes a built-in games section accessible from the sidebar. The primary game is a Flappy Bird clone that features a persistent leaderboard. High scores are stored in the database and visible to all users. When someone sets a new high score, a live notification is broadcast to the server.

The admin can also install a set of five classic Flash games from the admin panel. These games are downloaded on demand from a GitHub repository and played in the browser through the Ruffle Flash emulator, which runs entirely in WebAssembly with no Flash plugin required. The available Flash titles are Flight, Learn to Fly 3, Bubble Tanks 3, Tanks, and SuperSmash Flash.

---

## Administration Guide

This section covers all administrative tools available to the server owner. The first user to register on a fresh Haven server automatically becomes the owner with full administrative privileges. Ownership can be transferred to another user at any time from the Settings panel.

### Managing Channels

Admins can create new channels from the sidebar. Each channel receives an automatically generated eight-character hexadecimal invite code. Admins can rename channels, set their topics, create sub-channels beneath them, configure channel code settings (visibility, rotation mode, rotation interval), enable or disable screen sharing and music sharing per channel, set slow mode intervals, assign category labels for sidebar grouping, and reorder channels.

Deleting a channel permanently removes it along with all its messages, sub-channels, reactions, pins, and member associations. This action cannot be undone.

### Moderating Users

**Kicking** a user disconnects them from the server. They can reconnect immediately and rejoin channels using the same invite codes. Kicking is useful as a warning or to address temporary misbehaviour.

**Muting** prevents a user from sending messages for a specified duration, ranging from one minute up to thirty days. Muted users can still read messages and participate in voice chat. They simply cannot send text messages until the mute expires or until an admin unmutes them manually.

**Banning** permanently blocks a user from the server. Banned users cannot log in, cannot connect via WebSocket, and are immediately disconnected from all active sessions. Bans can be reversed using the Unban feature.

**Deleting a user** permanently removes their account from the database along with all associated data including messages, reactions, role assignments, push subscriptions, and EULA acceptances. Only banned users can be deleted. Deleting a user frees up their username for re-registration by someone else.

The admin can view the full list of currently banned users and their ban reasons from the bans management screen.

### Server Branding

The server's display name and icon can be customised from the Settings panel. The server name appears in the sidebar header and in multi-server views. The server icon is displayed alongside the server name. Upload any image up to 2 megabytes as the icon.

### EULA and Terms of Service

Haven includes a terms of service agreement that all users must accept during registration and login. The EULA text is configurable by the admin and supports versioning. Each user's acceptance is recorded with a timestamp, IP address, and the version of the terms they accepted. This provides a legal record of consent.

### Member Visibility Settings

The admin can control how the online member list is displayed. The three options are: show all members regardless of whether they are online, show only currently online members, or hide the member list entirely.

### Upload Size Limit

The maximum allowed file upload size is configurable, ranging from 1 megabyte up to 2048 megabytes. The default is 25 megabytes. This setting applies to general file uploads in messages. Avatar uploads have a separate fixed limit of 2 megabytes, and custom emoji uploads are limited to 256 kilobytes.

### Transferring Admin Ownership

If you need to hand over administrative control of the server to another user, the admin transfer feature is available in the Settings panel. You select the target user and enter your password to confirm the transfer. Once complete, the target user gains admin status and your account reverts to a regular user.

---

## The Role and Permission System

Haven uses a hierarchical role-based permission system that controls what each user can do on the server. Every user has one or more roles, and each role has a numeric level from 1 to 100 that determines its position in the hierarchy. Users with higher-level roles can moderate users with lower-level roles but not vice versa.

### Built-in Roles

**Admin** at level 100 has unrestricted access to all features and settings. This role is automatically assigned to the first registered user (server owner). Ownership can be transferred via the Settings panel.

**Server Mod** at level 50 has broad moderation powers. Server Mods can kick and mute users, delete messages from lower-ranked users, pin messages, manage sub-channels, rename channels, manage webhooks, and perform most day-to-day moderation tasks.

**Channel Mod** at level 25 has moderation powers scoped to specific channels. A Channel Mod can moderate within the channels they are assigned to, including that channel's sub-channels, but not in other channels.

**User** at level 1 is the default role automatically assigned to all new registrations. Users can send and read messages, edit and delete their own messages, upload files, use voice chat, and view message history.

### Creating Custom Roles

Admins can create additional custom roles with any name, level (from 1 to 99), colour (for visual distinction in the member list), and a custom set of permissions. Roles can be scoped to the entire server or to specific channels.

### Role Scope and Inheritance

Server-scoped roles apply everywhere on the server. Channel-scoped roles apply only within the specific channel they are assigned to, plus all sub-channels of that channel. This means that if you assign someone a Channel Mod role on a parent channel, they automatically have Channel Mod powers in all of that channel's sub-channels.

### Available Permissions

The permission system includes the following granular permissions: **edit_own_messages** to edit your own sent messages, **delete_own_messages** to delete your own messages, **delete_message** to delete any message, **delete_lower_messages** to delete messages from users with a lower role level, **pin_message** to pin and unpin messages, **kick_user** to kick users from the server, **mute_user** to mute users for a specified duration, **ban_user** to permanently ban users, **rename_channel** to rename top-level channels, **rename_sub_channel** to rename sub-channels, **set_channel_topic** to change channel topics, **manage_sub_channels** to create and delete sub-channels, **upload_files** to upload files and images, **use_voice** to participate in voice chat, **manage_webhooks** to create and manage webhooks, **mention_everyone** to use @everyone mentions, **view_history** to see message history, **promote_user** to assign roles to other users, and **transfer_admin** to transfer admin ownership.

### Permission Thresholds

The admin can configure permission thresholds, which set the minimum role level required for specific actions. For example, the create_channel action can be restricted to users with a role level of 50 or higher, effectively limiting channel creation to Server Mods and Admins. Thresholds can be adjusted from the admin settings.

### Auto-Assign Roles

One or more roles can be flagged as auto-assign, meaning they are automatically granted to every new user upon registration. The default User role is configured as auto-assign, but the admin can modify this or create additional auto-assign roles.

### Assigning and Revoking Roles

Users with the **promote_user** permission can assign roles to other users, but only roles whose level is lower than their own. This prevents privilege escalation — a level 50 Server Mod can assign level 25 Channel Mod roles but cannot assign level 50 Server Mod roles. Only the admin (level 100) can assign any role.

---

## Server Invite System

Haven uses a Discord-style invite system. Every server has a unique 8-character invite code that is automatically generated on first launch. This code powers the shareable invite link that new users use to join your server.

### Invite Links

The primary way to invite people is by sharing your server's invite link. The link format is:

- **With a custom domain:** `https://yourdomain.com/invite/CODE` (set the `DOMAIN` variable in `.env`)
- **Without a domain:** `http://HOST:PORT/invite/CODE` (uses the HOST and PORT from `.env`)

When someone opens an invite link, they are redirected to the login/registration page. After logging in or registering, they are automatically added to all public channels on the server. This mirrors Discord's "join server" experience — one link gives access to everything.

### Managing the Invite Code

The invite code and its full URL are displayed in the **Server Settings** section of the admin panel. From there you can:

- **Copy the invite link** with one click to share it with friends
- **View the raw code** for manual sharing
- **Regenerate** the code to invalidate the old one and create a new one
- **Clear** the code to prevent any new joins via invite link

Only one server-wide invite code is active at a time. When you regenerate the code, anyone with the old link will no longer be able to use it.

### How Joining Works

1. A user clicks the invite link (or enters the code in the "Join a Server" dialog)
2. If they don't have an account, they register on the login page
3. On successful login or registration, they are automatically added to all public channels on the server
4. Private channels still require their own individual invite codes

This matches Discord exactly: registration gives you an account but no server access. You need an invite link to join a specific server.

### Private Channel Codes

In addition to the server-wide invite code, each channel still has its own unique code. These per-channel codes are only needed for **private channels** (channels with `is_private` set). Public channels are joined automatically when a user joins the server. To join a private channel, enter its code in the "Join Private Channel" input in the sidebar.

---

## Whitelist — Restricting Registration

If you want to restrict who can create accounts on your server, enable the whitelist feature. When the whitelist is active, only usernames that have been explicitly pre-approved by the admin can successfully register. Anyone attempting to register with a username that is not on the whitelist receives an error message.

The whitelist is managed from the admin section of the Settings panel. You can add usernames individually, remove them, and toggle the whitelist enforcement on or off. When the whitelist is disabled, anyone can register. Existing user accounts are never affected by the whitelist — it only controls new registrations.

---

## Auto-Cleanup

Haven can automatically manage the size of your database and uploaded files over time. The admin can configure two independent cleanup rules from the Settings panel.

**Maximum message age** instructs Haven to delete messages that are older than a specified number of days. Set this value to zero to disable age-based cleanup entirely. This is useful for servers that want to keep their message history lean, or for compliance purposes where messages should not be retained indefinitely.

**Maximum database size** instructs Haven to delete the oldest messages when the database file exceeds a specified size in megabytes. Set this to zero to disable size-based cleanup. This prevents your database from growing without bound on systems with limited storage.

Both cleanup rules run automatically in the background at regular intervals when enabled. The admin can also trigger an immediate manual cleanup by clicking the Run Cleanup Now button in the settings. The cleanup process is careful to protect files that are actively in use — avatars, the server icon, custom emojis, and custom notification sounds are never deleted by the cleanup process.

---

## Keyboard Shortcuts

The following keyboard shortcuts are available throughout the Haven interface.

**Shift+Enter** inserts a new line in the message input without sending the message. This is how you create multi-line messages.

**Ctrl+F** opens the message search for the current channel. Type your search query and press Enter to see matching messages.

**@** typed in the message input opens the mention autocomplete popup. Start typing a username to filter the suggestions, and press Tab to insert the selected mention.

**:** typed in the message input opens the emoji autocomplete popup. Type at least two characters after the colon to filter emojis by name, and press Tab to insert the selected emoji.

**/** typed at the very beginning of a message opens the slash command autocomplete popup. Type to filter commands and press Tab to select one.

**Tab** confirms the currently highlighted suggestion in any autocomplete popup.

---

## Backing Up Your Data

Since all of Haven's data resides in the data directory, which is separate from the application code, backing up your server is straightforward. Simply copy the entire data directory to a safe location.

The data directory is at `./data/`. For Docker installations, data is either in a Docker volume named haven_data or in the host directory you mapped in your docker-compose.yml configuration.

The data directory contains everything you need to fully restore your server: the SQLite database (haven.db) with all messages, user accounts, channels, roles, and settings; the .env configuration file; the SSL certificates in the certs subdirectory; and all uploaded files in the uploads subdirectory. The Haven application directory contains no personal data whatsoever and can be replaced by downloading a fresh copy of the code.

For Docker volumes, you can extract the data using:

```bash
docker cp haven:/data ./haven-backup
```

Consider backing up regularly, especially before performing updates or making significant configuration changes.

---

## Updating Haven

### Updating a Git-Based Installation

If you installed Haven by cloning the Git repository, updating to the latest version is a two-step process:

```bash
git pull
npm install
```

Then restart the server. The `git pull` command downloads the latest code changes, and `npm install` ensures any new or updated dependencies are in place. Your data directory is completely separate from the application code, so updating the code never affects your messages, users, or settings.

### Updating a ZIP-Based Installation

If you downloaded Haven as a ZIP file, download the latest version from the repository, extract it over your existing Haven folder (overwriting all files), then run `npm install` in a terminal and restart the server.

### Updating a Docker Installation

If you are using the pre-built Docker image:

```bash
docker compose pull
docker compose up -d
```

If you are building from source:

```bash
git pull
docker compose build --no-cache
docker compose up -d
```

Your data is preserved in the Docker volume and is completely unaffected by container rebuilds.

---

## Troubleshooting

This section covers the most commonly encountered issues when setting up and running Haven, with detailed explanations and step-by-step resolution guidance.

### SSL_ERROR_RX_RECORD_TOO_LONG or ERR_SSL_PROTOCOL_ERROR in the Browser

This error occurs when your browser attempts to connect using HTTPS, but the server is actually running in plain HTTP mode. The browser sends an SSL handshake, the server responds with plain text, and the browser reports a protocol error.

This typically happens when SSL certificates were not generated on first launch, usually because OpenSSL is not installed on your system.

The quickest fix is to change the URL in your browser from `https://` to `http://` (keeping the same host and port). If the server is running in HTTP mode, it can only respond to http:// requests.

For a permanent fix, install OpenSSL so that Haven can generate SSL certificates. On Windows, download OpenSSL from [slproweb.com/products/Win32OpenSSL.html](https://slproweb.com/products/Win32OpenSSL.html) and choose the Light version. During installation, make sure to select "Copy OpenSSL DLLs to the Windows system directory." After installation is complete, restart your computer so that OpenSSL is added to the system PATH. Then navigate to your Haven data directory and delete the certs folder entirely (the path is `./data/certs`). Restart Haven by running Start Haven.bat again. The server will detect that certificates are missing, generate new ones using the now-available OpenSSL, and start in HTTPS mode.

To verify which mode your server is running in, check the startup output in the terminal window. The URL printed there indicates whether Haven is using http:// or https://.

### Node.js Is Not Installed or Not in PATH

If you see this error when running the batch launcher, Node.js is either not installed on your system or is installed but not available in the system PATH environment variable.

The batch launcher offers to install Node.js automatically. Type Y at the prompt and press Enter. The installer downloads the official Node.js LTS release and runs the MSI installer. After the installation completes, you must close the terminal window completely and double-click Start Haven.bat again. This is necessary because the current terminal session does not automatically pick up the PATH changes made by the installer.

If you prefer to install Node.js yourself, download the LTS version from [nodejs.org](https://nodejs.org/). During installation, ensure the checkbox for adding Node.js to the system PATH is selected. After installation, restart your computer and try running Start Haven.bat again.

You can verify that Node.js is properly installed and in your PATH by opening a new terminal window and running `node -v`. If it prints a version number like v22.18.0, Node.js is working correctly.

### The Server Starts but the Browser Shows a Blank Page

This is almost always caused by stale cached files in your browser. Haven updates its client-side JavaScript and CSS with each release, but if your browser has cached old versions, the application may fail to render correctly.

Try opening Haven in an incognito or private browsing window first. If it loads correctly there, the issue is confirmed as a cache problem. Clear your browser's cache for the Haven URL (or clear the entire cache), close and reopen your browser, and navigate to Haven again.

### Error EADDRINUSE — Address Already in Use

This error means another process on your computer is already listening on the network port that Haven is trying to use (the PORT value in your `.env` file, default 3000).

There are two solutions. The first is to find and close the process that is occupying the port. On Windows, run `netstat -ano | findstr :YOUR_PORT` in a Command Prompt (replacing YOUR_PORT with your configured port) to see which process ID is using it, then open Task Manager to identify and close that process. On Linux and macOS, use `lsof -i :YOUR_PORT` to find the process.

The second solution is to change Haven's port. Open the `.env` file in your data directory, find the PORT line, change the value to an available port such as 8080 or 4000, save the file, and restart Haven.

### Friends Can Connect Locally but Not From the Internet

This indicates that port forwarding is not configured correctly, the firewall is blocking incoming connections, or both.

Verify the following items methodically. First, confirm that your router's port forwarding rule specifies the correct internal (local) IP address — the one shown by `ipconfig` on Windows or `ip addr` on Linux. Second, confirm that the port number in the forwarding rule matches the port Haven is actually running on. Third, confirm that the protocol is set to TCP. Fourth, confirm that your Windows firewall (or Linux firewall) has an inbound allow rule for the Haven port. Fifth, ensure your ISP is not blocking incoming connections on that port.

Haven includes a built-in port reachability checker that the admin can use from the Settings panel. It contacts external services to verify whether your server is accessible from the public internet.

If all configuration appears correct and connections still fail, your ISP may be using Carrier-Grade NAT (CGNAT), which does not support inbound connections regardless of your router settings. In this case, use a Cloudflare tunnel instead of port forwarding.

### Voice Chat Does Not Work for Remote Users

Voice chat requires a secure HTTPS connection. If users are connecting via http://, their browsers will refuse to grant microphone access because WebRTC mandates a secure context. Ensure everyone is using https:// in their URL.

If voice works within your local network but fails across the internet, the likely cause is that direct peer-to-peer connections cannot be established through the NAT or firewall. In this case, you need a TURN relay server. See the detailed TURN server setup instructions in the Voice Chat section of this guide.

### Voice Chat Produces Echo

Echo occurs when a user's speakers play audio that is then picked up by their microphone, creating a feedback loop. The definitive solution is for users experiencing echo to wear headphones. Haven's noise gate can reduce mild echo under some conditions, but headphones fully eliminate the problem.

### Certificate Warning in the Browser

A certificate warning when accessing Haven is expected and normal when using a self-signed SSL certificate. Your browser is informing you that the certificate was not issued by a publicly trusted certificate authority. Despite the warning, the connection is fully encrypted.

Click "Advanced" (or "Show Details" in Safari) and then "Proceed to site" (the exact wording varies by browser). You typically only need to accept this once per browser session.

If you want to eliminate the certificate warning altogether, you can obtain a free SSL certificate from a certificate authority such as Let's Encrypt and configure Haven to use it by setting the SSL_CERT_PATH and SSL_KEY_PATH environment variables in your `.env` file.

### Push Notifications Are Not Working

Push notifications require an HTTPS connection. If you are accessing Haven via an http:// URL, the service worker that handles push cannot be registered. Switch to https:// in your browser URL bar.

If push was previously working but has stopped, the VAPID keys in your `.env` file may have been changed or accidentally deleted and regenerated. Changing VAPID keys invalidates every existing push subscription on every device. All users will need to disable and re-enable push notifications in their Haven settings.

On iOS devices, push notifications only work when Haven has been added to the home screen and launched from the home screen icon. They do not work through regular Safari browsing.

### Tunnel Shows 502 Bad Gateway

A 502 error from the Cloudflare tunnel means that Cloudflare's infrastructure is running the tunnel and can accept connections from visitors, but the tunnel cannot reach Haven on your local machine. This usually means Haven is not running, or it started after the tunnel was enabled.

Make sure Haven is fully started and listening on its configured port before enabling the tunnel in the settings. If Haven is running but the error persists, check that the port matches and that Haven is running in HTTPS mode (Cloudflare's tunnel connects to the local HTTPS endpoint).

### Tunnel URL Changes Every Time You Restart

This is the expected behaviour of Cloudflare's free quick tunnels. A new random URL is generated each time. If you need a stable, permanent URL, set up a free Cloudflare account and configure a named tunnel pointed at your own domain. See the Cloudflare documentation for named tunnel setup.

### Database Locked or Slow Performance

If you encounter occasional "database is locked" errors or notice slow query performance, this usually indicates that multiple Haven processes are running simultaneously and competing for database access. Haven is designed for a single server process. Check that you do not have multiple instances running on the same database.

Haven configures its SQLite database with WAL (Write-Ahead Logging) journal mode, a 64-megabyte page cache, and a 5-second busy timeout, which provides robust performance under normal load. For very large databases that have accumulated significant history, consider enabling the auto-cleanup feature to keep the database size manageable.

### Cloudflared Not Found After Installation

If the `cloudflared --version` command cannot be found after installation, the most common reason is that the terminal session was not restarted after the install completed. Close your terminal window entirely and open a new one. On Windows, you may also need to restart the computer for the PATH changes to take effect system-wide.

If the command is still not found, verify that cloudflared's installation directory is included in your system's PATH environment variable and add it manually if necessary.

---

## Router-Specific Notes

### Xfinity and Comcast — XB7 Gateway

Xfinity's XB7 gateway has specific behaviours that frequently trip up users trying to set up port forwarding. Open the Xfinity app on your phone, navigate to WiFi, scroll down to Advanced settings, and select Port forwarding. Choose your computer from the list of connected devices and add a rule for your Haven port with TCP/UDP protocol.

There is a critically important additional step that many users miss: return to the Home section of the Xfinity app and disable **xFi Advanced Security**. This security feature silently blocks all inbound connections to your network, completely overriding any port forwarding rules. Many users spend considerable time troubleshooting port forwarding configurations only to discover that Advanced Security was blocking everything the entire time.

Also confirm that the IP address reserved for your computer in the port forwarding settings matches your computer's actual current local IP address. You can check this by running `ipconfig` in a Command Prompt and comparing the IPv4 Address to what the Xfinity app shows.

### General Router Guidance

Most consumer routers have a web-based administration interface accessible at http://192.168.1.1 or http://10.0.0.1 in a web browser. The default login credentials are often printed on a sticker on the bottom or back of the router. If the default credentials do not work, you may have changed them previously, or your ISP may have set custom credentials during installation.

If your router supports UPnP (Universal Plug and Play), port forwarding may happen automatically. However, UPnP is often disabled by default for security reasons and is less reliable than manual port forwarding configuration.

Some internet service providers, particularly those delivering fibre internet through CGNAT (Carrier-Grade NAT), do not support inbound connections at all. No amount of port forwarding configuration on your router will make your server reachable if your ISP uses CGNAT, because your router does not have a dedicated public IP address. You can verify this by comparing the public IP shown at whatismyip.com with the WAN IP shown on your router's status page — if they differ, you are behind CGNAT. In this situation, a Cloudflare tunnel is your only practical option for remote access.

---

<p align="center"><b>Haven</b> — Your server. Your rules.</p>

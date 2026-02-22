# Changelog

All notable changes to Haven are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/). Haven uses [Semantic Versioning](https://semver.org/).

> **Deploy checklist** — after committing changes:
> 1. `git push origin main` — pushes code **and** GitHub Pages site (`docs/`)
> 2. `website/index.html` is auto-synced from `docs/index.html` — keep them identical
> 3. Restart the Haven server to pick up `server.js` / `socketHandlers.js` changes

---

## [2.2.4] — 2026-02-22

### Security
• SSRF bypass in link previews — link preview endpoint now uses `redirect: 'manual'` with manual redirect following (max 5 hops), re-validating each redirect target against private IP / DNS checks to prevent `evil.com` → 302 → `http://169.254.169.254/` style attacks.
• JWT admin claim trust — all 13 REST API admin endpoints now verify `is_admin` from the database instead of trusting the JWT claim, preventing demoted admins from using stale tokens.
• Path traversal in avatar/icon uploads — `set-avatar` and `server_icon` settings now validate paths with a strict regex (`/^\/uploads\/[\w\-.]+$/`) instead of a prefix check, blocking `../` traversal payloads like `/uploads/../../etc/passwd`.
• mark-read missing membership check — the `mark-read` socket event now verifies channel membership before allowing read-position writes, preventing any user from inserting read positions for channels they don't belong to.
• transfer-admin race condition — added a mutex flag and post-`await` DB re-check around the async `bcrypt.compare()` call, preventing concurrent transfer requests from racing past the admin verification.
• Server-side content sanitization — added `sanitizeText()` defense-in-depth filter that strips `<script>`, `<iframe>`, `<object>`, `<embed>`, `<style>`, `<meta>`, `<form>`, `<link>` tags, event handler attributes, and `javascript:` URIs. Applied to messages, edits, bios, and channel topics.
• Dependency vulnerabilities — patched all 6 npm audit findings (qs, bn.js, axios) via `npm audit fix` and `overrides` in package.json. Audit now reports 0 vulnerabilities.

### Fixed
• broadcastChannelLists DoS — added 150 ms debounce to batch rapid channel mutations, preventing O(N × queries) storms when channels are reordered.
• reorder-channels unbounded input — capped the channel reorder array to 500 items to prevent excessive DB writes from a single socket event.
• Bot delete button greyed out — scoped disabled state to E2E reset button only, preventing .btn-danger elements from being unintentionally disabled.
• Docker image tags versioning — per-platform builds now use release version in tags (e.g. v2.2.1-amd64) instead of hardcoded suffixes, preventing overwrites.
• OpenSSL auto-detection — startup script now checks common install directories (C:\Program Files\OpenSSL-Win64\bin) when OpenSSL is not on PATH.

### Changed
• Documented intentional `rejectUnauthorized: false` usage in port-check (self-connection to own public IP only).
• Website & docs updated to v2.2.4.

## [2.2.3] — 2026-02-22

### Notes
I got sent this project from a friend but I find this has been vibe coded? I can see a lot of AI style coding, I have ran my scanner and found over 200 issues from security issues to performance problems, I have changed a lot of it out, replaced and removed code.

This has been my own contribution but to my fork only, if the devs see this, you can copy any part of it, I have fixed many of the missing code such as the ports not being dynamic with the .env that exists.

The changes done will make sure everything here fits what I want specifically, on ocassion I may read the current commits and add them to this code but after heavy review as I do not trust what is posted without a thorough read!

### Added
- **Zero-external-calls guarantee** — Haven no longer contacts any external server on its own during normal operation. Google Fonts, Google STUN servers, Google Analytics, the GitHub update checker, and ipify.org IP detection have all been replaced or removed. Users can confidently claim "no data is sent to a random machine."
- **Discord-style server invite system** — shareable invite links (`/invite/CODE`) work exactly like Discord invite URLs. A server-wide 8-character invite code is auto-generated on first launch and stored in the database. The `DOMAIN` environment variable enables pretty invite URLs (e.g. `https://haven.example.com/invite/abc12345`); without it, the server falls back to `HOST:PORT`.
- **`/invite/:code` HTTP route** — visiting an invite URL redirects to `/?invite=CODE`, where the login page preserves the invite code through authentication and the app auto-joins the user on connect.
- **`/api/server-info` API endpoint** — public endpoint returning server name, icon, member count, invite code, and fully-qualified invite URL. Used by the admin panel, setup wizard, and multi-server status pings.
- **Auto-join all public channels on registration** — new users are automatically added to every non-DM, non-private channel (and their non-private sub-channels) when they register, exactly like joining a Discord server gives access to all public channels.
- **Auto-add all users to new public channels** — when a channel is created, all existing users are automatically added as members and notified in real-time, mirroring Discord's behaviour where new channels instantly appear for everyone.
- **"Join a Server" modal** — the server bar "+" button now opens a Discord-style dialog that accepts invite links or codes. Entering a local server code joins all public channels; entering a remote Haven URL adds it as a bookmarked external server.
- **Admin invite URL display** — the Server Settings panel now shows the full invite URL with a one-click "Copy Link" button, the raw invite code, and Regenerate/Clear actions.
- **Setup wizard invite step** — the final wizard step now prominently displays the server's invite link with a copy button and explains the 3-step join process (share link → register → auto-join).
- **`DOMAIN` environment variable** — optional `.env` setting for servers with a custom domain. When set, invite URLs use `https://DOMAIN/invite/CODE` instead of `http://HOST:PORT/invite/CODE`.
- **Self-hosted web fonts** — VT323 and Share Tech Mono font files are now bundled locally under `public/fonts/` as WOFF2 files. The Google Fonts CDN import has been replaced with local `@font-face` declarations.
- **Self-hosted Ruffle Flash emulator** — the full Ruffle WASM package is now bundled under `public/games/ruffle/` instead of loading from the unpkg CDN.
- **Discord-style ownership model** — the first user to register on a fresh server automatically becomes the owner/admin, exactly like creating a new Discord server. No special username required. The `ADMIN_USERNAME` environment variable has been removed from all code, configuration files, and documentation.
- **Channel creator management** — users who create a channel can now fully manage it (delete, rotate invite codes, configure code settings, toggle permissions, set slow mode, set categories, reorder) without needing a server-wide admin role. This mirrors Discord where the channel creator has full control over their channel.
- **`_isChannelOwner()` and `_canManageChannel()` client helpers** — new methods on the client app for consistent channel-ownership permission checks throughout the UI.
- **`create_channel` permission for all users** — the default User role (level 1) now includes the `create_channel` permission, and the permission threshold has been lowered from 50 to 1. Any user can create channels, just like Discord. Existing databases are automatically migrated.
- **Thread / reply system** — any message can now be opened as a thread. A side panel shows the root message, a reply count divider, and all threaded replies. Thread replies do not appear in the main channel feed, keeping conversations focused. New socket events (`get-thread-messages`, `send-thread-message`), a `thread_id` foreign-key column with index, full client-side UI (open/close/render/send), and 176 lines of dedicated CSS.
- **Client-side XSS sanitiser (`safe-html.js`)** — new script provides `Element.prototype._safeHTML` and `window.safeInsertHTML()`. All user-facing HTML injection points across the app, games, and theme files now pass through this sanitiser, which strips `<script>` tags, event-handler attributes, `javascript:` URIs, and other dangerous elements before DOM insertion.
- **Stop Haven.bat** — new one-click script reads the configured `PORT` from `.env`, locates the running Node process via `netstat`, and terminates it with `taskkill`.
- **Launcher network diagnostics** — `Start Haven.bat` and `start.sh` now detect LAN IP (via `ipconfig` / `ip route`), public IP (via the ipify API), and test basic internet connectivity before startup, displaying all addresses to the user.
- **Firewall auto-configuration** — `Start Haven.bat` checks for an existing Windows Firewall rule and creates one automatically (inbound TCP on the configured port) if missing.
- **HAVEN_QUIET mode** — launchers set `HAVEN_QUIET=1` so the server suppresses routine startup banners, keeping terminal output focused on actionable information.
- **Foreground server process** — `Start Haven.bat` now launches the Node server in the foreground so Ctrl+C cleanly shuts it down, replacing the previous background-spawn approach.
- **Shared upload helpers** — new `validateImageMagicBytes()` and `safeImageRename()` functions in the server eliminate three duplicate inline implementations across avatar, webhook-avatar, and image-upload routes.
- **Rate-limiter factory** — `createRateLimiter(limit, windowMs)` replaces three separate inline rate-limiter blocks (upload, GIF, link-preview) with a single reusable factory.

### Fixed
- **Login "Connection error" on plain HTTP** — `crypto.subtle` is only available in Secure Contexts (HTTPS/localhost). Accessing Haven over plain HTTP (e.g. `http://192.168.0.57:3001`) caused `deriveE2EWrappingKey()` to throw inside the login/register try-catch, producing a misleading "Connection error — is the server running?" message. Added a `_cryptoAvailable` check that gracefully skips E2E key derivation on HTTP instead of crashing.
- **Password length mismatch** — the client login page said "Minimum 6 characters" but the server required 8. Updated both the `minlength` attribute and help text to 8.
- **Registration error too vague** — "Registration could not be completed" gave no indication that the username was already taken. Now returns 409 with "Username is already taken".
- **Duplicate `const channel` declarations** — several socket handlers (`set-slow-mode`, `set-sort-alphabetical`, `set-channel-category`) had duplicate variable declarations after the channel-creator permission check was added. Removed the redundant lookups.
- **N+1 unread-count queries** — per-channel unread counts are now fetched in a single batched CTE query instead of one query per channel.
- **N+1 DM-target queries** — DM conversation target usernames are now resolved in a single batched query instead of one per conversation.
- **Channel-code rotation performance** — the prepared `UPDATE` statement is hoisted outside the loop and all rotations run inside a single transaction.
- **Push-subscription cleanup** — the prepared `DELETE` for expired subscriptions is hoisted outside the loop.
- **Server-code join query** — the prepared `SELECT` for sub-channel membership is hoisted outside the join handler.
- **Auto-role and sub-channel inserts** — new-member role grants and sub-channel subscriptions are wrapped in a transaction with a guard against empty arrays.
- **Role-permission updates not atomic** — permission changes for a role are now wrapped in a single transaction so partial writes cannot occur.
- **Auto-role migration safety** — the v2.2.2 auto-role migration is wrapped in a transaction with a length check.
- **Registration no longer auto-joins channels** — New users start with empty sidebar, matching Discord where you need an invite to join a server. Registration creates an account but no channel access.
- **Channel deletion for creators** — Channel creators can now delete their own channels from the context menu, not just admins. This matches Discord's permission model.

### Security
- **Google STUN servers removed** — WebRTC ICE configuration no longer includes Google's public STUN servers (`stun.l.google.com`). Voice chat still works on LAN without any external STUN/TURN traffic. Admins can configure their own ICE servers if needed.
- **GitHub update checker removed** — the client-side `_checkForUpdates()` method that polled `api.github.com` every 30 minutes has been completely removed (call + method body + `_isNewerVersion` helper).
- **Google Analytics removed** — `gtag.js` scripts removed from `docs/index.html` and `website/index.html`. No analytics or tracking of any kind.
- **Public IP detection removed from launchers** — `Start Haven.bat` and `start.sh` no longer call `api.ipify.org` to detect a public IP. Only the local LAN address is displayed.
- **Content Security Policy tightened** — `unpkg.com` removed from `script-src` and `worker-src` directives now that Ruffle is self-hosted.
- **E2E key derivation graceful degradation** — `deriveE2EWrappingKey()` returns `null` instead of throwing when `crypto.subtle` is unavailable (non-secure context). `sessionStorage` writes are guarded with `if (e2eWrap)` checks.
- **Max password length raised** — increased from 128 to 1024 characters on both register and change-password endpoints to support passphrases and generated passwords.
- **CORS origin validation** — the `/api/health` endpoint now parses and validates the `Origin` header against `http:` / `https:` protocols instead of reflecting a wildcard `*`.
- **`SELECT *` eliminated** — login and change-password queries in `auth.js` now request only the columns they need (`id`, `username`, `password_hash`, `is_admin`, `display_name`).
- **Column-name whitelisting on dynamic SQL** — `database.js` migrations that iterate over column names now reject any name not matching `/^[a-z_]+$/`. Dynamic `UPDATE` statements for channels and roles validate column names against explicit `Set` whitelists (`allowedChannelCols`, `allowedRoleCols`).
- **`rejectUnauthorized` scoped** — the TLS override is now limited to the self-signed health-check agent with an inline comment, instead of being set process-wide.
- **`Set.has()` for permission checks** — `validPerms` converted from an `Array` (`.includes()`) to a `Set` (`.has()`) for constant-time lookups.
- **innerHTML → _safeHTML / textContent** — approximately 50 `innerHTML` assignments across `app.js`, `theme.js`, `flappy.js`, `flash-game.js`, and `io-games.js` now use the new sanitiser. Element-clearing calls (`innerHTML = ''`) replaced with `textContent = ''`.

### Changed
- **"Add Server" → "Join a Server"** — the server bar "+" button and its modal have been completely reworked to match Discord's join flow. Invite codes and links are the primary input; adding an external Haven server is a secondary action.
- **"Join a Channel" → "Join Private Channel"** — the sidebar channel join input is now clearly labelled for private channel codes only, since public channels are joined automatically.
- **Server invite code auto-generated** — the server creates an 8-character hex invite code on first boot if one doesn't exist, stored in `server_settings`. No manual generation required.
- **Invite URL protocol detection** — the `/api/server-info` endpoint now correctly uses `http://` or `https://` based on the actual SSL configuration rather than defaulting to `https`.
- **External calls are now opt-in only** — all remaining external network calls (GIPHY, YouTube/Spotify/SoundCloud embeds, link previews, Discord import, port checker, .io games, localtunnel) are user-initiated and require explicit action. The server makes zero automatic outbound requests on startup or during idle operation.
- **`ADMIN_USERNAME` removed everywhere** — deleted from `.env`, `.env.example`, `docker-compose.yml`, `src/auth.js`, `src/socketHandlers.js`, and `server.js`. The server startup banner now shows "Owner: First registered user" instead of "Admin: admin".
- **First-user-is-owner registration** — `src/auth.js` now counts existing users (`SELECT COUNT(*) FROM users`) during registration. If zero, the new user gets `is_admin=1`. Works identically to how Discord assigns ownership to whoever creates a server.
- **Socket auth no longer syncs admin from .env** — `src/socketHandlers.js` reads `is_admin` directly from the database on every connection instead of comparing against an environment variable.
- **Channel management checks updated** — all channel management socket handlers (`delete-channel`, `update-channel-code-settings`, `rotate-channel-code`, `toggle-channel-permission`, `set-slow-mode`, `set-sort-alphabetical`, `set-channel-category`, `move-channel`) now allow the action if the user is admin OR the channel creator.
- **Topic bar edit access** — the topic edit pencil icon now appears for channel creators, not just admins and users with `set_channel_topic` permission.
- **Database migration** — existing databases automatically get the lowered `create_channel` threshold and the `create_channel` permission added to existing User roles.
- **Synchronous fs → async fs/promises** — all file-system calls in `server.js` (uploads, deletes, directory reads, existence checks, file writes) converted from blocking `fs.*Sync` to non-blocking `fsp.*` with proper error handling.
- **Console-log cleanup** — removed emoji prefixes from every server and client log message; routine events (connections, disconnections, renames, DM deletes) downgraded from `console.log` to `console.debug`; JWT secret value no longer printed; avatar and E2E debug lines removed entirely.
- **UI emoji removal** — stripped decorative emoji prefixes from all labels, headings, buttons, nav items, modal titles, context menus, wizard steps, and status indicators across `app.html`, `app.js`, `voice.js`, `theme.js`, `e2e.js`, `paths.js`, `docker-entrypoint.sh`, game pages, docs, and website.
- **Start Haven.bat rewritten** — reads `PORT` from `.env` instead of hardcoding 3000; syncs `.env` between project and data directories; detects Node.js availability; checks port availability before launch; generates SSL certs only when OpenSSL is present; displays LAN/public URLs with correct protocol.
- **start.sh rewritten** — same improvements as the `.bat` launcher plus a Node.js version guard (rejects v24+ due to compatibility issues).
- **install-node.ps1 tidied** — redundant comments removed, error messages clarified, installation verification step added.
- **GUIDE.md overhauled** — complete rewrite with a 39-section table of contents covering every feature, configuration option, and troubleshooting scenario. Removed all `ADMIN_USERNAME` references; rewrote First Launch, Configuration Reference, Administration Guide, Admin Transfer, and Built-in Roles sections to reflect the Discord-style ownership model. Approximately 860 lines added and 730 removed.
- **README.md streamlined** — removed the v2.0.0 Discord-import promotional section, simplified quick-start instructions, updated screenshot and version badge. Replaced "register with username admin" with first-user-is-owner wording.
- **Website & docs** — `website/index.html` and `docs/index.html` updated with v2.2.2 version references, download links, version-history entry, and emoji-free badges. `docs/support.html` email button emoji removed.
- **Duplicate `require` calls removed** — approximately 15 inline `const { getDb } = require('./src/database')` calls in `server.js` consolidated to a single top-level import.
- **package.json** version bumped to 2.2.3.

---

## [2.2.2] — 2026-02-21

### Added
- **FORCE_HTTP mode** — set `FORCE_HTTP=true` in `.env` to skip built-in SSL entirely, making reverse proxy setups (Caddy, nginx, Traefik) painless. Startup scripts also skip cert generation when enabled.
- **Auto-assign default roles** — roles can now be flagged as auto-assign in the admin panel. Flagged roles are automatically given to new users on registration and when joining a channel.

### Fixed
- **Docker ARM build failing** — replaced QEMU-based cross-compilation with native ARM runners (`ubuntu-24.04-arm64`) and a manifest merge step so the multi-arch image builds reliably.
- **HSTS header sent in HTTP mode** — Strict-Transport-Security is now disabled when FORCE_HTTP is active.
- **window.app not exposed globally** — the main app instance is now assigned to `window.app`, fixing integration hooks.

### Changed
- Website & docs updated to v2.2.2.

---

## [2.2.1] — 2026-02-21

### Fixed
- **Channel code hidden on mobile** — the channel code tag is now visible on tablet and phone with compact sizing instead of being hidden entirely.
- **Logout icon broken on Android** — replaced the Unicode power symbol (⏻) with an inline SVG that renders on all devices.
- **Mobile menu buttons missing on first load** — added an early media query so hamburger / users sidebar buttons render immediately instead of waiting for later CSS to load.
- **Status picker clipped on mobile** — switched from `position: absolute` (clipped by sidebar overflow) to `position: fixed` with JS-based placement.
- **Status change fails while disconnected** — status updates are now queued and applied automatically on reconnect, with a toast notification.
- **TURN credentials never fetched** — fixed localStorage key mismatch (`haven_token` → `token`) so voice chat works across networks, not just LAN.
- **File upload type restrictions removed** — server no longer blocks uploads by MIME type; a client-side warning is shown for risky file extensions instead.
- **Server branding not persisting** — added error handling for branding save failures.

### Changed
- Website & docs updated to v2.2.1 with download links and version history.

---

## [2.2.0] — 2026-02-20

### Added
- **CRT fishbowl vignette overlay** — the CRT effect now simulates the convex glass of a classic cathode-ray tube with a parabolic vignette, curved edges, phosphor glow, and a subtle glass reflection highlight.
- **CRT vignette darkness slider** — new slider in the effect panel controls how far the darkness encroaches from the edges and how dark it gets (0 = almost invisible, 100 = heavy CRT tunnel).
- **CRT scanline intensity slider** — new slider controls scanline opacity (0–80%) with lines that fade toward the center via a radial mask.
- **CRT flicker frequency range** — the CRT speed slider now maps to a wider flicker frequency range (half the previous slowest, double the previous fastest) for fine-grained control.
- **Inline YouTube embeds** — YouTube links posted in chat now render an inline video player directly in the message, supporting youtube.com, youtu.be, /shorts/, /embed/, and music.youtube.com URLs.
- **Emoji quickbar flip-below** — the quick-react emoji picker now detects when it would be clipped at the top of the viewport and flips below the message instead.

### Fixed
- **CRT vignette slider not appearing** — the vignette/scanline sliders are now injected directly into the effect speed editor block, fixing a visibility bug where the standalone editor div was never shown.
- **CRT vignette slider not working** — the flicker animation was overriding inline opacity; vignette now controls the gradient directly so both flicker and vignette coexist.
- **Reaction picker clipping** — emoji quickbar for messages near the top of the chat area no longer gets cut off.

### Changed
- **Website & docs** updated to v2.2.0 with feature descriptions and version history.
- **README** — version badge updated to v2.2.0.

---

## [2.1.0] — 2026-02-19

### Fixed
- **E2E encryption — multi-device key sync** — encrypted DM keys now stay in sync across multiple browsers and devices. Previously, logging in on a second device could cause key conflicts and break encryption for both sessions.
- **E2E encryption — infinite sync loop** — resolved a condition where two devices could repeatedly overwrite each other's keys, causing an endless conflict cycle.
- **Channel organizer — category/tag sorting** — the Up/Down buttons for reordering category headers (tag sections) in the Organize modal now work correctly. Previously, the buttons were disabled even when Manual Order was selected.
- **Channel organizer — channel sorting within groups** — moving channels up/down now correctly swaps within the visible tag group instead of the flat channel list.
- **Settings crash** — fixed a `TypeError` in server settings that could cause intermittent UI issues.

### Changed
- **E2E architecture improvements** — smarter key backup strategy prevents accidental overwrites when multiple devices are active. Cross-device sync notifications ensure all sessions stay current.
- **Cache-busting** — client JS files now use version-based cache keys to prevent stale code after updates.

---

## [2.0.1] — 2026-02-19

### Fixed
- **Security: removed GUI installer wizard** — the cross-platform GUI installer (PR #26) could open browser tabs and break running servers on the host machine. Reverted entirely.

---

## [2.0.0] — 2026-02-19

### Added
- **Discord history import — Direct Connect** — import your entire Discord server's message history directly into Haven. No external tools required. Built-in token retrieval instructions (Application tab → Local Storage method). Supports text channels, announcement channels, forum channels, media channels, threads (active + archived), and forum tags. Preserves messages, embeds, attachments, reactions, replies, pins, and Discord avatars.
- **Discord history import — File upload** — alternatively upload a DiscordChatExporter JSON or ZIP archive to import channel history.
- **Tabbed import modal** — the import dialog now has two tabs: Upload File and Connect to Discord.
- **Discord avatar preservation** — imported messages display the original author's Discord avatar (CDN URL) instead of the Haven admin's avatar. New `webhook_avatar` database column.
- **Full server structure import** — import fetches announcement (type 5), forum (type 15), and media (type 16) channels in addition to text channels. Threads (active + archived public) are nested under their parent channels. Forum tags are resolved and displayed.
- **Channel type indicators** — import channel picker shows type icons: # text, announcement, forum, media, thread.

### Fixed
- **E2E key loss on password change** — changing your password no longer orphans your encrypted DM key backup. The private key is now automatically re-wrapped with the new password and re-uploaded to the server, so login on new devices continues to work.
- **Scroll-to-bottom loop** — loading Discord CDN images (or any images) in chat no longer forces the viewport back to the bottom when you're scrolled up reading history.
- **ARM64 Docker support** (#34) — Docker image now builds and runs correctly on ARM64 (Raspberry Pi, Apple Silicon, etc.).

### Changed
- **Website & docs** updated to v2.0.0 with Discord import feature callout.
- **README** — added Discord import section with feature description.
- **GUIDE** — added Discord import instructions.

---

## [1.9.2] — 2026-02-18

### Added
- **Image lightbox** — clicking an image opens a full-screen overlay instead of a new tab. Click anywhere or press Escape to close.
- **Image display mode setting** — choose between compact thumbnails (default, 180px) or full-width Discord-style embeds in Settings › Layout.
- **Emoji autocomplete** — type `:` followed by 2+ characters to search emojis by name. Custom server emojis appear first. Navigate with arrow keys, insert with Enter/Tab.
- **Animated GIF avatars** — upload a GIF as your profile picture and it animates everywhere (messages, sidebar, profile popup). Format hint added to the upload UI.
- **Voice chat profile clicks** — click a username in the voice panel to open their profile popup (bio, DM, etc.), same as clicking a name in the sidebar.
- **Auto-focus message input** — the text box is automatically focused when switching channels or opening DMs.
- **Docker image publishing** — pre-built Docker images are now automatically pushed to GitHub Container Registry on every release (`ghcr.io/ancsemi/haven:latest`). No build step needed.

### Changed
- **Website & docs** updated to v1.9.2 with version history entries for v1.9.1.
- **README** — added Docker pull instructions, emoji autocomplete to keyboard shortcuts, updated feature descriptions.
- **GUIDE** — added pre-built Docker image quick start option.

### Fixed
- **Auto-cleanup deleting server assets** (#32) — the file cleanup routine now protects server icons, user avatars, custom emojis, custom sounds, and webhook avatars from deletion.

---

## [1.9.1] — 2026-02-18

### Added
- **Custom server emojis** — admins can upload PNG/GIF/WebP images as custom emojis (`:emoji_name:` syntax). Works in messages, reactions, and the emoji picker.
- **Emoji quickbar customization** — click the gear icon on the reaction picker to swap any of the 8 quick-react slots with any emoji (including custom ones). Saved per-user in localStorage.
- **DM deletion** — right-click (or click "...") on any DM conversation to delete it. Removes from your sidebar only.
- **Reply banner click-to-scroll** — clicking the reply preview above a message now smooth-scrolls to the original message and highlights it briefly.
- **Settings navigation sidebar** — the settings modal now has a left-side index with clickable categories (Layout, Sounds, Push, Password, and all admin subsections). Hidden on mobile.
- **Popout modals for sounds & emojis** — Custom Sounds and Custom Emojis management moved out of the inline settings panel into their own dedicated modals (like Bots/Roles). Keeps the settings menu lean.
- **JWT identity cross-check** — tokens are now validated against the actual database user, preventing token reuse across accounts (security hardening).

### Fixed
- **Docker entrypoint CRLF crash** — added `.gitattributes` to force LF line endings on shell scripts, plus a `sed` fallback in the Dockerfile.
- **Quick emoji editor immediately closing** — click events inside the editor propagated to the document-level close handler. Added `stopPropagation()` to all interactive elements.
- **Gear icon placement** — moved the customization button to the right of the "⋯" more-emojis button so frequent "..." clicks aren't blocked.

---

## [1.9.0] — 2026-02-17

### Added
- **First-time admin setup wizard** — 4-step guided setup on first launch: server name/description, create a channel, port reachability check, and summary with invite code.
- **Port reachability check** (`/api/port-check`) — tests if the server is accessible from the internet using external services (ipify + portchecker.io with self-connect fallback).
- **One-click Windows launcher** — `Start Haven.bat` handles everything: detects Node.js, offers automatic install (downloads Node 22 LTS MSI via PowerShell), installs npm dependencies, generates SSL certs, starts the server, and opens the browser.
- **Node.js auto-installer** (`install-node.ps1`) — PowerShell script that downloads and installs Node.js 22 LTS directly from nodejs.org. Pinned to v22 for native module compatibility.
- **Full emoji reaction picker** — the quick-react bar now has a `⋯` button that opens a scrollable, searchable panel with all emoji categories (not just 8 quick emojis).
- **Unified file upload button** — merged the image upload (landscape SVG) and file upload (paperclip) into one button. Images get queued with preview; other files upload immediately. Win95 theme shows instead of the SVG icon.
- **Input actions toolbar** — upload, emoji, and GIF buttons are now wrapped in a bordered backdrop box with vertical dividers (matching the channel header actions style).
- **Node.js version guard** — batch launcher and `package.json` engines field block Node ≥ 24 (where `better-sqlite3` prebuilt binaries don't exist yet).

### Fixed
- **E2E encryption: permanent decrypt failure** — partner public keys were cached forever and never re-fetched if the partner regenerated keys. Now always re-fetches, detects key changes, and invalidates the stale ECDH shared secret cache. Also fixed a race condition where messages were fetched before the partner key was available.
- **DM messages pushed to right side** — the E2E lock icon (🔒) in compact messages had `margin-left: auto` as a direct flex child, shoving the entire message content to the far right edge. Moved the lock inside `.message-content`.
- **Reactions appeared inconsistently** — in compact (grouped) messages, reactions were a flex sibling appearing to the right of the text instead of below. Now both compact and full messages use the same `.message-body` wrapper.
- **Reactions lost on message promotion** — `_promoteCompactToFull` used the wrong selector (`.reactions` → `.reactions-row`), silently dropping reactions when a group's root message was deleted.
- **`npm install` killed the batch launcher** — `npm` on Windows is `npm.cmd`; running it from a `.bat` without `call` transfers control permanently and the window vanishes. Added `call` keyword.
- **Node v24 build failures** — the auto-installer grabbed the latest LTS (v24), but `better-sqlite3` had no prebuilt binaries for it, causing a `node-gyp` compile attempt that fails without Python + C++ build tools. Pinned installer to Node 22 LTS.
- **`dotenv` MODULE_NOT_FOUND on fresh install** — an empty `node_modules` folder from a failed prior run caused the existence check to pass, skipping `npm install`. Changed to always run `call npm install` (fast no-op when deps exist).

### Changed
- **README restructured** — Docker-first install flow, "Who Is This For?" and "Why Not Discord?" sections added for non-technical audiences.
- **Website comparison table** — added Fluxer column and updated the screenshot.

---

## [1.8.2] — 2026-02-17

### Fixed
- **PiP reverted to native browser system** — the in-page overlay approach has been dropped in favor of the native Picture-in-Picture API (draggable to other screens). The overlay is now a slim fallback only when native PiP isn't supported. Fullscreen button removed.
- **YouTube playlist controls** — next, previous, and shuffle now work for YouTube playlists. The embed URL preserves the `list=` parameter so the IFrame API has playlist context. Controls are hidden for single videos (where they had no effect).
- **YouTube auto-advance** — when a video ends in a playlist, the next one plays automatically instead of showing end-screen suggestions that open new tabs.
- **Bot "Updated" toast was red** — server was emitting via the error channel. Now uses a dedicated `bot-updated` event with green success styling.
- **Toast hidden behind modals** — toast container z-index raised above modals so notifications are always visible.
- **Bot channel dropdown unordered** — channels now appear in server order with sub-channels indented under their parents.
- **Uncategorized DMs not collapsible** — the Uncategorized section now collapses/expands on click with state saved to localStorage, matching tagged DM categories.
- **HTTPS redirect hardcoded to localhost** — remote users hitting the HTTP port were redirected to `https://localhost` instead of the actual server host.
- **Duplicate avatar upload route** — two `/api/upload-avatar` handlers were registered; the first lacked the 2 MB size check. Removed the duplicate, added the size check to the primary handler.
- **Duplicate `get-webhooks` socket handler** — global and per-channel handlers both fired for every event. Added a guard so each only handles its own scope.
- **E2E safety number only 30 digits** — verification codes were half the documented length due to SHA-256 producing only 32 bytes. Switched to SHA-512 (64 bytes) for the full 60-digit output.
- **YouTube playlist flag not reset for Spotify** — sharing a Spotify link after a YouTube playlist left stale state, incorrectly showing track controls for Spotify.

### Added
- **Release tarball with fixed directory name** — GitHub Actions workflow now attaches a `haven.tar.gz` to each release that always extracts to `haven/` (no version in the path), so headless server users don't need to rename or update systemd paths on every update.

---

## [1.8.1] — 2026-02-16

### Fixed
- **Max upload size not applying client-side** — the drag-and-drop / file upload was hardcoded to reject files over 25 MB regardless of the admin setting. Now reads the server-configurable limit.
- **Message timestamp shift** — hovering over a compact (grouped) message no longer pushes the text rightward. Timestamp now uses `visibility` instead of `display` so it occupies space at all times.
- **Dual-role display** — users with Channel Mod + User roles no longer show both badges; the lower "User" badge is stripped when a higher role exists.
- **Mobile messages not updating** — when the app returns to foreground (tab becomes visible), messages, channel list, and member list are now re-fetched automatically. Socket reconnects if disconnected.
- **Mobile menu buttons not appearing** — foreground resume now triggers channel/data refresh which re-initializes the UI state.

### Changed
- **Mute/Deafen icons** — mic mute button now shows a microphone icon (🎙️) with a red strikethrough when muted. Deafen button shows a speaker icon (🔊/🔇). Previously both used speaker icons which was confusing.
- **Flash games are now optional** — SWF ROM files (~37 MB) are no longer shipped with Haven. The Activities panel shows a "Download Flash Games" button that fetches them on demand (admin only). Haven itself stays under 5 MB.
- **Carousel interval** — website hero image carousel slowed from 2s to 4s and uses fixed aspect ratio to prevent page jumping.

### Added
- **E2E verification codes** — DM channels now show a button in the header that displays a 60-digit safety number. Both users see the same code and can compare out-of-band to verify no one is intercepting their encrypted messages (like Signal).
- **E2E per-account key sync** — private keys are now wrapped with the user's password (PBKDF2, 600k iterations) and stored encrypted on the server. Keys sync across devices automatically on login.
- **Flash ROM download system** — server endpoints `/api/flash-rom-status` and `/api/install-flash-roms` allow checking and downloading Flash game ROMs on demand.
- **Win95 theme: beveled buttons** — all voice, sidebar, modal, and toolbar buttons now have proper 3D outset/inset borders in the Win95 theme.
- **Win95 scrollbar fix** — eliminated double arrow boxes on scrollbars by hiding Chrome's extra scrollbar-button pseudo-elements.
- **Ruffle Flash CSP fix** — added `wasm-unsafe-eval` and `unpkg.com` worker-src to Content Security Policy headers so Ruffle WASM can load.
- **Website updates** — new screenshots, E2E encryption in feature cards and comparison table, expanded games card, updated file sharing limit (configurable up to 1.5 GB).

---

## [1.8.0] — 2026-02-16

### Added
- **End-to-end encrypted DMs** — DM messages are now encrypted client-side using ECDH P-256 + AES-256-GCM. Private keys never leave the browser (stored with `extractable: false` in IndexedDB). Not even the server host can read DM content. Encrypted messages display a lock icon (🔒) on root messages. Editing a DM re-encrypts the content. Falls back to unencrypted if either party hasn't generated keys yet.
- **Server-wide invite code** — admins can generate a single code that grants access to every channel and sub-channel in the server at once. Generate, copy, and clear from Admin Settings.
- **Channel organize modal** — parent channels can now be reordered, categorized, and sorted just like sub-channels. New "Organize" button in the Channels sidebar header (admin-only).
- **Cloudflare Tunnel documentation** — comprehensive setup guide in GUIDE.md covering installation, configuration, and troubleshooting.
- **`/gif` slash command** — type `/gif <query>` to search GIPHY inline and send a GIF directly from the message bar. Results appear in a floating picker grid above the input; click any GIF to send it.
- **Music player seek bar** — YouTube and SoundCloud players now show a draggable seek slider with current/total time display. Spotify hides the seek bar (no embeddable API).
- **Configurable max upload size** — admins can set the per-file upload limit (1–500 MB) from Admin Settings. Default remains 25 MB. Enforced server-side per-request.
- **Flash games via Ruffle** — 5 classic Flash games (Flight, Learn to Fly 3, Bubble Tanks 3, Tanks, Super Smash Flash 2) playable in-browser via the Ruffle Flash emulator.
- **.io Games browser** — browse and play popular .io multiplayer games from the Activities panel.

### Changed
- **Win95 theme polish** — scrollbars now display proper beveled 3D rectangles with outset/inset borders. Channel header uses the classic blue gradient. Sliders use rectangular gray thumbs with outset borders and sunken tracks. Text turns white on navy-background hover/active states.
- **CRT theme / effect separation** — selecting the CRT theme now only applies the amber color scheme and VT323 font. The CRT scanline + vignette effect is a separate opt-in from the Effects panel, no longer auto-applied.
- **E2E lock icon consistency** — lock badge now appears once on root messages only (right-aligned in the header), not on every compact/grouped message.
- **SQLite performance pragmas** — added `synchronous = NORMAL`, `cache_size = -64000` (64 MB), `busy_timeout = 5000`, `temp_store = MEMORY` for significantly faster writes and reduced lock contention.

### Fixed
- **User status stuck on idle** — fixed race condition where the idle timer's server emit was async but the local status wasn't updated immediately, causing activity events to not restore "online" status.
- **YouTube embeds "Video unavailable"** — switched from `youtube-nocookie.com` to `youtube.com/embed/` with explicit `origin=` parameter and removed `referrerpolicy="no-referrer"`, which was blocking IFrame API communication.
- **Push notification "Registration failed"** — improved error messages with actionable guidance: use Cloudflare Tunnel, access via localhost, or install a real SSL certificate. Added self-signed certificate detection heuristic.
- **Sub-channel membership grandfathering** — joining a parent channel now auto-adds members to existing sub-channels.
- **Duplicate channel roles** — fixed de-duplication in role assignment and profile queries.
- **Cloudflare tunnel URL timeout** — increased detection timeout and tightened regex to exclude false positives.
- **Game iframe CSP** — added `'self'` to `frame-src` directive; extracted inline scripts to external JS files to comply with CSP.

---

## [1.7.0] — 2026-02-16

### Added
- **Role inheritance / cascading** — server-scoped roles now automatically apply in every channel and sub-channel. Channel-scoped roles cascade to all sub-channels beneath them. Sub-channel roles remain limited to that sub-channel only.
- **Voice dot role color** — the online dot next to users in a voice channel now matches their highest role color instead of always being green.

### Fixed
- **Transfer Admin modal** — completely redesigned with a proper warning box, clearer layout, and inline error styling.
- **Noise-suppression slider invisible track** — the slider track is now thicker (6 px) with a visible border, and the thumb enlarged to 14 px so it's easy to grab.
- **User hover tooltip translucency** — tooltip popup now uses an opaque background (`--bg-secondary`) with a solid box-shadow instead of blending into the page.

---

## [1.6.0] — 2026-02-15

### Added
- **19-permission role system** — fine-grained permissions for server and channel roles (send messages, manage channels, kick/ban, pin, upload files, etc.).
- **Channel Roles panel** — per-channel role management with create / edit / delete / assign UI.
- **Default "User" role** — every new server automatically seeds a level-1 User role so members always have baseline permissions.
- **Server icon upload** — admins can upload a custom server icon displayed in the header.
- **Admin transfer** — server owners can transfer full admin rights to another user (password-verified).
- **Promotion permission** — a dedicated `promote_members` permission controlling who can assign roles.
- **Level-based thresholds** — users can only assign/edit roles whose level is strictly below their own.
- **Auto-assign roles** — roles marked auto-assign are automatically granted to users when they join a channel.
- **Voice controls in right sidebar** — mute / deafen / noise-suppression / leave moved into a persistent sidebar panel at the bottom.
- **Per-user volume control** — right-click a voice user for an individual volume slider.
- **Header voice indicator** — a compact voice badge in the header shows your current voice channel and lets you leave.
- **CRT scan-line theme effect** — optional retro CRT overlay toggled from the theme menu.

### Fixed
- **Idle status** — idle detection now works correctly across all tabs.
- **Role dropdown clipping** — dropdowns in the Channel Roles panel no longer clip behind other elements.
- **Mobile sidebar** — improved touch handling and layout on small screens.
- **Settings z-index** — settings modal no longer appears behind other overlays.
- **Voice banner position** — the "you are in voice" banner no longer overlaps content.
- **Admin self-nerf prevention** — admins cannot demote or remove their own admin role.
- **Noise-suppression slider** — value now persists correctly across reconnects.

---

## [1.5.0] — 2026-02-14

### Added
- **Private sub-channels** — when creating a sub-channel, a Private checkbox is available. Private sub-channels only add the creator as initial member (not all parent members) and show a lock icon in the sidebar. Only users with the code can join.
- **Auto-join sub-channels** — when a user joins a parent channel, they're now automatically added to all non-private sub-channels of that parent. Previously, only users present at sub-channel creation were added.
- **Create sub-channel modal** — replaced the basic browser `prompt()` with a proper modal dialog that includes a name field and private checkbox.
- **Avatar system overhaul** — profile pictures now upload via HTTP (`/api/upload-avatar`) instead of Socket.io, fixing the silent disconnect caused by base64 data URLs exceeding Socket.io's 64KB buffer limit. Avatar shapes (circle, square, hexagon, diamond) are now stored per-user in the database and visible to all users in messages.
- **Avatar Save button** — avatar changes now require explicit save instead of auto-saving, preventing accidental changes.
- **Cyberpunk text scramble effect** — replaced the old CSS glitch animation with a JS-powered text scramble that randomly cycles text through random characters before resolving. Affects the HAVEN logo, channel names, section labels, usernames, and the channel header.
- **Glitch frequency slider** — configurable scramble frequency when the cyberpunk effect is active. Saved to localStorage.
- **Expanded scramble targets** — the text scramble effect now hits sidebar text, channel headers, user names, and section labels (not just the logo).

### Fixed
- **Channel code settings gear icon never appearing** — `this.isAdmin` was used in 3 places but never defined; should have been `this.user.isAdmin`. The gear icon next to channel codes now correctly appears for admins.
- **`_setupStatusPicker` crash** — `insertBefore` was called on the wrong parent node, causing `Uncaught NotFoundError`. Fixed to use `currentUser.parentNode`.
- **Messages breaking after avatar save** — root cause was Socket.io's `maxHttpBufferSize: 64KB` silently killing the connection when large base64 avatars were sent. Moved avatar upload to HTTP.
- **Avatar resetting on reload** — avatars are now persisted server-side via HTTP upload and reloaded from the database on reconnect.
- **Avatar shape affecting all users** — shapes were previously a local-only preference. Now stored in the `users` table and sent per-message so each user's chosen shape is visible to everyone.

### Changed
- **`is_private` column** added to `channels` table (migration auto-runs on startup).
- **`avatar_shape` column** added to `users` table.
- Version bumped to 1.5.0.
- Updated README features table, roadmap, and GUIDE with comprehensive documentation on channels, sub-channels, join codes, avatars, and effects.

---

## [1.4.7] — 2026-02-13

### Fixed
- **YouTube "Video unavailable" for host** — the browser was sending a `Referer` header containing the page's localhost / private-IP origin, which YouTube blocks. Added `referrerpolicy="no-referrer"` to YouTube iframes so no referrer is sent.
- **No time bar on YouTube music player** — the transparent overlay that blocked direct clicks on the embed has been removed for YouTube (was already removed for Spotify). Users can now interact with YouTube's native seek bar, progress indicator, and controls directly.
- **YouTube play/pause desync** — added an `onStateChange` handler to the YouTube iframe API so Haven's play/pause button stays in sync when users interact with YouTube's native controls.
- **Profile picture upload silently failing** — the `<label for="…">` pattern was unreliable in some browser / modal contexts. Added explicit JS click handlers (with `preventDefault`) as a bulletproof fallback for both the Settings and Edit Profile avatar upload buttons.
- **Gray wasted space in stream area** — when all stream tiles were hidden, the stream container (with its 180 px min-height and black background) remained visible. Now it collapses automatically when no visible tiles remain, while the "streams hidden" restore bar stays in the header.

### Added
- **Late joiner screen share support** — users who join a voice channel after someone has started screen sharing now receive the stream automatically. The server tracks active screen sharers per voice room and triggers WebRTC renegotiation so late joiners get the video tracks.

### Changed
- Version bumped to 1.4.7.

---

## [1.4.6] — 2026-02-13

### Fixed
- **Voice panel empty on channel switch** — switching to a DM and back no longer shows an empty voice user list. The client now requests the voice roster whenever changing channels.
- **Spotify embed unresponsive** — removed the click-blocking overlay that prevented all interaction with the Spotify player. Spotify embeds now allow direct click-through for play, pause, and song selection.
- **Spotify not playing for other users** — added `autoplay=1` parameter to the Spotify embed URL so playback starts automatically for all voice participants, not just the sharer.
- **Spotify play/pause destroying embed** — Haven's play button no longer blanks the iframe and reloads it. Spotify pause now stores the src for clean resume.
- **Profile picture upload broken** — the avatar upload `<label>` already triggered the file input natively via its `for` attribute; a redundant JS `.click()` call was causing a double-open that silently broke the `change` event. Removed the duplicate handler.
- **Stream viewer cut off on start** — streams now auto-apply the saved size on first display so they don't start at an inconsistent height.
- **Stream size slider jerky / hard to drag** — replaced raw per-frame DOM style updates with debounced resizing. The slider is now wider with a visible track bar, labeled, and drags smoothly.
- **Changelog dates from the future** — corrected twelve changelog entries that had dates of Feb 14–16 (future) or 2025 (wrong year). All dates now reflect their actual release day.

### Added
- **PiP opacity slider** — music player and stream pop-out windows now have an opacity slider (20–100%) so you can see through them while gaming or browsing. Preference is saved to localStorage.
- **Spotify volume disclaimer** — when Spotify is the active music source, the Haven volume slider shows a tooltip indicating volume must be controlled within the Spotify embed (no external API available).

### Changed
- **Stream pop-out is now in-page** — stream windows pop out as draggable floating overlays (like the music PiP) instead of new browser windows, enabling opacity control and eliminating pop-up blocker issues.
- Version bumped to 1.4.6.

---

## [1.4.5] — 2026-02-12

### Fixed
- **SSL_ERROR_RX_RECORD_TOO_LONG on Windows** — `Start Haven.bat` always opened the browser with `https://` even when the server was running in HTTP mode (no valid SSL certs). The batch file now detects the actual protocol and opens the correct URL. ([#2](https://github.com/ancsemi/Haven/issues/2))
- **Unreliable OpenSSL detection in Start Haven.bat** — the `%ERRORLEVEL%` check inside a parenthesized `if` block was evaluated at parse time (classic cmd.exe bug), so the batch file could report "SSL certificate generated" even when OpenSSL wasn't installed. Replaced with `if errorlevel 1` (runtime-safe) and added a file-existence check after generation.

### Improved
- **Troubleshooting docs** — added SSL/HTTPS troubleshooting to both README and GUIDE, covering the `SSL_ERROR_RX_RECORD_TOO_LONG` error, how to tell if you're running HTTP vs HTTPS, and how to install OpenSSL on Windows.

---

## [1.4.4] — 2026-02-12

### Added
- **User profile pictures (PFP)** — users can upload a custom avatar (max 2 MB) via Settings. Avatars appear in chat messages and the online-users list. Letter-based fallback when no avatar is set.
- **Avatar upload endpoint** — `POST /api/upload-avatar` with magic-byte validation for PNG/JPEG/GIF/WebP.
- **Socket-based avatar sync** — `set-avatar` event propagates avatar changes to all connected clients in real-time; online-user lists update immediately.
- **Modernized emoji picker** — expanded from ~300 to ~500+ emojis across 10 categories. New "Monkeys" category (🙈🙉🙊🐵🐒🦍🦧), new "Faces" category (👀👁️👅💋🧠🦷🦴). Smileys expanded with 🫣🫢🫥🫤🥹🥲🫠🤫🤥🫨🤠🤑🤓🥴🤧😷🤒🤕. People expanded with pointing gestures, shrug/facepalm, bowing, and couple emojis. Animals, Food, Travel, Objects, and Symbols categories all substantially expanded.
- **AIM Classic notification sounds** — four synthesized approximations of the original AOL Instant Messenger sounds:
  - **AIM Message** — the iconic rising two-tone "ding ding" with overtone shimmer
  - **AIM Door Open** — ascending creaky chime (buddy sign-on)
  - **AIM Door Close** — descending thump with low slam (buddy sign-off)
  - **AIM Nudge** — buzzy sawtooth vibration pattern
- **Join/Leave sound selectors** — new "User Joined" and "User Left" dropdowns in Settings > Sounds, with AIM Door Open/Close as built-in options.
- **Admin custom sound uploads** — admins can upload custom notification audio files (max 1 MB, MP3/OGG/WAV/WebM) via Settings > Admin > Custom Sounds. Custom sounds appear as options in all notification dropdowns.
- **Custom sound management** — preview and delete buttons for each uploaded sound. Sounds stored in `custom_sounds` database table with file-on-disk storage.
- **Audio file playback engine** — `NotificationManager` gains `_playFile(url)` method with `Audio` object caching for efficient custom sound playback.

### Changed
- **Emoji categories restructured** — reorganized into 10 categories (was 8): Smileys, People, Monkeys, Animals, Faces, Food, Activities, Travel, Objects, Symbols.
- **Message avatar rendering** — messages now render `<img>` tags for users with profile pictures, with automatic fallback to letter-avatar on load error.
- **Online-users list** — each user entry now shows a small avatar circle (24px) before the username.
- **CSP mediaSrc** — added `"data:"` to Content Security Policy for audio data URI support.

---

## [1.4.3] — 2026-02-12

### Added
- **Comprehensive Terms of Service & EULA v2.0** — rewrote the 8-clause Release of Liability into a full 12-section Terms of Service, End User License Agreement & Release of Liability covering: age restriction & eligibility, service description, no warranty, assumption of risk, release of liability & limitation of damages, indemnification, user conduct & content, data handling & privacy, intellectual property, dispute resolution & governing law (with 1-year limitation period, class action waiver), termination (with survival of key sections), and general provisions (severability, waiver, modification, assignment).
- **18+ age verification gate** — users must check a separate age-confirmation checkbox ("I confirm that I am 18 years of age or older") before login or registration. The server enforces `ageVerified: true` on both `/api/auth/login` and `/api/auth/register` and rejects requests without it.
- **Age attestation stored in database** — `eula_acceptances` table gains an `age_verified` column; every login/register records whether the user attested to being 18+.
- **Dual-checkbox validation** — client requires both age-checkbox and EULA-checkbox to be checked before allowing auth. Clicking "I Accept" in the EULA modal checks both; "Decline" unchecks both.
- **LICENSE updated** — added Section 4 (Age Restriction) and Section 5 (Indemnification) to the MIT-NC license.

### Changed
- **EULA version bumped to 2.0** — all existing users must re-accept the new terms on next login (localStorage key now checks for `'2.0'`).
- **EULA modal widened** — `max-width` increased from 600 px to 700 px for readability of the longer agreement.
- **CSS** — added `h4` heading styles and `ul` bullet-list styles inside `.eula-content` for the new sections, plus spacing between stacked checkboxes.

---

## [1.4.2] — 2026-02-12

### Fixed
- **Admin status & display name lost on reconnect** — the socket auth middleware now refreshes both `is_admin` and `display_name` from the database on every connection, instead of trusting the JWT payload which could be stale. Additionally, admin status is synced from `.env ADMIN_USERNAME` on every socket connect (not just login), so `.env` changes take effect without requiring a re-login.
- **Server pushes authoritative user info on connect** — a new `session-info` event fires on every socket connect/reconnect, overwriting the client's `localStorage` with the server's truth (id, username, isAdmin, displayName). This prevents stale or corrupted local data from hiding the display name or admin controls.

---

## [1.4.1] — 2026-02-12

### Added
- **Independent voice & text channels** — voice and text are now fully decoupled, matching Discord's model. You can be in voice on one channel while reading/typing in another. Voice persists across text channel switches. The server uses dedicated `voice:<code>` socket.io rooms so voice signaling and updates reach participants regardless of which text channel they're viewing.
- **Sidebar voice indicators** — channels with active voice users show a count badge in the left sidebar, so you can see at a glance where people are talking without clicking into each channel.
- **Roadmap section in README** — planned features (webhooks/bots, permission levels, threads, file sharing, E2EE) are now listed in a roadmap table.

### Fixed
- **Mobile input field sizing** — shortened placeholder to "Message..." on narrow screens, reduced button sizes from 40 px to 34 px, tightened padding, and lowered the auto-resize cap to 90 px. The input no longer starts too small or jumps to an awkward height on tap.
- **Mobile header voice overflow** — voice controls no longer wrap to a second line and get cut off. Removed `flex-wrap`, compacted button labels ("🎤▾" instead of "Voice ▾" on ≤ 768 px), and allowed the controls container to shrink.
- **Voice updates reaching wrong clients** — `broadcastVoiceUsers` previously emitted only to the text-channel room (`channel:<code>`), so users in voice who had switched text channels missed updates. It now emits to both `voice:<code>` and `channel:<code>`.

---

## [1.4.0] — 2026-02-12

### Added
- **Display name ≠ login name** — users now have a separate display name that is shown everywhere (messages, voice, leaderboards, online list). The login username is set at registration and never changes, so nobody forgets their credentials. Display names allow spaces, don't need to be unique, and can be changed at will via the button. The immutable login name is shown as a small `@username` subtitle in the sidebar.
- **Mobile voice join** — "Join Voice" button added to the right-sidebar users panel, accessible on phones where the header voice button is hidden.

### Fixed
- **Mobile viewport — message input visible** — switched from `100vh` (which doesn't account for browser chrome) to `100dvh` (dynamic viewport height). The text input no longer hides behind the phone's URL bar.
- **Mobile header decluttered** — delete, search, pin, and copy-code buttons are now hidden on screens ≤ 768 px. Features are still accessible via long-press or sidebar.
- **GIF picker branding** — corrected "Search Tenor…" / "Powered by Tenor" to "Search GIPHY…" / "Powered by GIPHY" to match the actual API in use.
- **Mobile toolbar tap-to-reveal at 768 px** — the message action toolbar (react, reply, pin, edit, delete) now hides/shows on tap across all mobile breakpoints, not just ≤ 480 px.

### Improved
- **Status bar hidden on mobile** — the ping / server / encryption status bar is suppressed on phones to reclaim vertical space.

---

## [1.3.9] — 2026-02-12

### Fixed
- **Slash commands working after every deploy** — static file caching dropped from 1 h to always-revalidate (ETag). Previously, browsers could serve stale JS for up to an hour after a server restart, causing commands and other new features to appear broken.

### Improved
- **Mobile message actions — tap to reveal** — react, reply, pin, edit, and delete buttons are now hidden until you tap a message, drastically reducing clutter on phone screens. Tap another message to move the toolbar; tap empty space or the input to dismiss.

---

## [1.3.8] — 2026-02-12

### Fixed
- **Leaderboard scoring now persists** — removed `noopener` from the Shippy Container popup so `postMessage` score submissions actually reach the main app. Scores are saved correctly again.
- **Dracula theme darkened** — replaced grey background values with much darker tones so the theme lives up to its name.

### Added
- **In-game leaderboard** — the Shippy Container game now shows a live leaderboard panel beside the canvas, updated on launch and after every run. The old sidebar leaderboard button and modal are removed.
- **High-score announcements** — when a player beats their personal best, a status toast is broadcast to the channel.
- **Voice controls dropdown** — mute, deafen, screen share, and noise suppression are tucked behind a single "Voice ▾" button; a compact "✕" leave button stays visible. Keeps the header clean.
- **5 new themes** — Dark Souls 🔥, Elden Ring 💍, Minecraft ⛏️, Final Fantasy X ⚔️, and Legend of Zelda join the theme picker.
- **Themed slider fills** — all range sliders (volume, noise suppression, stream size) now fill their left portion with accent-colored gradients and glow effects that match the active theme.

---

## [1.3.7] — 2026-02-12

### Fixed
- **Voice leave audio cue** — leaving voice chat now plays the descending tone (matching the cue other users already heard) so you get audible confirmation.
- **Stream ghost tiles cleaned up on leave** — all screen-share tiles are properly destroyed when leaving voice. Previously, tiles persisted with dead video sources and showed black screens when restored.

### Added
- **"Left voice chat" toast** — a brief info toast confirms you disconnected, mirroring the existing "Joined voice chat" toast.
- **Escape closes all modals** — pressing Escape now dismisses every open modal overlay (settings, bans, leaderboard, add-server) in addition to the search and theme panels it already handled.

---

## [1.3.6] — 2026-02-12

### Fixed
- **Noise suppression default lowered to 10%** — 50% was too aggressive for most microphones; new users now start at 10%.
- **RGB theme speed dramatically increased** — previous fastest setting is now the slowest. Uses fixed 16 ms tick with variable hue step (0.8°–4.0° per tick) for smooth, visible cycling.
- **Custom theme triangle now affects backgrounds** — triangle saturation is passed as the vibrancy parameter, so moving the picker visibly changes background tinting, not just accent highlights.
- **Switching to DMs no longer hides voice controls** — voice mute/deafen/leave buttons persist when in a call regardless of which channel is being viewed.
- **Stream "Hide" button removed** — per-tile close buttons are gone; the header minimize button keeps streams accessible and always allows restoring them.
- **Minimize no longer stops your own screen share** — minimizing the stream panel just hides the UI; your share continues broadcasting.

### Added
- **Stream size slider** — a range slider in the streams header adjusts the viewer height (20–90 vh), persisted to localStorage.
- **Theme popup menu** — themes moved from an inline sidebar section (that could scroll off-screen) to a floating popup panel pinned above the sidebar bottom bar. The bottom bar always shows theme/game/leaderboard buttons and the voice bar.

---

## [1.3.5] — 2026-02-12

### Changed
- **Noise suppression → sensitivity slider** — replaced the on/off NS toggle button with an adjustable slider (0–100). Sensitivity maps to the noise gate threshold (0 = off, 100 = aggressive gating). The slider sits inline in the voice controls when in a call.
- **Custom theme overhaul** — the triangle colour picker now dramatically affects the entire UI. Backgrounds, text, borders, links, glow effects, and even success/danger/warning colours are all derived from the chosen hue. The `vibrancy` parameter (used internally) controls how saturated the backgrounds and text become — the triangle’s saturation/value selection now produces visibly different themes instead of only tweaking subtle highlights.

### Added
- **RGB cycling theme** — new RGB button in the theme selector. Continuously shifts the entire UI through all hues like gaming RGB peripherals. Two sliders control **Speed** (how fast it cycles) and **Vibrancy** (how saturated/tinted the backgrounds and text become). Settings persist in localStorage.

---

## [1.3.4] — 2026-02-12

### Added
- **Noise suppression (noise gate)** — Web Audio noise gate silences background noise (keyboard, fans, breathing) before sending audio to peers. Runs at 20 ms polling with fast 15 ms attack / gentle 120 ms release. Toggle on/off with the NS button in voice controls (enabled by default).
- **Persistent voice across channels** — joining voice in one channel no longer disconnects when switching text channels. A pulsing green voice bar in the sidebar shows which channel you're connected to, with a quick-disconnect button. Voice controls dynamically show/hide based on whether the active text channel matches your voice channel.
- **Server leaderboard** — new Leaderboard button in the sidebar opens a modal showing the top 20 Shippy Container scores server-wide, complete with medal indicators for the top 3.

### Fixed
- **Shippy Container frame-rate physics** — game physics normalised to a 60 fps baseline using delta-time scaling. Players on 144 Hz (or any refresh rate) monitors now experience identical gravity, pipe speed, and spawn timing as 60 Hz players. Pipe spawning switched from frame-count based (every 90 frames) to time-based (every 1.5 s). Scale capped at 3× to prevent teleportation on tab-switch.

---

## [1.3.3] — 2026-02-12

### Fixed — Bug Fixes
- **Upload error handling** — both image and file upload handlers now check HTTP status before parsing JSON, giving users clear error messages instead of cryptic "Not Found" toasts.
- **Screen share X button** — clicking close now minimises the screen-share container instead of destroying all streams. A pulsing indicator button appears in the channel header so you can bring the view back. New incoming streams auto-restore the container.
- **Online users visibility** — users are now visible across all channels as soon as they connect, not only in the specific channel they are currently viewing. Disconnect events broadcast to all active channels.
- **DM button feedback** — clicking now shows a toast ("Opening DM with …"), disables the button during the request, scrolls the sidebar to the newly-opened DM channel, and re-enables after a timeout fallback.

### Changed
- **Tenor → GIPHY migration** — GIF search backend and client switched from Tenor (Google) to GIPHY. New admin setup guide, server proxy endpoints, and response parsing. All `media.tenor.com` URL patterns updated to `media*.giphy.com`. README updated with simpler GIPHY key setup instructions.

### Added
- **Custom theme with triangle picker** — new "Custom" button in the theme selector. Opens an inline HSV triangle colour picker (canvas-based hue bar + SV triangle) that live-generates a full theme palette from a single accent colour. Custom HSV values persist in localStorage and apply instantly on page load (no flash).

---

## [1.3.2] — 2026-02-12

### Fixed — Security Hardening II
- **Upload serving headers** — non-image uploads now served with `Content-Disposition: attachment`, preventing HTML/SVG files from executing in the browser when accessed directly.
- **Image magic-byte validation** — uploaded images are verified by reading file header bytes (JPEG `FF D8 FF`, PNG `89 50 4E 47`, GIF `GIF8x`, WebP `RIFF…WEBP`), not just MIME type. Spoofed files are rejected and deleted.
- **CSP tightened** — removed `ws:` from `connect-src`, allowing only `wss:` (encrypted WebSocket connections).
- **Inline event handler removed** — link preview `onerror` attribute replaced with delegated JS listener, eliminating a CSP `unsafe-inline` bypass vector.
- **Password minimum raised** — registration now requires 8+ characters (was 6).
- **Account enumeration mitigated** — registration endpoint no longer reveals whether a username is already taken.

### Added — Quality of Life
- **Password change from settings** — new Password section in the settings modal lets users change their password (current → new → confirm) without logging out. Backend `POST /api/auth/change-password` issues a fresh JWT on success.
- **Emoji picker upgrade** — categorized tabs (Smileys, People, Animals, Food, Activities, Travel, Objects, Symbols), search bar, scrollable grid with 280+ emojis. Replaces the old flat 40-emoji palette.
- **`/butt` slash command** — `( . )( . )` — companion to `/boobs`.

---

## [1.3.1] — 2026-02-12

### Fixed — Security Hardening
- **GIF endpoints now require authentication** — `/api/gif/search` and `/api/gif/trending` were previously unauthenticated, allowing anyone to probe the server and burn Tenor API quota. Now require a valid JWT.
- **GIF endpoint rate limiting** — new per-IP rate limiter (30 req/min) prevents abuse.
- **Version fingerprint removed** — `/api/health` no longer exposes the Haven version number to the public internet.
- **HTTP redirect server (port 3001) hardened** — added rate limiting, `x-powered-by` disabled, header/request timeouts, and replaced open redirect (`req.hostname`) with fixed `localhost` redirect target.
- **DNS rebinding SSRF protection** — link preview endpoint now resolves DNS and checks the resulting IP against private ranges, defeating rebinding attacks where `attacker.com` resolves to `127.0.0.1`.
- **Link preview rate limiting** — new per-IP rate limiter (30 req/min) prevents abuse of the outbound HTTP fetcher.
- **HSTS header** — forces browsers to use HTTPS for 1 year after first visit, preventing protocol downgrade attacks.
- **Permissions-Policy header** — explicitly denies camera, geolocation, and payment APIs to the page.
- **Referrer-Policy header** — `strict-origin-when-cross-origin` prevents full URL leakage in referrer headers.
- **X-Content-Type-Options** — `nosniff` header prevents MIME-type sniffing on uploaded files.
- **Server request timeouts** — headersTimeout (15s), requestTimeout (30s), keepAliveTimeout (65s), and absolute socket timeout (120s) to prevent Slowloris-style attacks.

---

## [1.3.0] — 2026-02-12

### Added — Direct Messages
- **Private 1-on-1 conversations** — click on any user in the member list to open a DM.
- DMs appear in a separate "Direct Messages" section in the sidebar.
- If a DM already exists with that user, it reopens instead of creating a duplicate.
- Both users are notified in real-time when a DM is created.

### Added — User Status
- **4 status modes** — Online (green), Away (yellow), Do Not Disturb (red), Invisible (grey).
- **Custom status text** — set a short message (up to 128 chars) visible in the member list.
- **Status picker** — click the status dot next to your username in the sidebar.
- **Auto-away** — automatically switches to Away after 5 minutes of inactivity; returns to Online on activity.
- **Persisted in database** — status survives reconnects and page refreshes.

### Added — Channel Topics
- **Admin-settable topic** — thin topic bar below the channel header with the channel's description.
- Click the topic bar to edit (admin-only). Non-admins see the topic as read-only.
- Topics are stored in the database and broadcast to all channel members on change.

### Added — General File Sharing
- **Upload files up to 25 MB** — PDFs, documents (Word/Excel/PowerPoint), audio (MP3/OGG/WAV), video (MP4/WebM), archives (ZIP/7z/RAR), text, CSV, JSON, Markdown.
- **File attachment cards** — styled download cards with file type icons, names, sizes, and download buttons.
- **Inline audio/video players** — audio and video files render with native HTML5 players directly in chat.
- **Separate upload endpoint** — `/api/upload-file` with expanded MIME whitelist and 25 MB limit.

### Added — Persistent Read State
- **Server-tracked unread counts** — `read_positions` table tracks the last-read message per user per channel.
- Unread badges now survive page refreshes, reconnects, and browser restarts.
- Mark-read is debounced (500 ms) and fires on message load and new message receipt.
- Channels list includes accurate unread counts from the server on load.

### Changed — Database
- New `read_positions` table for persistent unread tracking.
- New columns on `users`: `status`, `status_text`.
- New columns on `channels`: `topic`, `is_dm`.
- New column on `messages`: `original_name` (for file upload metadata).
- All migrations are safe — existing databases upgrade automatically.

### Changed
- Version bumped to 1.3.0.
- Member list now shows status dots (colored by status) and custom status text.
- Member list includes a DM button (💬) on each user for quick DM access.
- Channel list split into regular channels and DM section.
- `get-channels` now returns topic, is_dm, dm_target, and server-computed unread counts.
- `emitOnlineUsers` now includes user status and status text in the payload.

---

## [1.2.0] — 2026-02-12

### Added — Voice UX
- **Join / leave audio cues** — synthesized tones play when users enter or leave voice chat.
- **Talking indicators** — usernames glow green while speaking, with 300 ms hysteresis for smooth animation.
- **Multi-stream screen sharing** — multiple users can share screens simultaneously in a CSS Grid tiled layout with per-user video tiles, labels, and close buttons.

### Added — Message Pinning
- **Pin / unpin messages** (admin-only) — pin button in message hover toolbar.
- **Pinned messages panel** — sidebar panel listing all pinned messages in a channel with jump-to-message.
- **50-pin cap per channel** to prevent abuse.
- **Database-backed** — new `pinned_messages` table with foreign keys; pins survive restarts.

### Added — Enhanced Markdown
- **Fenced code blocks** — triple-backtick blocks with optional language labels render with styled monospace containers.
- **Blockquotes** — lines starting with `>` render with left-border accent styling.

### Added — Link Previews
- **Automatic OpenGraph previews** — shared URLs fetch title, description, and thumbnail server-side.
- **30-minute cache** — previews are cached to avoid repeated fetches.
- **SSRF protection** — private/internal IPs are blocked from the preview fetcher.

### Added — GIF Search
- **Tenor-powered GIF picker** — search and send GIFs inline from the message input.
- **Admin-configurable API key** — Tenor API key can be set from the admin GIF picker UI with an inline setup guide.
- **Server-stored key** — API key saved in `server_settings` DB table (never exposed to non-admins).

### Fixed — Security
- **Admin username hijack via rename** — non-admin users can no longer claim the admin username through `/nick` or rename.
- **XSS via attribute injection** — `_escapeHtml` now escapes `"` and `'` characters, preventing injection through OG metadata or user content.
- **SSRF in link previews** — `/api/link-preview` now blocks requests to localhost, private ranges (10.x, 192.168.x, 172.16-31.x), link-local (169.254.169.254), and internal domains.
- **API key leak** — `get-server-settings` no longer sends sensitive keys (e.g. `tenor_api_key`) to non-admin users.
- **Cross-channel reaction removal** — `remove-reaction` now verifies the message belongs to the current channel.
- **Voice signaling without membership** — `voice-offer`, `voice-answer`, and `voice-ice-candidate` now verify the sender is in the voice room.
- **Typing indicator channel check** — typing events now verify the user is in the claimed channel.

### Fixed — Bugs
- **Voice audio broken** — eliminated duplicate `MediaStreamSource` creation; single source now splits to analyser and gain node.
- **Spotty talking indicator** — added 300 ms sustain hysteresis to prevent flicker during natural speech pauses.
- **Screen share invisible** — added SDP rollback for renegotiation glare, `event.streams[0]` for proper stream association, `track.onunmute`, and explicit `play()` on muted video tiles.
- **GIF send completely broken** — fixed wrong property names (`channelCode` → `code`, `this.replyTo` → `this.replyingTo`) that silently dropped every GIF message.
- **Reconnect dead channel** — socket reconnect now re-emits `enter-channel`, `get-messages`, `get-channel-members`, and other state-restoring events.
- **Screen share privacy leak** — closing the screen share viewer now actually stops the broadcast (calls `stopScreenShare()`) instead of just hiding the UI.
- **Auto-scroll failure** — `_scrollToBottom` after appending messages now uses the force flag to prevent large messages from blocking scroll.
- **Delete-user FK violation** — user deletion now cleans up `pinned_messages`, `high_scores`, `eula_acceptances`, and `user_preferences` to prevent foreign key errors.
- **Delete-channel incomplete** — channel deletion now explicitly removes associated pinned messages.
- **Delete-message incomplete** — message deletion now removes associated pinned message entries.
- **LIKE wildcard injection** — search-messages now escapes `%`, `_`, and `\` in search queries.

### Changed — Performance
- **N+1 query eliminated** — `get-messages` replaced 240 individual queries (for 80 messages) with 3 batch queries using `WHERE ... IN (...)` for reply context, reactions, and pin status.

### Changed
- `edit-message`, `delete-message`, `pin-message`, `unpin-message` DB operations wrapped in try/catch for graceful error handling.
- Version bumped to 1.2.0.

---

## [1.1.0] — 2026-02-11

### Data Isolation

All user data now lives **outside** the Haven code directory, making it physically impossible to accidentally commit or share personal data.

### Changed
- **Database, .env, certs, and uploads** are now stored in:
  - **Windows:** `%APPDATA%\Haven\`
  - **Linux / macOS:** `~/.haven/`
- **SSL certificates are auto-detected** — if certs exist in the data directory, HTTPS enables automatically without needing to edit `.env`.
- **Start Haven.bat** and **start.sh** generate certs and bootstrap `.env` in the external data directory.
- **Automatic one-time migration** — existing data in the old project-directory locations is moved to the new data directory on first launch.

### Added
- New `src/paths.js` module — single source of truth for all data directory paths.
- `HAVEN_DATA_DIR` environment variable — override where data is stored.

### Updated
- README.md, GUIDE.md, and .env.example updated to reflect new data locations.

---

## [1.0.0] — 2026-02-10

### First Public Release

Haven is now ready for public use. This release includes all features from the alpha series plus security hardening and polish for distribution.

### Added — Slash Command Autocomplete
- **Type `/`** and a Discord-style tooltip dropdown appears with all available commands.
- **Keyboard navigation** — Arrow keys to browse, Tab to select, Escape to dismiss.
- **Descriptions & argument hints** for every command.

### Added — New Slash Commands
- `/roll [NdN]` — Roll dice (e.g. `/roll 2d20`). Defaults to 1d6.
- `/flip` — Flip a coin (heads or tails).
- `/hug <@user>` — Send a hug.
- `/wave` — Wave at the chat.
- `/nick <name>` — Change your username.
- `/clear` — Clear your chat view (local only).

### Added — Message Search
- **Ctrl+F** or button opens a search bar in the channel header.
- Results panel with highlighted matches.
- Click a result to scroll to that message with a flash animation.

### Added — 6 New Themes
- **Cyberpunk** — Neon pink and electric yellow
- **Nord** — Arctic blue and frost
- **Dracula** — Deep purple and blood red
- **Bloodborne** — Gothic crimson and ash
- **Ice** — Pale blue and white
- **Abyss** — Deep ocean darkness

### Fixed — Security
- **Privilege escalation via rename** — Users can no longer gain admin by renaming to the admin username.
- **Upload extension bypass** — Server now forces file extensions based on validated MIME type.
- **Banned user upload bypass** — Banned users can no longer upload images via the REST API.
- **Upload rate limiting** — 10 uploads per minute per IP.
- **Spoiler CSP violation** — Spoiler click handler moved from inline to delegated (CSP-safe).
- **postMessage origin check** — Game score listener validates origin before accepting.
- **Event listener leak** — Game score listener registered once, not per button click.

### Changed
- Version bumped to 1.0.0 for public release.
- README rewritten as user-facing documentation.
- All personal data scrubbed from codebase.
- Added MIT LICENSE file.
- 12 themes total (6 new added to the original 6).

---

## [0.6.0-alpha] — 2026-02-10

### Added — Emoji Picker
- **Emoji button** in the message input bar — click to open a 40-emoji palette.
- **Insert at cursor** — emojis are inserted at the current cursor position, not appended.
- **Curated set** — 40 of the most useful emojis across smileys, gestures, objects, and symbols.

### Added — Message Reactions
- **Hover toolbar** — hover any message to see React and Reply ↩️ buttons.
- **Quick-pick palette** — click React to get a fast 8-emoji picker (👍👎😂❤️🔥💯😮😢).
- **Toggle reactions** — click an existing reaction badge to add/remove your own reaction.
- **"Own" highlight** — reactions you've placed are visually highlighted with accent color.
- **Persistent** — reactions stored in database (`reactions` table) and survive restarts.
- **Real-time sync** — all users in the channel see reactions update instantly.

### Added — @Mentions with Autocomplete
- **Type `@`** in the message input to trigger an autocomplete dropdown.
- **Live filtering** — as you type, the dropdown narrows to matching usernames.
- **Keyboard nav** — Arrow keys to navigate, Enter/Tab to select, Escape to dismiss.
- **Click to select** — click any suggestion to insert `@username` into your message.
- **Visual highlight** — `@mentions` render with accent-colored pill styling in chat.
- **Self-highlight** — mentions of your own username are extra-bold for visibility.
- **Channel-aware** — only members of the current channel appear in suggestions.

### Added — Reply to Messages
- **Reply button** — hover any message and click ↩️ to reply.
- **Reply bar** — preview bar appears above the input showing who/what you're replying to.
- **Cancel reply** — click on the reply bar to clear.
- **Reply context** — replied messages show a colored banner above them linking back to the original.
- **Threaded feel** — replies group visually with the parent message's author color.
- **Persistent** — `reply_to` column in messages table; reply context survives reloads.

### Changed — Database
- Added `reply_to` column to `messages` table (auto-migrated on existing databases).
- New `reactions` table with unique constraint per (message, user, emoji).
- Safe migration: existing databases are upgraded without data loss.

### Changed — Backend
- `get-messages` now returns reactions and reply context for each message.
- `send-message` accepts optional `replyTo` field.
- New socket events: `add-reaction`, `remove-reaction`, `get-channel-members`.
- `reactions-updated` broadcast to all channel members on any reaction change.
- `channel-members` event returns member list for @mention autocomplete.
- Emoji validation: only actual emoji characters accepted (regex unicode property check).

---

## [0.5.0-alpha] — 2026-02-10

### Added — Multi-Server Sidebar
- **Server bar** (far left) — Discord-style vertical strip showing all your Haven servers.
- **Live status lights** — Green (online), grey (offline), yellow (checking) status dots on each server icon.
- **Add/remove servers** — Modal dialog to add friends' Haven servers by name + URL.
- **Health check API** — `GET /api/health` returns server name, status, and version. CORS-enabled for cross-server pings.
- **One-click connect** — Click any server icon to open it in a new tab.
- **`ServerManager` class** (`servers.js`) — Client-side server list stored in `localStorage` with 30-second polling.

### Added — Image Sharing
- **Image upload** — Upload button in message input area. Max 5 MB (jpg, png, gif, webp).
- **Clipboard paste** — Paste images directly from clipboard into chat.
- **Drag & drop** — Drag image files onto the chat area to upload.
- **Inline rendering** — Uploaded images and image URLs render as clickable inline images in chat.
- **Server-side handling** — Multer middleware with random filenames, MIME type validation, size limits.
- **Upload authentication** — JWT token required for uploads.

### Added — Voice Volume Control
- **Per-user volume sliders** — Range inputs (0–200%) below each voice user in the panel.
- **Persistent settings** — Volume preferences saved in `localStorage` per user ID.
- **Auto-applied** — Saved volumes automatically applied when peers connect.
- **"you" tag** — Your own entry in voice shows a label instead of a slider.

### Added — Notification Tones
- **Web Audio API engine** — Zero-dependency synthesized notification sounds.
- **5 built-in tones** — Ping, Chime, Blip, Bell, Drop.
- **Configurable** — Choose which sound plays for messages (right sidebar panel).
- **Enable/disable toggle** — Master on/off switch for all notifications.
- **Volume slider** — Independent notification volume control.
- **Event triggers** — Sounds on new message (from others) and user join.

### Added — Cross-Platform Support
- **`start.sh`** — Linux/macOS launcher with: Node.js detection, auto dependency install, auto SSL cert generation, process management, clean shutdown on Ctrl+C, browser auto-open.
- **`.env.example`** — Template configuration file with full documentation.
- **`SERVER_NAME`** — New `.env` variable for naming your Haven instance.

### Fixed — Security
- **JWT timing bug** — `JWT_SECRET` auto-generation now runs *before* `auth.js` is loaded, fixing a race condition where the first boot used a different secret than subsequent boots.
- **JWT fallback removed** — `auth.js` no longer has a hardcoded fallback secret. If `JWT_SECRET` is missing, the server exits with a clear error.
- **Channel membership enforcement** — `enter-channel` and `voice-join` now verify the user is actually a member before granting access.
- **Atomic channel deletion** — `delete-channel` now wrapped in a SQLite transaction for data integrity.

### Changed
- **`server.js`** — Restructured require order (JWT auto-gen before auth load), added multer, health endpoint, upload endpoint, SERVER_NAME in banner.
- **`package.json`** — Version bumped to 0.5.0, added multer dependency.
- **`public/app.html`** — Added server bar, image upload button, file input, notification settings panel, add-server modal.
- **`public/js/app.js`** — Full rewrite with ServerManager, NotificationManager, image upload/paste/drag-drop, volume sliders, server bar rendering.
- **`public/js/voice.js`** — Added `setVolume()`, `_getSavedVolume()` methods, auto-apply saved volume on stream play.
- **`public/css/style.css`** — Added 7 new CSS sections: server bar, modal, chat images, upload button, volume sliders, notification settings, drag-over state.
- **`.gitignore`** — Added `public/uploads/*`, `haven.db-shm`, `haven.db-wal`.
- **`Start Haven.bat`** — Made generic (no hardcoded IP), increased startup timeout.
- **`README.md`** — Full rewrite with updated features, cross-platform install, expanded roadmap.

---

## [0.4.0-alpha] — 2026-02-10

### Added — Security Hardening
- **Helmet security headers** — CSP, X-Content-Type-Options, X-Frame-Options, HSTS, no X-Powered-By.
- **API rate limiting** — 20 requests per 15 minutes per IP on auth endpoints.
- **Socket connection rate limiting** — Max 15 connections per minute per IP.
- **Socket event flood protection** — Per-connection: max 60 events/10s, max 10 messages/10s.
- **Input validation on all socket events** — Type checks, string length bounds, regex for channel codes, integer checks.
- **Body size limits** — Express JSON parsing capped at 16KB.
- **Static file hardening** — `dotfiles: 'deny'`.
- **CORS lockdown** — Socket.IO CORS set to `origin: false`.
- **Auto-generated JWT secret** — 48-byte random secret on first run.
- **Safe URL regex (client)** — Tightened URL matching, `nofollow`, URL constructor validation.
- **User Guide** — `GUIDE.md` created.

---

## [0.3.0-alpha] — 2026-02-10

### Added
- **HTTPS / SSL support** — Self-signed certificate, auto-detection from `.env`.
- **HTTP → HTTPS redirect** — Secondary listener on port 3001.

---

## [0.2.0-alpha] — 2026-02-10

### Added
- **6 UI themes** — Haven, Discord, Matrix, Tron, HALO, Lord of the Rings.
- **Status bar** — LEDs, ping, channel name, online count, clock.
- **`Start Haven.bat`** — Windows one-click launcher.
- **Unread badges** — Channel list badges.
- **Message grouping** — Compact mode for consecutive messages.

### Fixed
- **App crash** — `initThemeSwitcher()` extracted to shared `theme.js`.

---

## [0.1.0-alpha] — 2026-02-10

### Added
- Core server (Express + Socket.IO).
- User authentication (bcrypt + JWT).
- Secret channels with invite codes.
- Real-time text chat with history.
- Voice chat (WebRTC).
- Admin controls.
- SQLite database.
- `.env` configuration.

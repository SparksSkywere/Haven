const express = require('express');
const bcrypt = require('bcryptjs');
// Removed unused import: jwt
// Removed unused import: crypto
const { getDb } = require('./database');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  console.error('FATAL: JWT_SECRET is not set. Check your .env file or let server.js auto-generate it.');
  process.exit(1);
}

// ── Rate Limiting (in-memory, no extra deps) ────────────
const rateLimitStore = new Map();

function authLimiter(req, res, next) {
  const ip = req.ip || req.socket.remoteAddress;
  const now = Date.now();
  const windowMs = 15 * 60 * 1000; // 15 minutes
  const maxAttempts = 20;           // 20 auth requests per 15 min per IP

  if (!rateLimitStore.has(ip)) {
    rateLimitStore.set(ip, []);
  }

  const timestamps = rateLimitStore.get(ip).filter(t => now - t < windowMs);
  rateLimitStore.set(ip, timestamps);

  if (timestamps.length >= maxAttempts) {
    return res.status(429).json({
      error: 'Too many attempts. Try again in a few minutes.'
    });
  }

  timestamps.push(now);
  next();
}

// Clean up stale entries every 30 minutes
setInterval(() => {
  const now = Date.now();
  const windowMs = 15 * 60 * 1000;
  for (const [ip, timestamps] of rateLimitStore) {
    const fresh = timestamps.filter(t => now - t < windowMs);
    if (fresh.length === 0) rateLimitStore.delete(ip);
    else rateLimitStore.set(ip, fresh);
  }
}, 30 * 60 * 1000);

// ── Input Sanitization ──────────────────────────────────
function sanitizeString(str, maxLen = 200) {
  if (typeof str !== 'string') return '';
  return str.trim().slice(0, maxLen);
}

// ── Register ──────────────────────────────────────────────
router.post('/register', async (req, res) => {
  try {
    const username = sanitizeString(req.body.username, 20);
    const password = typeof req.body.password === 'string' ? req.body.password : '';
    const eulaVersion = typeof req.body.eulaVersion === 'string' ? req.body.eulaVersion.trim() : '';
    const ageVerified = req.body.ageVerified === true;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }
    if (!eulaVersion) {
      return res.status(400).json({ error: 'You must accept the Terms of Service & Release of Liability Agreement' });
    }
    if (!ageVerified) {
      return res.status(400).json({ error: 'You must confirm that you are 18 years of age or older' });
    }

    if (username.length < 3 || username.length > 20) {
      return res.status(400).json({ error: 'Username must be 3-20 characters' });
    }
    if (password.length < 8 || password.length > 1024) {
      return res.status(400).json({ error: 'Password must be 8-1024 characters' });
    }
    if (!/^[a-zA-Z0-9_]+$/.test(username)) {
      return res.status(400).json({ error: 'Username: letters, numbers, underscores only' });
    }

    const db = getDb();

    // Whitelist check — if enabled, only pre-approved usernames can register
    const wlSetting = db.prepare("SELECT value FROM server_settings WHERE key = 'whitelist_enabled'").get();
    if (wlSetting && wlSetting.value === 'true') {
      const onList = db.prepare('SELECT 1 FROM whitelist WHERE username = ?').get(username);
      if (!onList) {
        return res.status(403).json({ error: 'Registration is restricted. Your username is not on the whitelist.' });
      }
    }

    const existing = db.prepare('SELECT id FROM users WHERE username = ?').get(username);
    if (existing) {
      return res.status(409).json({ error: 'Username is already taken' });
    }

    const hash = await bcrypt.hash(password, 12);

    // Discord-style: the very first user to register becomes the server owner (admin)
    const userCount = db.prepare('SELECT COUNT(*) as cnt FROM users').get();
    const isAdmin = userCount.cnt === 0 ? 1 : 0;

    const result = db.prepare(
      'INSERT INTO users (username, password_hash, is_admin) VALUES (?, ?, ?)'
    ).run(username, hash, isAdmin);

    // Auto-assign roles flagged as auto_assign to new users
    try {
      const autoRoles = db.prepare("SELECT id FROM roles WHERE auto_assign = 1 AND scope = 'server'").all();
      if (autoRoles.length > 0) {
        const insertRole = db.prepare('INSERT OR IGNORE INTO user_roles (user_id, role_id, channel_id, granted_by) VALUES (?, ?, NULL, NULL)');
        const assignAll = db.transaction(() => {
          for (const role of autoRoles) {
            insertRole.run(result.lastInsertRowid, role.id);
          }
        });
        assignAll();
      }
    } catch { /* non-critical */ }

    // Discord-style: DO NOT auto-join channels on registration
    // Users start with empty sidebar and must join a server via invite link
    // This matches Discord where you need to create a server or use an invite to get channels

    const token = jwt.sign(
      { id: result.lastInsertRowid, username, isAdmin: !!isAdmin, displayName: username },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Record EULA acceptance
    if (eulaVersion) {
      try {
        db.prepare(
          'INSERT OR IGNORE INTO eula_acceptances (user_id, version, ip_address, age_verified) VALUES (?, ?, ?, ?)'
        ).run(result.lastInsertRowid, eulaVersion, req.ip || req.socket.remoteAddress || '', ageVerified ? 1 : 0);
      } catch { /* non-critical */ }
    }

    res.json({
      token,
      user: { id: result.lastInsertRowid, username, isAdmin: !!isAdmin, displayName: username }
    });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ── Login ─────────────────────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const username = sanitizeString(req.body.username, 20);
    const password = typeof req.body.password === 'string' ? req.body.password : '';
    const eulaVersion = typeof req.body.eulaVersion === 'string' ? req.body.eulaVersion.trim() : '';
    const ageVerified = req.body.ageVerified === true;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }
    if (!eulaVersion) {
      return res.status(400).json({ error: 'You must accept the Terms of Service & Release of Liability Agreement' });
    }
    if (!ageVerified) {
      return res.status(400).json({ error: 'You must confirm that you are 18 years of age or older' });
    }

    const db = getDb();
    const user = db.prepare('SELECT id, username, password_hash, is_admin, display_name FROM users WHERE username = ?').get(username);

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check if user is banned
    const ban = db.prepare('SELECT reason FROM bans WHERE user_id = ?').get(user.id);
    if (ban) {
      return res.status(403).json({ error: 'You have been banned from this server' });
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const displayName = user.display_name || user.username;

    // e2eSecret is no longer generated server-side (v3 true E2E — wrapping
    // key is derived from the user's password client-side)

    const token = jwt.sign(
      { id: user.id, username: user.username, isAdmin: !!user.is_admin, displayName },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Record EULA acceptance
    if (eulaVersion) {
      try {
        db.prepare(
          'INSERT OR IGNORE INTO eula_acceptances (user_id, version, ip_address, age_verified) VALUES (?, ?, ?, ?)'
        ).run(user.id, eulaVersion, req.ip || req.socket.remoteAddress || '', ageVerified ? 1 : 0);
      } catch { /* non-critical */ }
    }

    res.json({
      token,
      user: { id: user.id, username: user.username, isAdmin: !!user.is_admin, displayName }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ── Change Password ──────────────────────────────────────
router.post('/change-password', async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'Unauthorized' });
    const decoded = verifyToken(token);
    if (!decoded) return res.status(401).json({ error: 'Unauthorized' });

    const currentPassword = typeof req.body.currentPassword === 'string' ? req.body.currentPassword : '';
    const newPassword = typeof req.body.newPassword === 'string' ? req.body.newPassword : '';

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Current and new password required' });
    }
    if (newPassword.length < 8 || newPassword.length > 1024) {
      return res.status(400).json({ error: 'New password must be 8-1024 characters' });
    }

    const db = getDb();
    const user = db.prepare('SELECT id, username, password_hash, is_admin, display_name FROM users WHERE id = ?').get(decoded.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const valid = await bcrypt.compare(currentPassword, user.password_hash);
    if (!valid) return res.status(401).json({ error: 'Current password is incorrect' });

    const hash = await bcrypt.hash(newPassword, 12);
    db.prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(hash, user.id);

    // Issue a fresh token so the session stays alive
    const freshToken = jwt.sign(
      { id: user.id, username: user.username, isAdmin: !!user.is_admin, displayName: user.display_name || user.username },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({ message: 'Password changed successfully', token: freshToken });
  } catch (err) {
    console.error('Change password error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ── Helpers ───────────────────────────────────────────────

// ── Verify Password (lightweight, for E2E password prompt) ──
router.post('/verify-password', async (req, res) => {
  try {
    const username = sanitizeString(req.body.username, 20);
    const password = typeof req.body.password === 'string' ? req.body.password : '';
    if (!username || !password) {
      return res.status(400).json({ valid: false, error: 'Username and password required' });
    }
    const db = getDb();
    const user = db.prepare('SELECT password_hash FROM users WHERE username = ?').get(username);
    if (!user) {
      return res.status(401).json({ valid: false, error: 'Invalid credentials' });
    }
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ valid: false, error: 'Invalid credentials' });
    }
    res.json({ valid: true });
  } catch (err) {
    console.error('Verify password error:', err);
    res.status(500).json({ valid: false, error: 'Server error' });
  }
});

function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch {
    return null;
  }
}

function generateToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });
}

function generateChannelCode() {
  return crypto.randomBytes(4).toString('hex'); // 8-char hex string
}

module.exports = { router, verifyToken, generateChannelCode, generateToken, authLimiter };

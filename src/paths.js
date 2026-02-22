/**
 * Haven — Centralised data-directory resolution
 *
 * For portability, all user data (database, .env, certs, uploads) lives
 * in a 'data' subdirectory within the application folder. This allows
 * the entire Haven directory to be copied and run from any location.
 *
 * Location: ./data/ (relative to the application root)
 *
 * Override : set HAVEN_DATA_DIR env var to any absolute path.
 */

const path = require('path');
const fs   = require('fs');
const os   = require('os');

function getDataDir() {
  // Allow explicit override via environment variable
  if (process.env.HAVEN_DATA_DIR) {
    const custom = path.resolve(process.env.HAVEN_DATA_DIR);
    fs.mkdirSync(custom, { recursive: true });
    return custom;
  }

  // For portability, use data/ subdirectory in the app directory
  const appDir = path.dirname(__dirname); // src/paths.js -> app root
  const base = path.join(appDir, 'data');
  fs.mkdirSync(base, { recursive: true });
  return base;
}

// Pre-computed paths for convenience
const DATA_DIR     = getDataDir();
const DB_PATH      = path.join(DATA_DIR, 'haven.db');
const ENV_PATH     = path.join(DATA_DIR, '.env');
const CERTS_DIR    = path.join(DATA_DIR, 'certs');
const UPLOADS_DIR  = path.join(DATA_DIR, 'uploads');

// Ensure sub-directories exist
fs.mkdirSync(CERTS_DIR,   { recursive: true });
fs.mkdirSync(UPLOADS_DIR, { recursive: true });

// ── One-time migration: move data from old project-dir locations ─────
const PROJECT_ROOT = path.join(__dirname, '..');

function migrateFile(oldRel, newAbs) {
  const oldAbs = path.join(PROJECT_ROOT, oldRel);
  if (fs.existsSync(oldAbs) && !fs.existsSync(newAbs)) {
    try {
      fs.copyFileSync(oldAbs, newAbs);
      fs.unlinkSync(oldAbs);
      console.log(`Migrated ${oldRel} → ${newAbs}`);
    } catch { /* silent — might lack permissions */ }
  }
}

function migrateDir(oldRel, newDir) {
  const oldAbs = path.join(PROJECT_ROOT, oldRel);
  if (fs.existsSync(oldAbs)) {
    try {
      const entries = fs.readdirSync(oldAbs);
      for (const entry of entries) {
        if (entry === '.gitkeep') continue;
        const src = path.join(oldAbs, entry);
        const dst = path.join(newDir, entry);
        if (!fs.existsSync(dst) && fs.statSync(src).isFile()) {
          fs.copyFileSync(src, dst);
          fs.unlinkSync(src);
          console.log(`Migrated ${oldRel}/${entry} → ${dst}`);
        }
      }
    } catch { /* silent */ }
  }
}

// Migrate from old external data directories
function migrateFromOldExternal() {
  const oldPaths = [];
  if (process.platform === 'win32') {
    const appdata = process.env.APPDATA || path.join(os.homedir(), 'AppData', 'Roaming');
    oldPaths.push(path.join(appdata, 'Haven'));
  } else {
    oldPaths.push(path.join(os.homedir(), '.haven'));
  }

  for (const oldDir of oldPaths) {
    if (fs.existsSync(oldDir)) {
      try {
        const entries = fs.readdirSync(oldDir);
        for (const entry of entries) {
          const src = path.join(oldDir, entry);
          let dst;
          if (entry === 'haven.db' || entry.startsWith('haven.db-')) {
            dst = path.join(DATA_DIR, entry);
          } else if (entry === '.env') {
            dst = ENV_PATH;
          } else if (entry === 'certs') {
            // Migrate cert files
            if (fs.statSync(src).isDirectory()) {
              const certs = fs.readdirSync(src);
              for (const cert of certs) {
                const srcCert = path.join(src, cert);
                const dstCert = path.join(CERTS_DIR, cert);
                if (!fs.existsSync(dstCert) && fs.statSync(srcCert).isFile()) {
                  fs.copyFileSync(srcCert, dstCert);
                  console.log(`Migrated certs/${cert} → ${dstCert}`);
                }
              }
            }
            continue;
          } else if (entry === 'uploads') {
            // Migrate upload files
            if (fs.statSync(src).isDirectory()) {
              const uploads = fs.readdirSync(src);
              for (const upload of uploads) {
                const srcUpload = path.join(src, upload);
                const dstUpload = path.join(UPLOADS_DIR, upload);
                if (!fs.existsSync(dstUpload) && fs.statSync(srcUpload).isFile()) {
                  fs.copyFileSync(srcUpload, dstUpload);
                  console.log(`Migrated uploads/${upload} → ${dstUpload}`);
                }
              }
            }
            continue;
          } else {
            continue; // Skip other files
          }
          if (!fs.existsSync(dst) && fs.statSync(src).isFile()) {
            fs.copyFileSync(src, dst);
            console.log(`Migrated from old location ${entry} → ${dst}`);
          }
        }
      } catch { /* silent */ }
    }
  }
}

migrateFile('haven.db',       DB_PATH);
migrateFile('haven.db-shm',   DB_PATH + '-shm');
migrateFile('haven.db-wal',   DB_PATH + '-wal');
migrateFile('.env',           ENV_PATH);
migrateDir('certs',           CERTS_DIR);
migrateDir('public/uploads',  UPLOADS_DIR);
migrateFromOldExternal();

module.exports = { getDataDir, DATA_DIR, DB_PATH, ENV_PATH, CERTS_DIR, UPLOADS_DIR };

// ── Auth Page Logic (with theme support) ─────────────────

(function () {
  // Capture invite code from URL (e.g. /?invite=CODE or /invite/CODE redirect)
  const _urlParams = new URLSearchParams(window.location.search);
  const _inviteCode = _urlParams.get('invite') || '';
  const _appRedirect = _inviteCode ? `/app?invite=${encodeURIComponent(_inviteCode)}` : '/app';

  // If already logged in, redirect to app (preserving invite code)
  if (localStorage.getItem('haven_token')) {
    window.location.href = _appRedirect;
    return;
  }

  // ── E2E wrapping key derivation (mirrors HavenE2E.deriveWrappingKey) ───
  // crypto.subtle is only available in Secure Contexts (HTTPS or localhost).
  // On plain HTTP with a non-localhost host we skip E2E key derivation so
  // login / register still works; E2E DMs will be unavailable until HTTPS.
  const _cryptoAvailable = !!(crypto && crypto.subtle);

  async function deriveE2EWrappingKey(password) {
    if (!_cryptoAvailable) {
      console.warn('[Haven] crypto.subtle unavailable (non-secure context) — E2E wrapping key skipped');
      return null;
    }
    const enc = new TextEncoder();
    const raw = await crypto.subtle.importKey(
      'raw', enc.encode(password), 'PBKDF2', false, ['deriveBits']
    );
    const bits = await crypto.subtle.deriveBits(
      { name: 'PBKDF2', hash: 'SHA-256', salt: enc.encode('haven-e2e-wrapping-v3'), iterations: 210_000 },
      raw, 256
    );
    return Array.from(new Uint8Array(bits)).map(b => b.toString(16).padStart(2, '0')).join('');
  }

  // ── Theme switching ───────────────────────────────────
  initThemeSwitcher('auth-theme-bar');

  // ── Fetch and display server version ──────────────────
  fetch('/api/version').then(r => r.json()).then(d => {
    const el = document.getElementById('auth-version');
    if (el && d.version) el.textContent = 'v' + d.version;
  }).catch(() => {});

  // ── EULA ─────────────────────────────────────────────
  const ageCheckbox  = document.getElementById('age-checkbox');
  const eulaCheckbox = document.getElementById('eula-checkbox');
  const eulaModal = document.getElementById('eula-modal');
  const eulaLink = document.getElementById('eula-link');
  const eulaAcceptBtn = document.getElementById('eula-accept-btn');
  const eulaDeclineBtn = document.getElementById('eula-decline-btn');

  // Restore EULA acceptance from localStorage (v2.0 requires re-acceptance)
  if (localStorage.getItem('haven_eula_accepted') === '2.0') {
    eulaCheckbox.checked = true;
    ageCheckbox.checked  = true;
  }

  eulaLink.addEventListener('click', (e) => {
    e.preventDefault();
    eulaModal.style.display = 'flex';
  });

  eulaAcceptBtn.addEventListener('click', () => {
    eulaCheckbox.checked = true;
    ageCheckbox.checked  = true;
    localStorage.setItem('haven_eula_accepted', '2.0');
    eulaModal.style.display = 'none';
  });

  eulaDeclineBtn.addEventListener('click', () => {
    eulaCheckbox.checked = false;
    ageCheckbox.checked  = false;
    localStorage.removeItem('haven_eula_accepted');
    eulaModal.style.display = 'none';
  });

  eulaModal.addEventListener('click', (e) => {
    if (e.target === e.currentTarget) eulaModal.style.display = 'none';
  });

  function checkEula() {
    if (!ageCheckbox.checked) {
      showError('You must confirm that you are 18 years of age or older');
      return false;
    }
    if (!eulaCheckbox.checked) {
      showError('You must accept the Terms of Service & Release of Liability Agreement');
      return false;
    }
    return true;
  }

  // ── Tab switching ─────────────────────────────────────
  const tabs = document.querySelectorAll('.auth-tab');
  const loginForm = document.getElementById('login-form');
  const registerForm = document.getElementById('register-form');
  const errorEl = document.getElementById('auth-error');

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');

      const target = tab.dataset.tab;
      loginForm.style.display = target === 'login' ? 'flex' : 'none';
      registerForm.style.display = target === 'register' ? 'flex' : 'none';
      hideError();
    });
  });

  function showError(msg) {
    errorEl.textContent = msg;
    errorEl.style.display = 'block';
  }

  function hideError() {
    errorEl.style.display = 'none';
  }

  // ── Login ─────────────────────────────────────────────
  loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    hideError();
    if (!checkEula()) return;

    const username = document.getElementById('login-username').value.trim();
    const password = document.getElementById('login-password').value;

    if (!username || !password) return showError('Fill in all fields');

    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password, eulaVersion: '2.0', ageVerified: true })
      });

      const data = await res.json();
      if (!res.ok) return showError(data.error || 'Login failed');

      // Derive E2E wrapping key from password (client-side only, never sent to server)
      const e2eWrap = await deriveE2EWrappingKey(password);
      if (e2eWrap) sessionStorage.setItem('haven_e2e_wrap', e2eWrap);

      localStorage.setItem('haven_token', data.token);
      localStorage.setItem('haven_user', JSON.stringify(data.user));
      localStorage.setItem('haven_eula_accepted', '2.0');
      window.location.href = _appRedirect;
    } catch (err) {
      console.error('[Haven] Login error:', err);
      showError('Connection error — is the server running?');
    }
  });

  // ── Register ──────────────────────────────────────────
  registerForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    hideError();
    if (!checkEula()) return;

    const username = document.getElementById('reg-username').value.trim();
    const password = document.getElementById('reg-password').value;
    const confirm = document.getElementById('reg-confirm').value;

    if (!username || !password || !confirm) return showError('Fill in all fields');
    if (password !== confirm) return showError('Passwords do not match');
    if (password.length < 8) return showError('Password must be at least 8 characters');

    try {
      const res = await fetch('/api/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password, eulaVersion: '2.0', ageVerified: true })
      });

      const data = await res.json();
      if (!res.ok) return showError(data.error || 'Registration failed');

      // Derive E2E wrapping key from password (client-side only, never sent to server)
      const e2eWrap = await deriveE2EWrappingKey(password);
      if (e2eWrap) sessionStorage.setItem('haven_e2e_wrap', e2eWrap);

      localStorage.setItem('haven_token', data.token);
      localStorage.setItem('haven_user', JSON.stringify(data.user));
      localStorage.setItem('haven_eula_accepted', '2.0');
      window.location.href = _appRedirect;
    } catch (err) {
      console.error('[Haven] Register error:', err);
      showError('Connection error — is the server running?');
    }
  });
})();

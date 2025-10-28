// Winzige Giganten — service worker (final clean)
// - Caches app shell (HTML/CSS/JS/icons)
// - Serves cached index.html for navigations to allow offline homescreen launches
// - Runtime network-first caching for videos; falls back to cache when offline

const APP_SHELL_CACHE = 'wg-shell-v3';
const VIDEO_RUNTIME_CACHE = 'wg-videos-v1';
// Derive scope and index path relative to the service worker location so the SW
// works whether deployed at repo root or in a subpath (GitHub Pages project site).
const SW_URL = self.location.href;
const SW_BASE = new URL('.', SW_URL).pathname; // example: '/2025_kunst_und_brot_winzige_giganten/'
const INDEX_PATH = SW_BASE + 'index.html';

const APP_SHELL_FILES = [
  INDEX_PATH,
  SW_BASE + 'style.css',
  SW_BASE + 'script.js',
  SW_BASE + 'manifest.json',
  SW_BASE + 'icons/icon-192.png',
  SW_BASE + 'icons/icon-512.png'
];

// Limit entries in a cache to avoid unbounded growth
async function trimCache(cacheName, maxEntries) {
  const cache = await caches.open(cacheName);
  const keys = await cache.keys();
  if (keys.length > maxEntries) {
    for (let i = 0; i < keys.length - maxEntries; i++) {
      await cache.delete(keys[i]);
    }
  }
}

self.addEventListener('install', event => {
  event.waitUntil(caches.open(APP_SHELL_CACHE).then(cache => cache.addAll(APP_SHELL_FILES)));
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => Promise.all(
      keys.filter(k => ![APP_SHELL_CACHE, VIDEO_RUNTIME_CACHE].includes(k)).map(k => caches.delete(k))
    ))
  );
  self.clients.claim();
});

self.addEventListener('fetch', event => {
  const req = event.request;
  const url = new URL(req.url);

  // Only handle requests within our app folder (respect the SW base path)
  if (!url.pathname.startsWith(SW_BASE)) return;

  // Navigations: serve cached index.html so homescreen launches work offline
  if (req.mode === 'navigate') {
    event.respondWith(caches.match(INDEX_PATH).then(cached => cached || fetch(INDEX_PATH)));
    return;
  }

  // Videos: network-first with cache fallback.
  // Browsers often use Range requests for media; Range headers cause cached keys to miss.
  // Strategy: when fetching from network, request the full resource (no Range) so we cache
  // a complete copy under a normalized key (SW_BASE + video pathname). When offline,
  // we match that normalized key and return the cached full response.
  if (req.destination === 'video' || url.pathname.endsWith('.mp4')) {
    event.respondWith((async () => {
    // Create a normalized key that keeps the videos in the same "videos/" folder
    // so cached entries match requests for `/.../videos/<file>` later.
    const filename = url.pathname.split('/').pop();
    const normalizedKey = SW_BASE + 'videos/' + filename;
      try {
        // If the request includes a Range header, fetch a full copy (no Range)
        const needsFull = req.headers.has('range');
        const fetchReq = needsFull ? new Request(req.url, { method: 'GET', headers: new Headers(), mode: req.mode, credentials: req.credentials, redirect: req.redirect }) : req;

        const response = await fetch(fetchReq);

        // Cache the full response under a normalized key (use pathname filename)
        const cache = await caches.open(VIDEO_RUNTIME_CACHE);
        // Store under a cleaned request so future Range requests match the cached full file
        cache.put(new Request(normalizedKey), response.clone()).then(() => trimCache(VIDEO_RUNTIME_CACHE, 3)).catch(() => {});
        return response;
      } catch (err) {
        // Try to find the cached full video (normalized key)
        const cached = await caches.match(new Request(normalizedKey));
        if (cached) {
          // If the client requested a byte range, serve a 206 Partial Content slice
          const range = req.headers.get('range');
          if (range) {
            try {
              const buffer = await cached.arrayBuffer();
              const size = buffer.byteLength;
              // parse "bytes=start-end"
              const matches = /bytes=(\d*)-(\d*)/.exec(range);
              let start = 0, end = size - 1;
              if (matches) {
                if (matches[1]) start = parseInt(matches[1], 10);
                if (matches[2]) end = parseInt(matches[2], 10);
              }
              // clamp
              start = Math.max(0, Math.min(start, size - 1));
              end = Math.max(start, Math.min(end, size - 1));
              const chunk = buffer.slice(start, end + 1);
              const headers = new Headers();
              const contentType = cached.headers && cached.headers.get('content-type');
              if (contentType) headers.set('Content-Type', contentType);
              headers.set('Content-Range', `bytes ${start}-${end}/${size}`);
              headers.set('Accept-Ranges', 'bytes');
              headers.set('Content-Length', String(chunk.byteLength));
              return new Response(chunk, { status: 206, statusText: 'Partial Content', headers });
            } catch (e) {
              // fallback to returning the whole cached response
              return cached;
            }
          }
          return cached;
        }
        return new Response('', { status: 503, statusText: 'Service Unavailable' });
      }
    })());
    return;
  }

  // App-shell / static assets: cache-first
  event.respondWith(caches.match(req).then(cached => cached || fetch(req)));
});

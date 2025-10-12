// Winzige Giganten — service worker (final clean)
// - Caches app shell (HTML/CSS/JS/icons)
// - Serves cached index.html for navigations to allow offline homescreen launches
// - Runtime network-first caching for videos; falls back to cache when offline

const APP_SHELL_CACHE = 'wg-shell-v3';
const VIDEO_RUNTIME_CACHE = 'wg-videos-v1';
const INDEX_PATH = '/winzige_giganten_webapp/winzige_giganten_index.html';

const APP_SHELL_FILES = [
  INDEX_PATH,
  '/winzige_giganten_webapp/style.css',
  '/winzige_giganten_webapp/script.js',
  '/winzige_giganten_webapp/manifest.json',
  '/winzige_giganten_webapp/icons/icon-192.png',
  '/winzige_giganten_webapp/icons/icon-512.png'
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

  // Only handle requests within our app folder
  if (!url.pathname.startsWith('/winzige_giganten_webapp/')) return;

  // Navigations: serve cached index.html so homescreen launches work offline
  if (req.mode === 'navigate') {
    event.respondWith(caches.match(INDEX_PATH).then(cached => cached || fetch(INDEX_PATH)));
    return;
  }

  // Videos: network-first with cache fallback
  if (req.destination === 'video' || url.pathname.endsWith('.mp4')) {
    event.respondWith((async () => {
      try {
        const response = await fetch(req);
        const cache = await caches.open(VIDEO_RUNTIME_CACHE);
        cache.put(req, response.clone()).then(() => trimCache(VIDEO_RUNTIME_CACHE, 3)).catch(() => {});
        return response;
      } catch (err) {
        const cached = await caches.match(req);
        if (cached) return cached;
        return new Response('', { status: 503, statusText: 'Service Unavailable' });
      }
    })());
    return;
  }

  // App-shell / static assets: cache-first
  event.respondWith(caches.match(req).then(cached => cached || fetch(req)));
});

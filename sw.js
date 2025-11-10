// Winzige Giganten — service worker (v4 - full video precaching)
// - Caches app shell (HTML/CSS/JS/icons) AND all videos at install time
// - Ensures 100% offline functionality with progress reporting
// - Serves cached content with proper Range request support for videos

const APP_SHELL_CACHE = 'wg-shell-v4';
const VIDEO_CACHE = 'wg-videos-v4';
// Derive scope and index path relative to the service worker location
const SW_URL = self.location.href;
const SW_BASE = new URL('.', SW_URL).pathname;
const INDEX_PATH = SW_BASE + 'index.html';

const APP_SHELL_FILES = [
  INDEX_PATH,
  SW_BASE + 'style.css',
  SW_BASE + 'script.js',
  SW_BASE + 'manifest.json',
  SW_BASE + 'icons/icon-192.png',
  SW_BASE + 'icons/icon-512.png'
];

// All videos to precache for full offline support
const VIDEO_FILES = [
  SW_BASE + 'videos/teaser.mp4',
  SW_BASE + 'videos/Pasteur.mp4',
  SW_BASE + 'videos/Robert_Hooke.mp4',
  SW_BASE + 'videos/Van_Leevenhoek.mp4'
];

// Helper to send progress messages to clients
function notifyClients(message) {
  self.clients.matchAll().then(clients => {
    clients.forEach(client => client.postMessage(message));
  });
}

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
  event.waitUntil((async () => {
    // Cache app shell first
    const shellCache = await caches.open(APP_SHELL_CACHE);
    await shellCache.addAll(APP_SHELL_FILES);
    
    notifyClients({ type: 'CACHE_PROGRESS', message: 'App shell cached', progress: 20 });
    
    // Cache videos one by one with progress updates
    const videoCache = await caches.open(VIDEO_CACHE);
    const total = VIDEO_FILES.length;
    
    for (let i = 0; i < total; i++) {
      const videoUrl = VIDEO_FILES[i];
      const videoName = videoUrl.split('/').pop();
      
      notifyClients({ 
        type: 'CACHE_PROGRESS', 
        message: `Caching ${videoName}...`, 
        progress: 20 + Math.round((i / total) * 70)
      });
      
      try {
        const response = await fetch(videoUrl);
        await videoCache.put(videoUrl, response);
      } catch (err) {
        console.error('Failed to cache video:', videoUrl, err);
      }
    }
    
    notifyClients({ type: 'CACHE_COMPLETE', message: 'All media cached', progress: 100 });
  })());
  
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => Promise.all(
      keys.filter(k => ![APP_SHELL_CACHE, VIDEO_CACHE].includes(k)).map(k => caches.delete(k))
    ))
  );
  self.clients.claim();
});

self.addEventListener('fetch', event => {
  const req = event.request;
  const url = new URL(req.url);

  // Only handle requests within our app folder
  if (!url.pathname.startsWith(SW_BASE)) return;

  // Navigations: serve cached index.html for offline homescreen launches
  if (req.mode === 'navigate') {
    event.respondWith(caches.match(INDEX_PATH).then(cached => cached || fetch(INDEX_PATH)));
    return;
  }

  // Videos: serve from cache with Range request support (offline-safe)
  if (req.destination === 'video' || url.pathname.endsWith('.mp4')) {
    event.respondWith((async () => {
      try {
        // Always try cache first - essential for offline
        const cached = await caches.match(req.url, { ignoreSearch: true });
        
        if (!cached) {
          console.warn('Video not in cache:', req.url);
          // Try network as last resort
          try {
            return await fetch(req);
          } catch (networkErr) {
            // Network failed and no cache - return error response
            return new Response('Video not available offline', { status: 503 });
          }
        }
        
        // Handle Range requests for video seeking
        const range = req.headers.get('range');
        if (range) {
          try {
            const buffer = await cached.arrayBuffer();
            const size = buffer.byteLength;
            const matches = /bytes=(\d*)-(\d*)/.exec(range);
            let start = 0, end = size - 1;
            
            if (matches) {
              if (matches[1]) start = parseInt(matches[1], 10);
              if (matches[2]) end = parseInt(matches[2], 10);
            }
            
            start = Math.max(0, Math.min(start, size - 1));
            end = Math.max(start, Math.min(end, size - 1));
            const chunk = buffer.slice(start, end + 1);
            
            const headers = new Headers();
            const contentType = cached.headers.get('content-type') || 'video/mp4';
            headers.set('Content-Type', contentType);
            headers.set('Content-Range', `bytes ${start}-${end}/${size}`);
            headers.set('Accept-Ranges', 'bytes');
            headers.set('Content-Length', String(chunk.byteLength));
            // Critical for offline: tell browser this is available offline
            headers.set('Cache-Control', 'public, max-age=31536000');
            
            return new Response(chunk, { status: 206, statusText: 'Partial Content', headers });
          } catch (e) {
            console.error('Range request failed, returning full video:', e);
            return cached;
          }
        }
        
        // No range request - return full video with proper headers
        const headers = new Headers(cached.headers);
        headers.set('Accept-Ranges', 'bytes');
        headers.set('Cache-Control', 'public, max-age=31536000');
        return new Response(await cached.blob(), { 
          status: 200, 
          statusText: 'OK', 
          headers 
        });
      } catch (err) {
        console.error('Video fetch error:', err);
        return new Response('Video error', { status: 500 });
      }
    })());
    return;
  }

  // App-shell / static assets: cache-first
  event.respondWith(caches.match(req).then(cached => cached || fetch(req)));
});

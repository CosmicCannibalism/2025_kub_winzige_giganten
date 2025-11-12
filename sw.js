// Winzige Giganten — service worker (v5 - full video precaching)
// - Caches app shell (HTML/CSS/JS/icons) AND all videos at install time
// - Ensures 100% offline functionality with progress reporting
// - Serves cached content with proper Range request support for videos

const APP_SHELL_CACHE = 'wg-shell-v22';
const VIDEO_CACHE = 'wg-videos-v22';
// Derive scope and index path relative to the service worker location
const SW_URL = self.location.href;
const SW_BASE = new URL('.', SW_URL).pathname;
const INDEX_PATH = SW_BASE + 'index.html';

const APP_SHELL_FILES = [
  SW_BASE + 'index.html',
  SW_BASE + 'index01.html',
  SW_BASE + 'index02.html',
  SW_BASE + 'style.css',
  SW_BASE + 'script.js',
  SW_BASE + 'manifest.json',
  SW_BASE + 'manifest01.json',
  SW_BASE + 'manifest02.json',
  SW_BASE + 'icons/icon-pasteur-180.png',
  SW_BASE + 'icons/icon-pasteur-192.png',
  SW_BASE + 'icons/icon-pasteur-512.png',
  SW_BASE + 'icons/icon-hooke-180.png',
  SW_BASE + 'icons/icon-hooke-192.png',
  SW_BASE + 'icons/icon-hooke-512.png',
  SW_BASE + 'icons/icon-leeuwenhoek-180.png',
  SW_BASE + 'icons/icon-leeuwenhoek-192.png',
  SW_BASE + 'icons/icon-leeuwenhoek-512.png'
];

// All videos to precache for full offline support
// Use absolute URLs to ensure proper caching
const VIDEO_FILES = [
  '/videos/teaser.mp4',
  '/videos/Pasteur.mp4',
  '/videos/Robert_Hooke.mp4',
  '/videos/Van_Leevenhoek.mp4'
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
  console.log('SW: Install event started');
  
  event.waitUntil((async () => {
    try {
      // Cache app shell first - one by one for better error handling
      console.log('SW: Caching app shell...');
      const shellCache = await caches.open(APP_SHELL_CACHE);
      
      for (const file of APP_SHELL_FILES) {
        try {
          const response = await fetch(file);
          if (response.ok) {
            await shellCache.put(file, response);
            console.log(`SW: ✓ Cached shell file: ${file}`);
          } else {
            console.warn(`SW: ⚠ Skipping ${file} (HTTP ${response.status})`);
          }
        } catch (err) {
          console.warn(`SW: ⚠ Failed to cache ${file}:`, err);
          // Continue with other files even if one fails
        }
      }
      
      console.log('SW: App shell cached ✓');
      notifyClients({ type: 'CACHE_PROGRESS', message: 'App shell cached', progress: 20 });
      
      // Cache videos one by one with progress updates
      console.log('SW: Caching videos...');
      const videoCache = await caches.open(VIDEO_CACHE);
      const total = VIDEO_FILES.length;
      
      let allSuccess = true;
      for (let i = 0; i < total; i++) {
        const videoUrl = VIDEO_FILES[i];
        const videoName = videoUrl.split('/').pop();
        
        console.log(`SW: Fetching ${videoName} (${i+1}/${total})...`);
        
        notifyClients({ 
          type: 'CACHE_PROGRESS', 
          message: `Caching ${videoName}...`, 
          progress: 20 + Math.round((i / total) * 70)
        });
        
        try {
          const response = await fetch(videoUrl);
          if (!response.ok) throw new Error(`HTTP ${response.status}`);
          await videoCache.put(videoUrl, response);
          console.log(`SW: ✓ Cached ${videoName}`);
        } catch (err) {
          console.error(`SW: ✗ Failed to cache ${videoName}:`, err);
          notifyClients({ type: 'CACHE_ERROR', message: `Failed: ${videoName}`, error: err.message });
          allSuccess = false;
        }
      }
      
      if (allSuccess) {
        console.log('SW: All videos cached successfully ✓');
        notifyClients({ type: 'CACHE_COMPLETE', message: 'All media cached', progress: 100 });
      } else {
        console.warn('SW: Some videos failed to cache');
        notifyClients({ type: 'CACHE_INCOMPLETE', message: 'Some videos failed to cache', progress: 90 });
      }
      
      // Skip waiting to activate new service worker immediately
      await self.skipWaiting();
      console.log('SW: Install complete, skipping waiting');
      
    } catch (err) {
      console.error('SW: Install failed:', err);
      throw err;
    }
  })());
});

self.addEventListener('activate', event => {
  console.log('SW: Activate event');
  event.waitUntil((async () => {
    // Clean up old caches
    const keys = await caches.keys();
    await Promise.all(
      keys.filter(k => ![APP_SHELL_CACHE, VIDEO_CACHE].includes(k))
         .map(k => {
           console.log('SW: Deleting old cache:', k);
           return caches.delete(k);
         })
    );
    
    // Take control of all clients immediately
    await self.clients.claim();
    console.log('SW: Activated and claimed clients');
  })());
});

self.addEventListener('fetch', event => {
  const req = event.request;
  const url = new URL(req.url);

  // Only handle requests within our app folder
  if (!url.pathname.startsWith(SW_BASE)) return;

  // Navigations: serve the requested HTML file (index.html, index01.html, index02.html)
  if (req.mode === 'navigate') {
    event.respondWith((async () => {
      // Build the pathname for cache lookup (strip query string)
      const pathname = url.pathname === '/' ? '/index.html' : url.pathname;
      const cacheUrl = new URL(pathname, url.origin).href;
      
      console.log('SW: Navigation request:', url.pathname, '→ cache lookup:', cacheUrl);
      
      // Try to serve from cache
      const cached = await caches.match(cacheUrl, { ignoreSearch: true });
      if (cached) {
        console.log('SW: ✓ Serving cached HTML');
        return cached;
      }
      
      // Not in cache - try network
      console.warn('SW: HTML not in cache, trying network:', pathname);
      try {
        const response = await fetch(req);
        if (response.ok) {
          console.log('SW: ✓ Fetched from network');
          return response;
        } else {
          console.error('SW: Network returned', response.status);
          return new Response(`Error ${response.status}`, { 
            status: response.status, 
            headers: { 'Content-Type': 'text/plain' } 
          });
        }
      } catch (err) {
        console.error('SW: ✗ Navigation failed offline:', pathname, err);
        return new Response('App offline - please reconnect to Wi-Fi', { 
          status: 503, 
          headers: { 'Content-Type': 'text/plain; charset=utf-8' } 
        });
      }
    })());
    return;
  }

  // App shell assets (CSS, JS, manifest, icons): cache-first strategy
  if (url.pathname.endsWith('.css') || 
      url.pathname.endsWith('.js') || 
      url.pathname.endsWith('.json') ||
      url.pathname.endsWith('.png') ||
      url.pathname.endsWith('.jpg') ||
      url.pathname.endsWith('.svg')) {
    event.respondWith((async () => {
      // Try cache first
      const cached = await caches.match(req.url, { ignoreSearch: true });
      if (cached) {
        console.log('SW: ✓ Serving cached asset:', url.pathname);
        return cached;
      }
      
      // Not in cache - try network
      console.log('SW: Fetching asset from network:', url.pathname);
      try {
        const response = await fetch(req);
        if (response.ok) {
          // Cache for next time
          const cache = await caches.open(APP_SHELL_CACHE);
          cache.put(req.url, response.clone());
          return response;
        }
        return response;
      } catch (err) {
        console.error('SW: ✗ Asset fetch failed:', url.pathname, err);
        return new Response('Asset not available offline', { 
          status: 503,
          headers: { 'Content-Type': 'text/plain' }
        });
      }
    })());
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

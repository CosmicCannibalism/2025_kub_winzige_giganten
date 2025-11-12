console.log('Winzige Giganten script.js loaded — version 2025-09-27');
(function(){
  const teaser = document.getElementById('teaserVideo');
  const main = document.getElementById('mainVideo');
  const overlay = document.getElementById('overlay');
  const startBtn = document.getElementById('startBtn');
  const spinner = document.querySelector('.spinner');

  // Hide Start button initially
    // Hide Start button initially (use class for opacity control)
    startBtn.classList.add('fade-hidden');
  teaser.classList.add('visible'); teaser.classList.remove('hidden');
  main.classList.remove('visible'); main.classList.add('hidden');

  let teaserReady = false;
  let mainReady = false;
  let started = false;
  let fallbackTimer = null;
  let mainVideoPreloaded = false;
  let allVideosCached = false; // Track if Service Worker cached all videos

  // Track online/offline status
  window.addEventListener('online', () => {
    console.log('Network: ONLINE');
  });
  window.addEventListener('offline', () => {
    console.log('Network: OFFLINE - using cached videos');
  });

const overlayMsg = document.getElementById('overlayMsg');
function showStartButton() {
  if (spinner) spinner.style.display = 'none';
  if (overlayMsg) overlayMsg.style.display = 'none';
  // ensure the button is visible immediately (no fade)
  if (started) return; // don't show again after start
  console.log('showStartButton()');
  startBtn.style.display = 'block';
  startBtn.classList.remove('fade-hidden');
  startBtn.hidden = false;
  startBtn.setAttribute('aria-hidden', 'false');
}
function checkReady() {
  // ONLY show button when ALL videos are cached by Service Worker
  if (allVideosCached) {
    showStartButton();
  }
}

// Preload main video when teaser is ready
function preloadMainVideo() {
  if (mainVideoPreloaded) return;
  mainVideoPreloaded = true;
  console.log('Preloading main video in background');
  
  // Just set preload - Service Worker has already cached it
  main.preload = 'auto';
  // DO NOT call load() - causes offline issues!
}

  teaser.addEventListener('canplaythrough', ()=>{
    teaserReady = true;
    checkReady();
    // Start preloading main video in background once teaser is ready
    preloadMainVideo();
  });

  main.addEventListener('canplaythrough', ()=>{
    mainReady = true;
    checkReady();
  });

  // Fallback: show Start button after 30 seconds if Service Worker doesn't respond
  fallbackTimer = setTimeout(()=>{
    console.warn('Timeout: Service Worker did not complete caching, showing button anyway');
    if (!allVideosCached) {
      allVideosCached = true;
      showStartButton();
    }
  }, 30000); // 30 seconds for large videos over WiFi

  // Start button click: hide overlay, hide button, show and play teaser
  startBtn.addEventListener('click', ()=>{
    console.log('startBtn clicked — hiding button and fading overlay');
    // mark started so we don't show the start button again
    started = true;
    if (fallbackTimer) { clearTimeout(fallbackTimer); fallbackTimer = null; }
    overlay.classList.add('hidden');
    // hide the button instantly while overlay fades (robust)
    startBtn.style.display = 'none';
    startBtn.hidden = true;
    startBtn.setAttribute('aria-hidden', 'true');
    // also remove focus to avoid accidental re-activation
    try { startBtn.blur(); } catch(e){}
    teaser.classList.add('visible'); teaser.classList.remove('hidden');
    teaser.currentTime = 0;
    teaser.play().catch((err)=>{
      console.warn('Teaser autoplay failed:', err);
    });
  });

  // CRITICAL FIX: Manual loop fallback for iOS PWA mode
  // iOS PWA ignores loop attribute - manual restart needed
  teaser.addEventListener('ended', () => {
    console.log('Teaser ended - manual loop restart');
    teaser.currentTime = 0;
    teaser.play().catch(err => console.warn('Manual loop play failed:', err));
  });

  // When main video ends, return to teaser
  main.addEventListener('ended', ()=>{
    // Reset main video position (no load() needed - video is cached)
    main.pause();
    main.currentTime = 0;
    
    // Reset and play teaser
    teaser.currentTime = 0;
    teaser.classList.add('visible'); teaser.classList.remove('hidden');
    main.classList.remove('visible'); main.classList.add('hidden');
    teaser.play().catch((err)=>{
      console.warn('Teaser autoplay failed after main ended:', err);
    });
  });

  // Keyboard: Space handling
  window.addEventListener('keydown', (e)=>{
    if(e.code !== 'Space' && e.key !== 'l') return;
    // don't react while overlay is active
    if(!overlay.classList.contains('hidden')) return;
    e.preventDefault();
    
    // Long-press 'l' key from Arduino: Return to teaser (only from main video)
    if(e.key === 'l' && main.classList.contains('visible')) {
      main.pause();
      main.currentTime = 0;
      teaser.currentTime = 0;
      teaser.classList.add('visible'); teaser.classList.remove('hidden');
      main.classList.remove('visible'); main.classList.add('hidden');
      teaser.play().catch((err)=>{
        console.warn('Teaser play failed after long-press:', err);
      });
      return;
    }
    
    // Space key handling (original behavior)
    if(e.code === 'Space') {
      if(teaser.classList.contains('visible') && !main.classList.contains('visible')){
        // Switch from teaser to main
        teaser.pause();
        teaser.currentTime = 0; // Reset teaser position
        main.currentTime = 0;
        main.classList.add('visible'); main.classList.remove('hidden');
        teaser.classList.remove('visible'); teaser.classList.add('hidden');
        // NO load() - video already cached by Service Worker
        main.play().catch((err)=>{
          console.warn('Main video play failed:', err);
        });
      } else if(main.classList.contains('visible')){
        // Restart main video
        main.pause(); // Pause first before reset
        main.currentTime = 0;
        // NO load() - just restart from cached video
        main.play().catch((err)=>{
          console.warn('Main video restart failed:', err);
        });
      }
    }
  });

  // Register service worker with progress tracking
  // CRITICAL: Register immediately, not on 'load' event (which waits for video preload)
  if ('serviceWorker' in navigator) {
    // Listen for messages from Service Worker (cache progress)
    navigator.serviceWorker.addEventListener('message', (event) => {
      const { type, message, progress, error } = event.data;
      
      if (type === 'CACHE_PROGRESS') {
        if (overlayMsg) {
          overlayMsg.textContent = message;
        }
        console.log(`Cache progress: ${progress}% - ${message}`);
      } else if (type === 'CACHE_COMPLETE') {
        if (overlayMsg) {
          overlayMsg.textContent = 'Ready to start!';
        }
        console.log('All media cached successfully');
        // Mark videos as cached and show start button
        allVideosCached = true;
        setTimeout(checkReady, 500);
      } else if (type === 'CACHE_INCOMPLETE') {
        if (overlayMsg) {
          overlayMsg.textContent = 'Warning: Some videos failed to cache';
        }
        console.warn('CACHE_INCOMPLETE:', message);
        // Still show button after delay, but log warning
        allVideosCached = true;
        setTimeout(checkReady, 2000);
      } else if (type === 'CACHE_ERROR') {
        console.error('Cache error:', message, error);
      }
    });
    
    // Register Service Worker immediately (don't wait for window 'load')
    navigator.serviceWorker.register('sw.js').then(reg => {
      console.log('ServiceWorker registered', reg.scope);
      
      // If SW is already active (not first install), videos should be cached
      if (reg.active && !reg.installing) {
        console.log('SW already active, videos should be cached');
        allVideosCached = true; // Mark as cached if SW already installed
        setTimeout(checkReady, 500);
      }
    }).catch(err => {
      console.warn('ServiceWorker registration failed', err);
      // Still allow app to start even if SW fails
      setTimeout(() => showStartButton(), 5000);
    });
  } else {
    // No service worker support - show start button after timeout
    setTimeout(() => showStartButton(), 5000);
  }
})();

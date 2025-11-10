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
  let isOnline = navigator.onLine;
  let videoBlobsLoaded = false;
  let teaserBlobUrl = null;
  let mainBlobUrl = null;

  // Track online/offline status
  window.addEventListener('online', () => {
    isOnline = true;
    console.log('Network: ONLINE');
  });
  window.addEventListener('offline', () => {
    isOnline = false;
    console.log('Network: OFFLINE - using cached videos');
  });

  // Load videos as Blobs for true offline capability
  async function loadVideosAsBlobs() {
    if (videoBlobsLoaded) return;
    
    try {
      console.log('Loading videos as Blobs for offline capability...');
      
      // Get video sources from DOM
      const teaserSrc = teaser.querySelector('source').src;
      const mainSrc = main.querySelector('source').src;
      
      // Fetch videos (from cache or network)
      const [teaserResponse, mainResponse] = await Promise.all([
        fetch(teaserSrc),
        fetch(mainSrc)
      ]);
      
      // Convert to Blobs
      const [teaserBlob, mainBlob] = await Promise.all([
        teaserResponse.blob(),
        mainResponse.blob()
      ]);
      
      // Create Object URLs
      teaserBlobUrl = URL.createObjectURL(teaserBlob);
      mainBlobUrl = URL.createObjectURL(mainBlob);
      
      // Replace video sources with Blob URLs
      teaser.src = teaserBlobUrl;
      main.src = mainBlobUrl;
      
      videoBlobsLoaded = true;
      console.log('Videos loaded as Blobs - true offline mode enabled');
      
    } catch (err) {
      console.error('Failed to load videos as Blobs:', err);
      // Continue with normal src - at least online will work
    }
  }

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
  if (teaserReady && mainReady) {
    showStartButton();
  }
}

// Preload main video when teaser is ready
function preloadMainVideo() {
  if (mainVideoPreloaded) return;
  mainVideoPreloaded = true;
  console.log('Preloading main video in background (aggressive warm-up)');
  
  // Strategy: "Prime" the video decoder by playing a tiny bit muted
  // This forces browser to allocate decoder resources and buffer data
  main.preload = 'auto';
  main.muted = true;
  main.currentTime = 0;
  
  // Only call load() if online or on first load - cached videos don't need it
  if (isOnline) {
    main.load();
  }
  
  // Play a tiny bit (0.1s) then pause - this "warms up" the decoder
  const warmUpVideo = () => {
    main.play().then(() => {
      console.log('Main video decoder warmed up');
      setTimeout(() => {
        main.pause();
        main.currentTime = 0;
        main.muted = false;
        console.log('Main video ready for instant playback');
      }, 100); // Play for 100ms then reset
    }).catch(err => {
      console.warn('Video warm-up failed:', err);
      // Don't try load() again - video should be cached
      main.muted = false;
    });
  };
  
  // If video not ready yet, wait for canplay event
  if (main.readyState >= 2) {
    warmUpVideo();
  } else {
    main.addEventListener('canplay', warmUpVideo, { once: true });
  }
}

  teaser.addEventListener('canplaythrough', ()=>{
    teaserReady = true;
    checkReady();
    // Load videos as Blobs for offline capability
    loadVideosAsBlobs();
    // Start preloading main video in background once teaser is ready
    preloadMainVideo();
  });
  main.addEventListener('canplaythrough', ()=>{
    mainReady = true;
    checkReady();
  });

  // Fallback: show Start button after 10 seconds if videos aren't ready
  fallbackTimer = setTimeout(()=>{
    if (!teaserReady || !mainReady) showStartButton();
  }, 10000);

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
    if(e.code !== 'Space') return;
    // don't react while overlay is active
    if(!overlay.classList.contains('hidden')) return;
    e.preventDefault();
    if(teaser.classList.contains('visible') && !main.classList.contains('visible')){
      // Switch from teaser to main - pause teaser first to prevent double playback
      teaser.pause();
      // Video is already preloaded and warmed up - just reset position and play
      main.pause(); // Ensure clean state
      main.currentTime = 0;
      main.muted = false; // Ensure unmuted (in case warm-up left it muted)
      main.classList.add('visible'); main.classList.remove('hidden');
      teaser.classList.remove('visible'); teaser.classList.add('hidden');
      // Small delay to ensure DOM updates before play
      setTimeout(() => {
        main.play().catch((err)=>{
          console.warn('Main video play failed:', err);
        });
      }, 10);
    } else if(main.classList.contains('visible')){
      // Restart main - ensure it's not paused, reset position
      main.pause(); // Pause first for clean reset
      main.currentTime = 0;
      // Immediate restart
      setTimeout(() => {
        main.play().catch((err)=>{
          console.warn('Main video restart failed:', err);
        });
      }, 10);
    }
  });

  // Register service worker with progress tracking
  if ('serviceWorker' in navigator) {
    // Listen for messages from Service Worker (cache progress)
    navigator.serviceWorker.addEventListener('message', (event) => {
      const { type, message, progress } = event.data;
      
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
        // Force check ready state after cache is complete
        setTimeout(checkReady, 500);
      }
    });
    
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('sw.js').then(reg => {
        console.log('ServiceWorker registered', reg.scope);
        
        // If SW is already active (not first install), videos should be cached
        if (reg.active && !reg.installing) {
          console.log('SW already active, videos should be cached');
          setTimeout(checkReady, 500);
        }
      }).catch(err => {
        console.warn('ServiceWorker registration failed', err);
        // Still allow app to start even if SW fails
        setTimeout(() => showStartButton(), 5000);
      });
    });
  } else {
    // No service worker support - show start button after timeout
    setTimeout(() => showStartButton(), 5000);
  }
})();

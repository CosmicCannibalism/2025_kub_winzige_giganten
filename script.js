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

  teaser.addEventListener('canplaythrough', ()=>{
    teaserReady = true;
    checkReady();
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
    teaser.play().catch(()=>{});
  });

  // When main video ends, return to teaser
  main.addEventListener('ended', ()=>{
    teaser.currentTime = 0;
    teaser.classList.add('visible'); teaser.classList.remove('hidden');
    main.classList.remove('visible'); main.classList.add('hidden');
    teaser.play().catch(()=>{});
  });

  // Keyboard: Space handling
  window.addEventListener('keydown', (e)=>{
    if(e.code !== 'Space') return;
    // don't react while overlay is active
    if(!overlay.classList.contains('hidden')) return;
    e.preventDefault();
    if(teaser.classList.contains('visible') && !main.classList.contains('visible')){
      // show main
      main.currentTime = 0;
      main.classList.add('visible'); main.classList.remove('hidden');
      teaser.classList.remove('visible'); teaser.classList.add('hidden');
      main.play().catch(()=>{});
    } else if(main.classList.contains('visible')){
      // restart main
      main.currentTime = 0; main.play().catch(()=>{});
    }
  });

  // Register service worker for offline/app-shell behavior (optional)
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('sw.js').then(reg => {
        console.log('ServiceWorker registered', reg.scope);
      }).catch(err => {
        console.warn('ServiceWorker registration failed', err);
      });
    });
  }
})();

// The reused site component persists a user-resized card width to localStorage
// ('tc-card-size') and restores it on mount. In the docked side panel, Chrome
// controls the width (the card fills the panel and its own resize handle is
// disabled via panel.css), so clear that key before the component mounts to keep
// the card flush with the panel. Runs before popup.js.
try { localStorage.removeItem('tc-card-size'); } catch (e) { /* ignore */ }

// Swallow ONLY the benign "ResizeObserver loop completed with undelivered
// notifications" warning. The component's height-animation observer emits it
// harmlessly (a resize callback nudges the card height, which re-measures in the
// same frame); it breaks nothing but Chrome logs it as a page error. Registered
// before the app mounts so it catches the very first one. Every other error
// still propagates normally.
window.addEventListener('error', function (e) {
  if (e && e.message && e.message.indexOf('ResizeObserver loop') !== -1) {
    e.stopImmediatePropagation();
    e.preventDefault();
  }
});

// Chrome's side panel can leave a stale hit-test/paint region on first open: after
// the custom fonts load (or the engine result lands) the button metrics shift, but
// the panel doesn't rebuild the interactive region until something forces a real
// REFLOW — so the button body ignores hover while the icon (its own painted box)
// still reacts, and typing a character "fixes" every button at once. A composite-
// only repaint (transform/opacity) is NOT enough; the hit-test region only rebuilds
// on layout. So we dirty a layout property (+0.5px bottom padding, imperceptible),
// flush it, then restore next frame — the same reflow that typing a space triggers.
function tcRepaintNudge() {
  // Document-level reflow first — nudging the body height by a hair mimics the
  // panel resize that reliably "unfreezes" a fresh side panel (the whole-document
  // hit-test region rebuilds). body already has min-height:100vh in panel.css, so
  // this restores to the stylesheet value on the next frame.
  var b = document.body;
  if (b) {
    b.style.minHeight = 'calc(100vh + 1px)';
    void b.offsetHeight;
    requestAnimationFrame(function () { b.style.minHeight = ''; });
  }
  // Then a subtree reflow on #app (dirty a layout prop by 0.5px, flush, restore).
  var app = document.getElementById('app');
  if (app) {
    var base = parseFloat(getComputedStyle(app).paddingBottom) || 0;
    app.style.paddingBottom = (base + 0.5) + 'px';
    void app.offsetHeight;
    requestAnimationFrame(function () { app.style.paddingBottom = ''; });
  }
}
function tcScheduleNudges() {
  tcRepaintNudge();
  setTimeout(tcRepaintNudge, 120);
  setTimeout(tcRepaintNudge, 400);
  // Custom-font swap is the usual culprit — nudge once metrics are final.
  if (document.fonts && document.fonts.ready) {
    document.fonts.ready.then(tcRepaintNudge).catch(function () {});
  }
  // Safety net: the first pointer movement anywhere in the panel rebuilds the
  // hit-test region immediately. It's on the document (capture), so it fires even
  // while an individual button's own hover is the thing that's stale.
  var once = function () {
    document.removeEventListener('pointermove', once, true);
    tcRepaintNudge();
  };
  document.addEventListener('pointermove', once, true);
}
if (document.readyState === 'complete') tcScheduleNudges();
else window.addEventListener('load', tcScheduleNudges);

// Color theme: System / Light / Dark, persisted in localStorage. Loaded in
// <head> so it sets [data-theme] on <html> BEFORE first paint (no flash). Also
// wires the header switch and follows the OS while in "system" mode. The reused
// component and panel chrome read CSS vars, so switching re-colors live.
(function () {
  'use strict';
  var KEY = 'tc-theme';
  var mq = window.matchMedia('(prefers-color-scheme: dark)');

  function pref() {
    try { return localStorage.getItem(KEY) || 'system'; } catch (e) { return 'system'; }
  }
  function resolve(p) { return p === 'system' ? (mq.matches ? 'dark' : 'light') : p; }
  function apply(p) { document.documentElement.setAttribute('data-theme', resolve(p)); }

  // Apply immediately (before paint).
  apply(pref());

  // Follow the OS while in system mode.
  var onMq = function () { if (pref() === 'system') apply('system'); };
  if (mq.addEventListener) mq.addEventListener('change', onMq);
  else if (mq.addListener) mq.addListener(onMq); // older Chrome fallback

  function markActive(p) {
    var btns = document.querySelectorAll('.tc-theme [data-theme-set]');
    for (var i = 0; i < btns.length; i++) {
      var on = btns[i].getAttribute('data-theme-set') === p;
      btns[i].classList.toggle('on', on);
      btns[i].setAttribute('aria-pressed', on ? 'true' : 'false');
    }
  }
  function setPref(p) {
    try { localStorage.setItem(KEY, p); } catch (e) {}
    apply(p);
    markActive(p);
  }

  // Wire the header switch once the DOM is parsed.
  document.addEventListener('DOMContentLoaded', function () {
    var group = document.querySelector('.tc-theme');
    if (!group) return;
    group.addEventListener('click', function (e) {
      var b = e.target.closest ? e.target.closest('[data-theme-set]') : null;
      if (b) setPref(b.getAttribute('data-theme-set'));
    });
    markActive(pref());
  });
})();

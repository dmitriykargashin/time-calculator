// Service worker: powers the address-bar (omnibox) calculator. Type the keyword
// "tc" then a duration ("tc 5h 30m + 2h 15m") and the live result shows in the
// dropdown. The Dart engine is fully self-contained (globalThis.evaluateTime) and
// needs no DOM/window, so it runs here via importScripts.
importScripts('engine/time_engine.js', 'lib/time-bridge.js');

// Clicking the toolbar icon opens the calculator in the right-hand side panel
// (which docks and resizes the page). Requires no popup in the manifest.
if (chrome.sidePanel && chrome.sidePanel.setPanelBehavior) {
  chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true }).catch(function () {});
}

var DEFAULT_FORMAT = 'Hour Minute';

function escapeXml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

// The default suggestion (the top row) is set ONCE and kept static. Chrome renders
// the default suggestion one keystroke BEHIND the input, so putting the live result
// there showed a stale, one-character-short answer. The live result instead goes
// through suggest() below, which Chrome pairs with the exact keystroke that fired
// onInputChanged — so it is always current.
chrome.omnibox.setDefaultSuggestion({
  description: 'Time Calculator — type a duration like <match>5h 30m + 2h 15m</match>, then press Enter',
});

// A separator that never appears in a duration expression, so we can carry both
// the expression AND the answer in the suggestion's `content` and split them back
// apart on Enter. `content` MUST differ from the verbatim typed text — Chrome trims
// it and, if it then equals the input, drops the row (which hid the result before).
var SEP = '  =  ';

chrome.omnibox.onInputChanged.addListener(function (text, suggest) {
  var q = (text || '').trim();
  if (q === '') { suggest([]); return; }
  var r = self.TimeBridge.evaluate(q, DEFAULT_FORMAT);
  if (r.ok) {
    suggest([{
      content: q + SEP + r.result, // distinct from input → always rendered; split on Enter
      description: '<match>= ' + escapeXml(r.result) + '</match>   <dim>·  press Enter to open in Time Calculator</dim>',
    }]);
  } else if (r.error) {
    suggest([{ content: q + SEP + '?', description: '<dim>Not a valid duration expression — keep typing</dim>' }]);
  } else {
    suggest([{ content: q + SEP + '?', description: '<dim>' + escapeXml(r.hint || 'Keep typing a duration…') + '</dim>' }]);
  }
});

chrome.omnibox.onInputEntered.addListener(function (text, disposition) {
  // `text` is either the verbatim input (Enter on the default row) or our
  // "<expr>  =  <answer>" suggestion content — take the expression part of both.
  var expr = (text || '').split(SEP)[0].trim();
  var url = chrome.runtime.getURL('src/popup/panel.html') + '?q=' + encodeURIComponent(expr);
  if (disposition === 'currentTab') chrome.tabs.update({ url: url });
  else chrome.tabs.create({ url: url });
});

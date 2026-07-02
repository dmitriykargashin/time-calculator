// Shared bridge over the Dart-compiled engine (engine/time_engine.js, which sets
// globalThis.evaluateTime). Ported from the website's app/composables/useTimeEngine.ts
// so the extension normalizes free-form input EXACTLY like the site, then feeds the
// engine its own grammar. Attaches to `self` so it works in the popup (window) AND
// the omnibox service worker (self === globalThis). No DOM, no network.
(function (root) {
  'use strict';

  // Longest-match-first so "mo"->Month beats "m"->Minute and "ms"->MSecond.
  var UNIT_RULES = [
    [/\b(?:years?|yrs?|y)\b/g, 'Year'],
    [/\b(?:months?|mons?|mo)\b/g, 'Month'],
    [/\b(?:weeks?|wks?|w)\b/g, 'Week'],
    [/\b(?:days?|d)\b/g, 'Day'],
    [/\b(?:hours?|hrs?|h)\b/g, 'Hour'],
    [/\b(?:milliseconds?|millis?|msecs?|ms)\b/g, 'MSecond'],
    [/\b(?:minutes?|mins?|m)\b/g, 'Minute'],
    [/\b(?:seconds?|secs?|s)\b/g, 'Second'],
  ];

  // Free-form -> engine grammar. "5h30m" -> "5 Hour 30 Minute".
  function normalizeExpression(raw) {
    var s = (raw == null ? '' : String(raw)).toLowerCase();
    s = s.replace(/[×✕✖]/g, '*').replace(/[÷]/g, '/').replace(/[–—−]/g, '-');
    // split glued digit<->letter boundaries: "5h30m" -> "5 h 30 m"
    s = s.replace(/(\d)([a-z])/g, '$1 $2').replace(/([a-z])(\d)/g, '$1 $2');
    for (var i = 0; i < UNIT_RULES.length; i++) s = s.replace(UNIT_RULES[i][0], UNIT_RULES[i][1]);
    return s.replace(/\s+/g, ' ').trim();
  }

  // Clock-style "2:30:15" / "2:45" -> engine grammar. A 3-part token is h:m:s; a
  // bare 2-part token reads as hours:minutes unless a decimal tail implies seconds.
  var COLON_SRC = '(?<![\\d.:])(\\d{1,4}):(\\d{1,2})(?::(\\d{1,2}))?(?:\\.(\\d{1,3}))?(?![\\d:])';
  function expandColon(raw, mode) {
    if (!raw) return raw;
    return String(raw).replace(new RegExp(COLON_SRC, 'g'), function (m, a, b, c, frac) {
      var parts = [];
      if (c != null) parts.push(Number(a) + 'h', Number(b) + 'm', Number(c) + 's');
      else if (frac != null) parts.push(Number(a) + 'm', Number(b) + 's');
      else if (mode === 'ms') parts.push(Number(a) + 'm', Number(b) + 's');
      else parts.push(Number(a) + 'h', Number(b) + 'm');
      if (frac != null) parts.push(Math.round(parseFloat('0.' + frac) * 1000) + 'ms');
      return parts.join(' ');
    });
  }

  // Units the engine understands (post-normalization). Anything else alphabetic is
  // a typo (e.g. "minu") and must be rejected, not silently dropped.
  var CANONICAL_UNITS = { Year: 1, Month: 1, Week: 1, Day: 1, Hour: 1, Minute: 1, Second: 1, MSecond: 1 };
  function firstUnknownUnit(normalized) {
    var words = normalized.match(/[A-Za-z]+/g);
    if (!words) return null;
    for (var i = 0; i < words.length; i++) if (!CANONICAL_UNITS[words[i]]) return words[i];
    return null;
  }

  // Evaluate free-form input in the given engine format string ("Hour Minute").
  // Returns { ok, result, error, incomplete, hint, normalized }.
  function evaluate(input, format) {
    var normalized = normalizeExpression(expandColon(input));
    var out = { ok: false, result: '', error: false, normalized: normalized };
    if (normalized === '') return out;
    if (typeof root.evaluateTime !== 'function') { out.error = true; return out; }
    var unknown = firstUnknownUnit(normalized);
    if (unknown) { out.incomplete = true; out.hint = '"' + unknown + '" is not a known unit'; return out; }
    var res;
    try { res = root.evaluateTime(normalized, format); }
    catch (e) { out.error = true; return out; }
    if (res === 'ERROR') { out.error = true; return out; }
    if (res === 'INCOMPLETE') { out.incomplete = true; out.hint = 'give every number a unit'; return out; }
    if (res === 'SCALAR_ONLY') { out.incomplete = true; out.hint = 'multiply / divide by a plain number only'; return out; }
    if (res === '') return out;
    out.ok = true; out.result = res; return out;
  }

  // Friendly result format labels -> the engine's ordered unit-set grammar.
  var FORMATS = [
    { id: 'hm', label: 'Hours : Minutes', engine: 'Hour Minute' },
    { id: 'hms', label: 'H : M : S', engine: 'Hour Minute Second' },
    { id: 'dhms', label: 'Days, H : M : S', engine: 'Day Hour Minute Second' },
    { id: 'dech', label: 'Decimal hours', engine: 'Hour' },
    { id: 'min', label: 'Total minutes', engine: 'Minute' },
    { id: 'sec', label: 'Total seconds', engine: 'Second' },
    { id: 'all', label: 'All units', engine: 'Year Month Week Day Hour Minute Second MSecond' },
  ];

  root.TimeBridge = {
    normalizeExpression: normalizeExpression,
    expandColon: expandColon,
    firstUnknownUnit: firstUnknownUnit,
    evaluate: evaluate,
    FORMATS: FORMATS,
  };
})(typeof self !== 'undefined' ? self : this);

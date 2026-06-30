// All homepage FAQ entries (answer-first). Single source shared by the page
// (FAQPage JSON-LD) and the generated /llms.txt and /llms-full.txt routes.
export interface Faq { q: string; a: string }

export const FAQS: Faq[] = [
  {
    q: "How do I add hours and minutes together?",
    a: "Put a + between the durations, like \"5h 30m + 2h 15m\", and you get 7 Hours 45 Minutes. Mix any units you like (days, hours, minutes, seconds) and choose how the answer reads with the format picker.",
  },
  {
    q: "How do I subtract time?",
    a: "Use a minus sign. \"8h - 90m\" gives 6 Hours 30 Minutes, and \"2 days - 4h\" gives 1 Day 20 Hours. It subtracts across units, so you never have to convert everything to minutes first.",
  },
  {
    q: "Can I multiply or divide a duration?",
    a: "Yes. Pair a number with × (or *) and ÷ (or /). \"8h 15m × 3\" gives 24 Hours 45 Minutes, and \"1 day ÷ 4\" gives 6 Hours. Handy for shifts, billing, or splitting time evenly.",
  },
  {
    q: "What units does the time calculator support?",
    a: "Years, months, weeks, days, hours, minutes, seconds, and milliseconds. Type the full word or the shorthand (h, m, d, w, s), like \"1w 3d\", \"90 min\", or \"1d 4h 30m\". Months take \"mo\" so they don't clash with minutes.",
  },
  {
    q: "Is the time calculator free?",
    a: "The web version is free to use and is supported by ads. The Android app is free with no ads, with an optional donation if you want to support it. On iOS, a Pro upgrade unlocks the full app. Whichever you use, the calculation runs entirely on your device.",
  },
  {
    q: "Does the website give the same results as the app?",
    a: "Yes. The site runs the very same engine as the Cardamon apps, compiled for your browser, so the answer you get here matches the app down to the millisecond.",
  },
  {
    q: "Why doesn't typing \"2 + 2\" work?",
    a: "Every number needs a unit. \"2 + 2\" is ambiguous, but \"2h + 2h\" gives 4 Hours and \"2d + 2h\" gives 2 Days 2 Hours. The only bare number allowed is the multiplier or divisor, like the 3 in \"8h 15m × 3\". Always attach a unit to each value.",
  },
  {
    q: "How do I change the format of the result?",
    a: "Open the format picker and pick how the answer reads. Options include Hour Minute, Hour Minute Second, Day Hour Minute, Minute, Second, and Week Day. The same total stays fixed; only the wording changes, so \"450 minutes\" can show as 7 Hours 30 Minutes or 450 Minutes.",
  },
  {
    q: "How do I get a minutes and seconds (min:sec) result?",
    a: "Type your calculation, then choose the Minute Second format from the picker. \"3m 45s + 90s\" becomes 5 Minutes 15 Seconds. You can also pick plain Second to read it as 315 Seconds, or Hour Minute Second for longer durations. The format only changes how the answer is displayed.",
  },
  {
    q: "Does it work offline and in the browser?",
    a: "Yes. The web version runs entirely in your browser using the compiled calculation engine, so it keeps working with no connection once the page has loaded. The calculation never leaves your device. The Android and iOS apps run fully offline too.",
  },
  {
    q: "Are there any ads?",
    a: "It depends on the platform. The Android app is free and has no ads. The web version is free to use and is supported by ads. On iOS, you unlock the full version with a Pro purchase instead of ads. In every case the calculation runs on your device.",
  },
  {
    q: "Can results be negative?",
    a: "Yes. When you subtract a larger duration from a smaller one, the result goes negative. \"30m - 2h\" gives -1 Hour 30 Minutes. This is useful for tracking deficits, like time over or under a budgeted total, without forcing you to reorder the durations yourself.",
  },
  {
    q: "Does it handle milliseconds?",
    a: "Yes. Milliseconds are a supported unit, written as \"ms\". You can add, subtract, multiply, or divide them like any other unit, for example \"1s - 250ms\" gives 750 Milliseconds. It is one of the few time calculators that goes down to the millisecond, which audio and dev users rely on.",
  },
]

// "Get the mobile app" page content (generated, grounded in real Play reviews).
export interface ShowcaseUseCase { title: string; text: string; tag: string }
export interface Showcase {
  h1: string
  metaTitle: string
  metaDescription: string
  pitch: string
  useCases: ShowcaseUseCase[]
  features: string[]
  whyApp: string[]
}

export const SHOWCASE: Showcase = {
  "h1": "Get Time Calculator Cardamon on your phone",
  "metaTitle": "Get Time Calculator Cardamon for Android & iOS",
  "metaDescription": "Time Calculator Cardamon is free on Android (no ads), with an iOS version on the way. Add, subtract, multiply, and divide hours, minutes, and days. 4.6 stars.",
  "pitch": "Time Calculator Cardamon is free on Google Play, with an iOS version on the way. It runs the same engine as the website, so a sum like \"8h 15m × 3\" gives the exact same answer on your phone. The Android app has no ads and no sign-up, and your work timesheets are one tap away on your home screen.",
  "useCases": [
    {
      "title": "Work timesheets",
      "text": "Add up clock-in and clock-out blocks across a week and read the total in hours and minutes.",
      "tag": "Timesheets"
    },
    {
      "title": "Drivers logging hours",
      "text": "Truck and transport drivers track on-duty, drive, and break time without converting everything to minutes first.",
      "tag": "Transport"
    },
    {
      "title": "Audio and video editing",
      "text": "Work down to the millisecond, add clip lengths, and split a runtime into even segments.",
      "tag": "Editing"
    },
    {
      "title": "Billing and splitting time",
      "text": "Multiply a rate block by a number or divide a task evenly, like \"1 day ÷ 4\" for four people.",
      "tag": "Billing"
    },
    {
      "title": "Developers and converting",
      "text": "Convert a duration between days, hours, minutes, and seconds, then switch the result format to match your code.",
      "tag": "Dev"
    },
    {
      "title": "Everyday math",
      "text": "Cooking timers, workout sets, and fasting windows add up fast when you can type \"16h - 90m\" and just read the answer.",
      "tag": "Everyday"
    }
  ],
  "features": [
    "A fast keypad of number keys and time-unit keys, with the answer updating as you tap",
    "Add, subtract, multiply by a number, and divide durations",
    "Works in years, months, weeks, days, hours, minutes, seconds, and milliseconds",
    "Pick how the result reads: Hour Minute, Day Hour Minute, Minute Second, and more",
    "Customise the keypad: presets like Stopwatch or Media, or your own choice of unit keys",
    "Same engine as the website, so answers match down to the millisecond",
    "Light, dark, and system themes; resize the display with a draggable divider",
    "Android is free with no ads and no account required"
  ],
  "whyApp": [
    "One tap from your home screen, no browser or URL to find",
    "Works offline, so it keeps calculating with no signal on the job site",
    "Your calculation history stays saved on your device",
    "No ads and nothing tracking your sums; the math stays on your phone",
    "Faster keypad built for thumbs, with a layout you can resize to fit your hand"
  ]
}

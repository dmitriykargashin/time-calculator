// Time-unit conversion data. Powers /convert (the hub) and /convert/[pair]
// (one landing page per pair). Every `result` and every table row is real
// engine output, verified at build time, so a page never shows a wrong number.
export interface ConversionRow {
  label: string
  result: string
}
export interface ConversionFaq {
  q: string
  a: string
}
export interface Conversion {
  slug: string
  from: string
  to: string
  inverse: string | null
  metaTitle: string
  metaDescription: string
  h1: string
  question: string
  answer: string
  intro: string
  formula: string
  expr: string
  format: string
  result: string
  table: ConversionRow[]
  faqs: ConversionFaq[]
}

export const CONVERT_META = {
  metaTitle: "Time Unit Converter: Minutes, Hours, Seconds, Days",
  metaDescription: "Free time unit converter. Type a duration like 90 min or 3 days, pick a target format, and read the answer. Minutes to hours, seconds to minutes, days to hours, and more.",
  h1: "Time unit converter",
  intro: "Most time conversions are simple division or multiplication, but the right divisor is easy to forget under pressure. Is an hour 60 minutes or 100? How many hours sit in three days? This converter holds the rules so you do not have to. You type the duration the way you would say it, choose how the answer should read, and the calculator does the math. Each pair below also works as a quick reference you can read without typing anything.",
  answer: "Type a duration with its unit, then pick the result format you want. Enter \"90 min\" and choose Hour to get 1.5 Hours. The same input can be read as 90 minutes, 1.5 hours, or 5400 seconds just by switching formats. The converter handles minutes, hours, seconds, days, weeks, and milliseconds in one line.",
}

export const CONVERSIONS: Conversion[] = [
  {
    "slug": "minutes-to-hours",
    "from": "Minutes",
    "to": "Hours",
    "inverse": "hours-to-minutes",
    "metaTitle": "Minutes to Hours Converter | Time Calculator",
    "metaDescription": "Convert minutes to hours by dividing by 60. See why 90 minutes equals 1.5 hours, how to read decimal results, and convert any value with the live calculator.",
    "h1": "Minutes to Hours",
    "question": "How many hours is 90 minutes?",
    "answer": "90 minutes is 1.5 hours, because one hour is 60 minutes and 90 divided by 60 is 1.5. Choose the Hour format to read any duration as decimal hours.",
    "intro": "A 135-minute movie, a 50-minute lecture, a running app that logged 200 minutes this week: these read awkwardly until you turn them into hours. Divide the minutes by 60 and you get the answer in decimal hours. So 135 minutes becomes 2.25 hours.",
    "formula": "Divide the number of minutes by 60: 90 minutes ÷ 60 = 1.5 hours, and 240 minutes ÷ 60 = 4 hours.",
    "expr": "90 min",
    "format": "Hour",
    "result": "1.5 Hours",
    "table": [
      {
        "label": "15 Minutes",
        "result": "0.25 Hours"
      },
      {
        "label": "30 Minutes",
        "result": "0.5 Hours"
      },
      {
        "label": "45 Minutes",
        "result": "0.75 Hours"
      },
      {
        "label": "60 Minutes",
        "result": "1 Hour"
      },
      {
        "label": "90 Minutes",
        "result": "1.5 Hours"
      },
      {
        "label": "120 Minutes",
        "result": "2 Hours"
      },
      {
        "label": "150 Minutes",
        "result": "2.5 Hours"
      },
      {
        "label": "180 Minutes",
        "result": "3 Hours"
      },
      {
        "label": "240 Minutes",
        "result": "4 Hours"
      },
      {
        "label": "360 Minutes",
        "result": "6 Hours"
      },
      {
        "label": "480 Minutes",
        "result": "8 Hours"
      }
    ],
    "faqs": [
      {
        "q": "How many hours is 90 minutes?",
        "a": "90 minutes is 1.5 hours. Divide 90 by 60 to get 1.5. The 0.5 represents the extra 30 minutes past the first full hour, since 30 is exactly half of 60."
      },
      {
        "q": "Why does the result show as a decimal instead of hours and minutes?",
        "a": "Dividing by 60 gives decimal hours, so 100 minutes reads as 1.67 hours, not 1 hour 40 minutes. The decimal part is the leftover minutes over 60. Here 40 ÷ 60 rounds to 0.67."
      }
    ]
  },
  {
    "slug": "hours-to-minutes",
    "from": "Hours",
    "to": "Minutes",
    "inverse": "minutes-to-hours",
    "metaTitle": "Hours to Minutes Converter | Time Calculator",
    "metaDescription": "Convert hours to minutes by multiplying by 60. 1.5 hours is 90 minutes, 8 hours is 480. Use the live calculator and value table for any hours-to-minutes amount.",
    "h1": "Hours to Minutes",
    "question": "How many minutes is 2 hours?",
    "answer": "2 hours is 120 minutes, because each hour holds 60 minutes and 2 times 60 is 120. The Minute format returns the total as a single minute count.",
    "intro": "Recipe timers, parking meters, and billable work logs usually want minutes, but you start with a figure in hours like 1.5 or 8. To convert, multiply the hours by 60. A 2-hour movie runs 120 minutes; a 7.5-hour shift is 450 minutes.",
    "formula": "Multiply the number of hours by 60 to get total minutes: 3.25 hours x 60 = 195 minutes.",
    "expr": "2h",
    "format": "Minute",
    "result": "120 Minutes",
    "table": [
      {
        "label": "1 Hour",
        "result": "60 Minutes"
      },
      {
        "label": "2 Hours",
        "result": "120 Minutes"
      },
      {
        "label": "3 Hours",
        "result": "180 Minutes"
      },
      {
        "label": "4 Hours",
        "result": "240 Minutes"
      },
      {
        "label": "5 Hours",
        "result": "300 Minutes"
      },
      {
        "label": "6 Hours",
        "result": "360 Minutes"
      },
      {
        "label": "8 Hours",
        "result": "480 Minutes"
      },
      {
        "label": "10 Hours",
        "result": "600 Minutes"
      },
      {
        "label": "12 Hours",
        "result": "720 Minutes"
      },
      {
        "label": "24 Hours",
        "result": "1440 Minutes"
      }
    ],
    "faqs": [
      {
        "q": "How many minutes is 8 hours?",
        "a": "An 8-hour stretch equals 480 minutes, since 8 x 60 = 480. A standard 8-hour workday therefore covers 480 minutes of clocked time, or 28,800 seconds if you push the conversion one step further."
      },
      {
        "q": "How do I convert a fractional hour like 2.75 hours?",
        "a": "Multiply the whole decimal by 60. So 2.75 x 60 = 165 minutes. The 0.75 alone is 45 minutes (three quarters of an hour), which added to the 120 minutes from 2 hours gives the same 165."
      }
    ]
  },
  {
    "slug": "seconds-to-minutes",
    "from": "Seconds",
    "to": "Minutes",
    "inverse": "minutes-to-seconds",
    "metaTitle": "Seconds to Minutes Converter | Time Calculator",
    "metaDescription": "Convert seconds to minutes by dividing by 60. See how 90 seconds becomes 1 minute 30 seconds, 300 seconds equals 5 minutes, and any value in between.",
    "h1": "Seconds to Minutes",
    "question": "How many minutes is 300 seconds?",
    "answer": "300 seconds is 5 minutes, because a minute is 60 seconds and 300 divided by 60 is 5. Pick the Minute format to convert any number of seconds into minutes.",
    "intro": "A 4:32 song shows as 272 seconds in some audio editors, and a plank you held for 195 seconds is easier to log as 3 minutes 15 seconds. To switch between them, divide the seconds by 60. The whole-number part is your minutes; any remainder is leftover seconds.",
    "formula": "Divide the seconds by 60: 450 seconds / 60 = 7.5 minutes, which is 7 minutes and 30 seconds.",
    "expr": "300 sec",
    "format": "Minute",
    "result": "5 Minutes",
    "table": [
      {
        "label": "30 Seconds",
        "result": "0.5 Minutes"
      },
      {
        "label": "60 Seconds",
        "result": "1 Minute"
      },
      {
        "label": "90 Seconds",
        "result": "1.5 Minutes"
      },
      {
        "label": "120 Seconds",
        "result": "2 Minutes"
      },
      {
        "label": "150 Seconds",
        "result": "2.5 Minutes"
      },
      {
        "label": "180 Seconds",
        "result": "3 Minutes"
      },
      {
        "label": "240 Seconds",
        "result": "4 Minutes"
      },
      {
        "label": "300 Seconds",
        "result": "5 Minutes"
      },
      {
        "label": "600 Seconds",
        "result": "10 Minutes"
      },
      {
        "label": "900 Seconds",
        "result": "15 Minutes"
      }
    ],
    "faqs": [
      {
        "q": "How many minutes is 90 seconds?",
        "a": "90 seconds is 1.5 minutes. Dividing 90 by 60 gives 1 with a remainder of 30, so it reads as 1 minute and 30 seconds. The decimal form 1.5 and the 1:30 form describe the same duration."
      },
      {
        "q": "What if the seconds don't divide evenly by 60?",
        "a": "You get a remainder. For 200 seconds, 200 / 60 is 3 with 20 left over, so 3 minutes 20 seconds. The decimal version is about 3.33 minutes. To go back, multiply minutes by 60."
      }
    ]
  },
  {
    "slug": "minutes-to-seconds",
    "from": "Minutes",
    "to": "Seconds",
    "inverse": "seconds-to-minutes",
    "metaTitle": "Minutes to Seconds Converter | Time Calculator",
    "metaDescription": "Convert minutes to seconds by multiplying by 60. See why 1 minute is 60 seconds, how 2.5 minutes becomes 150, and convert any value with the live calculator.",
    "h1": "Minutes to Seconds",
    "question": "How many seconds is 5 minutes?",
    "answer": "5 minutes is 300 seconds, because one minute is 60 seconds and 5 times 60 is 300. The Second format gives the total in whole seconds.",
    "intro": "Coaches timing a 4-minute plank, podcast editors trimming an intro, and developers setting a cache that expires in minutes all end up working in raw seconds. One minute holds 60 seconds, so the conversion is a single multiplication. Enter the minutes below and read off the total second count.",
    "formula": "Multiply the minutes by 60 to get seconds: 7 minutes x 60 = 420 seconds, and a fractional value like 2.5 minutes x 60 = 150 seconds.",
    "expr": "5 min",
    "format": "Second",
    "result": "300 Seconds",
    "table": [
      {
        "label": "1 Minute",
        "result": "60 Seconds"
      },
      {
        "label": "2 Minutes",
        "result": "120 Seconds"
      },
      {
        "label": "3 Minutes",
        "result": "180 Seconds"
      },
      {
        "label": "5 Minutes",
        "result": "300 Seconds"
      },
      {
        "label": "10 Minutes",
        "result": "600 Seconds"
      },
      {
        "label": "15 Minutes",
        "result": "900 Seconds"
      },
      {
        "label": "20 Minutes",
        "result": "1200 Seconds"
      },
      {
        "label": "30 Minutes",
        "result": "1800 Seconds"
      },
      {
        "label": "45 Minutes",
        "result": "2700 Seconds"
      },
      {
        "label": "60 Minutes",
        "result": "3600 Seconds"
      }
    ],
    "faqs": [
      {
        "q": "How many seconds is 5 minutes?",
        "a": "5 minutes is 300 seconds, found by multiplying 5 by 60. The same rule scales cleanly: 10 minutes is 600 seconds and 15 minutes is 900 seconds, since every whole minute adds exactly 60 seconds to the running total."
      },
      {
        "q": "How do I convert seconds back into minutes?",
        "a": "Divide the seconds by 60 to reverse the conversion. So 300 seconds becomes 5 minutes. When the count is not a clean multiple of 60, like 200 seconds, you get 3 minutes with a remainder of 20 seconds left over."
      }
    ]
  },
  {
    "slug": "days-to-hours",
    "from": "Days",
    "to": "Hours",
    "inverse": "hours-to-days",
    "metaTitle": "Days to Hours Converter | Time Calculator Cardamon",
    "metaDescription": "Convert days to hours instantly. Multiply any number of days by 24 to get hours: 3 days = 72 hours, 7 days = 168 hours. Free, exact, runs in your browser.",
    "h1": "Days to Hours",
    "question": "How many hours is 3 days?",
    "answer": "3 days is 72 hours, because a day is 24 hours and 3 times 24 is 72. Use the Hour format to turn any number of days into total hours.",
    "intro": "Project planners and shift schedulers run this conversion when a task estimated in days has to slot into an hourly timesheet or a billing tool. A two-week sprint, for example, is easier to staff once you see it as 336 hours. The rule is simple: one day equals 24 hours, so multiply the day count by 24.",
    "formula": "Multiply the number of days by 24 to get hours, so 5 days × 24 = 120 hours.",
    "expr": "3 days",
    "format": "Hour",
    "result": "72 Hours",
    "table": [
      {
        "label": "1 Day",
        "result": "24 Hours"
      },
      {
        "label": "2 Days",
        "result": "48 Hours"
      },
      {
        "label": "3 Days",
        "result": "72 Hours"
      },
      {
        "label": "4 Days",
        "result": "96 Hours"
      },
      {
        "label": "5 Days",
        "result": "120 Hours"
      },
      {
        "label": "6 Days",
        "result": "144 Hours"
      },
      {
        "label": "7 Days",
        "result": "168 Hours"
      },
      {
        "label": "10 Days",
        "result": "240 Hours"
      },
      {
        "label": "14 Days",
        "result": "336 Hours"
      },
      {
        "label": "30 Days",
        "result": "720 Hours"
      }
    ],
    "faqs": [
      {
        "q": "How many hours is 7 days?",
        "a": "7 days is 168 hours. Multiply 7 by 24 to reach 168. That figure is the basis for a standard week, which is why weekly on-call rotations and 168-hour billing cycles line up exactly with seven full days."
      },
      {
        "q": "What if I have a fraction of a day, like 1.5 days?",
        "a": "Multiply the fractional day by 24 the same way. 1.5 days × 24 = 36 hours, and 2.25 days × 24 = 54 hours. To go the other direction, divide your hours by 24 to recover the days."
      }
    ]
  },
  {
    "slug": "hours-to-days",
    "from": "Hours",
    "to": "Days",
    "inverse": "days-to-hours",
    "metaTitle": "Hours to Days Converter | Time Calculator Cardamon",
    "metaDescription": "Convert hours to days by dividing by 24. See how 60 hours becomes 2 days 12 hours, with a live calculator and full value table for any number of hours.",
    "h1": "Hours to Days",
    "question": "How many days is 60 hours?",
    "answer": "60 hours is 2 days and 12 hours, because a day is 24 hours, 60 divided by 24 is 2 with 12 left over. The Day Hour format splits it into whole days plus the remaining hours.",
    "intro": "Render farm queued for 90 hours, a flight with two long layovers, a battery rated to last 200 hours of standby. Stated in raw hours, none of those land until you picture them in days. Divide the hours by 24 and the quotient is the day count, with any remainder staying as leftover hours.",
    "formula": "Divide the number of hours by 24: 90 hours divided by 24 equals 3.75, which reads as 3 days and 18 hours (the 0.75 of a day is 0.75 times 24, or 18 hours).",
    "expr": "60h",
    "format": "Day Hour",
    "result": "2 Days 12 Hours",
    "table": [
      {
        "label": "24 Hours",
        "result": "1 Day"
      },
      {
        "label": "36 Hours",
        "result": "1 Day 12 Hours"
      },
      {
        "label": "48 Hours",
        "result": "2 Days"
      },
      {
        "label": "60 Hours",
        "result": "2 Days 12 Hours"
      },
      {
        "label": "72 Hours",
        "result": "3 Days"
      },
      {
        "label": "96 Hours",
        "result": "4 Days"
      },
      {
        "label": "120 Hours",
        "result": "5 Days"
      },
      {
        "label": "168 Hours",
        "result": "7 Days"
      },
      {
        "label": "240 Hours",
        "result": "10 Days"
      }
    ],
    "faqs": [
      {
        "q": "How many days is 100 hours?",
        "a": "100 hours is 4 days and 4 hours. Dividing 100 by 24 gives 4 with a remainder of 4, so you get 4 full days plus the 4 hours that do not complete a fifth day."
      },
      {
        "q": "What is 48 hours in days, and how do I go back?",
        "a": "48 hours is exactly 2 days, since 48 divided by 24 leaves no remainder. To reverse the conversion, multiply days by 24: 2 days times 24 returns the original 48 hours."
      }
    ]
  },
  {
    "slug": "weeks-to-days",
    "from": "Weeks",
    "to": "Days",
    "inverse": "days-to-weeks",
    "metaTitle": "Weeks to Days Converter — Multiply Weeks by 7",
    "metaDescription": "Convert weeks to days fast. Multiply any number of weeks by 7 to get days (3 weeks = 21 days). Free converter, formula, and value table for whole or fractional weeks.",
    "h1": "Weeks to Days",
    "question": "How many days is 2 weeks?",
    "answer": "2 weeks is 14 days, because one week is 7 days and 2 times 7 is 14. Pick the Day format to convert any number of weeks into days.",
    "intro": "Counting down a 6-week recovery, a 12-week pregnancy milestone, or a 40-week project plan usually means thinking in days. The rule is fixed: every week is exactly 7 days, so 6 weeks is 42 days. Type your weeks below and the calculator returns the day count instantly.",
    "formula": "Multiply the number of weeks by 7 to get days: 4 weeks × 7 = 28 days, and 2.5 weeks × 7 = 17.5 days.",
    "expr": "2w",
    "format": "Day",
    "result": "14 Days",
    "table": [
      {
        "label": "1 Week",
        "result": "7 Days"
      },
      {
        "label": "2 Weeks",
        "result": "14 Days"
      },
      {
        "label": "3 Weeks",
        "result": "21 Days"
      },
      {
        "label": "4 Weeks",
        "result": "28 Days"
      },
      {
        "label": "6 Weeks",
        "result": "42 Days"
      },
      {
        "label": "8 Weeks",
        "result": "56 Days"
      },
      {
        "label": "12 Weeks",
        "result": "84 Days"
      },
      {
        "label": "52 Weeks",
        "result": "364 Days"
      }
    ],
    "faqs": [
      {
        "q": "How many days is 3 weeks?",
        "a": "Three weeks is 21 days, since 3 × 7 = 21. This is a full calendar count with no remainder, so a stay that starts on a Monday and lasts 3 weeks ends 21 days later on a Monday."
      },
      {
        "q": "What about half weeks or decimals like 1.5 weeks?",
        "a": "Multiply by 7 the same way. 1.5 weeks × 7 = 10.5 days, and 0.5 weeks is 3.5 days. The half day is real here because a week splits evenly into 7, so fractions carry straight through."
      }
    ]
  },
  {
    "slug": "milliseconds-to-seconds",
    "from": "Milliseconds",
    "to": "Seconds",
    "inverse": "seconds-to-milliseconds",
    "metaTitle": "Milliseconds to Seconds Converter | ms to s",
    "metaDescription": "Convert milliseconds to seconds by dividing by 1000. See how many seconds any millisecond value is, with the exact rule, a worked example, and answers to common questions.",
    "h1": "Milliseconds to Seconds",
    "question": "How many seconds is 2500 milliseconds?",
    "answer": "2500 milliseconds is 2.5 seconds, because a second is 1000 milliseconds and 2500 divided by 1000 is 2.5. The Second format reads milliseconds as seconds.",
    "intro": "When you read a page-load time of 850 ms in your browser's network panel or a 47000 ms timeout in a config file, you usually want it in seconds to reason about it. The conversion is one step: divide the millisecond count by 1000. So 850 ms becomes 0.85 seconds, and 47000 ms becomes 47 seconds.",
    "formula": "Divide the number of milliseconds by 1000 to get seconds: 2500 ms ÷ 1000 = 2.5 seconds, and 9000 ms ÷ 1000 = 9 seconds.",
    "expr": "2500 ms",
    "format": "Second",
    "result": "2.5 Seconds",
    "table": [
      {
        "label": "100 Milliseconds",
        "result": "0.1 Seconds"
      },
      {
        "label": "250 Milliseconds",
        "result": "0.25 Seconds"
      },
      {
        "label": "500 Milliseconds",
        "result": "0.5 Seconds"
      },
      {
        "label": "750 Milliseconds",
        "result": "0.75 Seconds"
      },
      {
        "label": "1000 Milliseconds",
        "result": "1 Second"
      },
      {
        "label": "1500 Milliseconds",
        "result": "1.5 Seconds"
      },
      {
        "label": "2000 Milliseconds",
        "result": "2 Seconds"
      },
      {
        "label": "2500 Milliseconds",
        "result": "2.5 Seconds"
      },
      {
        "label": "5000 Milliseconds",
        "result": "5 Seconds"
      }
    ],
    "faqs": [
      {
        "q": "How many seconds is 500 milliseconds?",
        "a": "500 milliseconds is 0.5 seconds, or half a second. Divide 500 by 1000 to get the answer. Any value under 1000 ms lands below one second, so 250 ms is 0.25 s and 750 ms is 0.75 s."
      },
      {
        "q": "How do I convert seconds back to milliseconds?",
        "a": "Go the other way by multiplying instead of dividing. Take the seconds and multiply by 1000, so 3 seconds is 3000 ms and 0.4 seconds is 400 ms. The factor of 1000 is the same in both directions."
      }
    ]
  },
  {
    "slug": "seconds-to-milliseconds",
    "from": "Seconds",
    "to": "Milliseconds",
    "inverse": "milliseconds-to-seconds",
    "metaTitle": "Seconds to Milliseconds Converter (s to ms)",
    "metaDescription": "Convert seconds to milliseconds by multiplying by 1000. See why 1 second is 1000 ms, work a quick example, and use the live calculator for any value.",
    "h1": "Seconds to Milliseconds",
    "question": "How many milliseconds is 3 seconds?",
    "answer": "3 seconds is 3000 milliseconds, because one second is 1000 milliseconds and 3 times 1000 is 3000. The MSecond format returns the total in milliseconds.",
    "intro": "Code expects milliseconds almost everywhere a delay shows up. A setTimeout call, a CSS animation duration, or an API timeout field all count in ms, so a 2-second pause has to be entered as 2000. To convert, multiply the seconds by 1000.",
    "formula": "Multiply the number of seconds by 1000 to get milliseconds: 7 seconds × 1000 = 7000 ms.",
    "expr": "3 sec",
    "format": "MSecond",
    "result": "3000 MSeconds",
    "table": [
      {
        "label": "1 Second",
        "result": "1000 MSeconds"
      },
      {
        "label": "2 Seconds",
        "result": "2000 MSeconds"
      },
      {
        "label": "3 Seconds",
        "result": "3000 MSeconds"
      },
      {
        "label": "5 Seconds",
        "result": "5000 MSeconds"
      },
      {
        "label": "10 Seconds",
        "result": "10000 MSeconds"
      },
      {
        "label": "15 Seconds",
        "result": "15000 MSeconds"
      },
      {
        "label": "30 Seconds",
        "result": "30000 MSeconds"
      },
      {
        "label": "60 Seconds",
        "result": "60000 MSeconds"
      }
    ],
    "faqs": [
      {
        "q": "How many milliseconds is 1.5 seconds?",
        "a": "1.5 seconds is 1500 milliseconds. Multiply 1.5 by 1000. Decimal seconds work cleanly because each whole second holds exactly 1000 ms, so half a second is 500 ms and a quarter second is 250 ms."
      },
      {
        "q": "How do I convert milliseconds back to seconds?",
        "a": "Divide the milliseconds by 1000. So 4500 ms becomes 4.5 seconds, and 250 ms becomes 0.25 seconds. It is the exact inverse of the seconds-to-milliseconds step, where you multiply by 1000 instead."
      }
    ]
  },
  {
    "slug": "seconds-to-hours",
    "from": "Seconds",
    "to": "Hours",
    "inverse": "hours-to-seconds",
    "metaTitle": "Seconds to Hours Converter | Time Calculator",
    "metaDescription": "Convert seconds to hours by dividing by 3600. See why 7200 seconds equals 2 hours, how to read decimal results, and convert any value with the live calculator.",
    "h1": "Seconds to Hours",
    "question": "How many hours is 7200 seconds?",
    "answer": "7200 seconds is 2 hours, because one hour is 3600 seconds and 7200 divided by 3600 is 2. To convert seconds to hours, divide the second count by 3600. Choose the Hour format to read any duration in seconds as decimal hours.",
    "intro": "Stopwatch exports, API logs, and video runtimes often report raw seconds, and a figure like 9000 seconds says little on its own. Divide the seconds by 3600 and you get decimal hours. So 9000 seconds becomes 2.5 hours, and 5400 seconds becomes 1.5 hours.",
    "formula": "Divide the number of seconds by 3600: 7200 seconds ÷ 3600 = 2 hours, and 5400 seconds ÷ 3600 = 1.5 hours.",
    "expr": "7200 seconds",
    "format": "Hour",
    "result": "2 Hours",
    "table": [
      {
        "label": "900 Seconds",
        "result": "0.25 Hours"
      },
      {
        "label": "1800 Seconds",
        "result": "0.5 Hours"
      },
      {
        "label": "2700 Seconds",
        "result": "0.75 Hours"
      },
      {
        "label": "3600 Seconds",
        "result": "1 Hour"
      },
      {
        "label": "5400 Seconds",
        "result": "1.5 Hours"
      },
      {
        "label": "7200 Seconds",
        "result": "2 Hours"
      },
      {
        "label": "10800 Seconds",
        "result": "3 Hours"
      },
      {
        "label": "18000 Seconds",
        "result": "5 Hours"
      },
      {
        "label": "28800 Seconds",
        "result": "8 Hours"
      },
      {
        "label": "43200 Seconds",
        "result": "12 Hours"
      },
      {
        "label": "86400 Seconds",
        "result": "24 Hours"
      }
    ],
    "faqs": [
      {
        "q": "How many hours is 3600 seconds?",
        "a": "3600 seconds is exactly 1 hour. An hour holds 60 minutes of 60 seconds each, and 60 × 60 = 3600. Every multiple follows the same rule: 7200 seconds is 2 hours and 10800 seconds is 3 hours."
      },
      {
        "q": "How do I read an uneven value like 10000 seconds?",
        "a": "Divide by 3600 the same way. 10000 ÷ 3600 gives 2.7777778 hours, which the calculator prints as 2.7777778 Hours. The decimal part is the leftover 2800 seconds expressed as a fraction of the 3600-second hour."
      }
    ]
  },
  {
    "slug": "hours-to-seconds",
    "from": "Hours",
    "to": "Seconds",
    "inverse": "seconds-to-hours",
    "metaTitle": "Hours to Seconds Converter | Time Calculator",
    "metaDescription": "Convert hours to seconds by multiplying by 3600. 1 hour is 3600 seconds and 2 hours is 7200. Use the live calculator and full value table for any hour count.",
    "h1": "Hours to Seconds",
    "question": "How many seconds is 2 hours?",
    "answer": "2 hours is 7200 seconds, because each hour holds 3600 seconds and 2 times 3600 is 7200. To convert hours to seconds, multiply the hours by 3600. The Second format returns any duration as a single second count, so 1.5 hours reads as 5400 Seconds.",
    "intro": "Countdown timers, video encoders, and cron settings usually want raw seconds while you think in hours. Multiply the hours by 3600 to convert. A 2-hour timer counts down 7200 seconds; a 45-minute session, entered as 0.75 hours, runs 2700 seconds.",
    "formula": "Multiply the number of hours by 3600 to get total seconds: 2 hours × 3600 = 7200 seconds, and 2.5 hours × 3600 = 9000 seconds.",
    "expr": "2h",
    "format": "Second",
    "result": "7200 Seconds",
    "table": [
      {
        "label": "0.5 Hours",
        "result": "1800 Seconds"
      },
      {
        "label": "1 Hour",
        "result": "3600 Seconds"
      },
      {
        "label": "1.5 Hours",
        "result": "5400 Seconds"
      },
      {
        "label": "2 Hours",
        "result": "7200 Seconds"
      },
      {
        "label": "3 Hours",
        "result": "10800 Seconds"
      },
      {
        "label": "4 Hours",
        "result": "14400 Seconds"
      },
      {
        "label": "6 Hours",
        "result": "21600 Seconds"
      },
      {
        "label": "8 Hours",
        "result": "28800 Seconds"
      },
      {
        "label": "12 Hours",
        "result": "43200 Seconds"
      },
      {
        "label": "24 Hours",
        "result": "86400 Seconds"
      }
    ],
    "faqs": [
      {
        "q": "How many seconds are in 1 hour?",
        "a": "One hour is 3600 seconds. An hour has 60 minutes, each minute has 60 seconds, and 60 × 60 = 3600. That constant sits behind every row in the table above."
      },
      {
        "q": "How many seconds is an 8-hour workday?",
        "a": "8 hours is 28800 seconds, since 8 × 3600 = 28800. A full 24-hour day comes to 86400 seconds, which is why Unix timestamps advance by 86400 between one midnight and the next."
      },
      {
        "q": "How do I convert a fractional value like 1.5 hours?",
        "a": "Multiply by 3600 the same way. 1.5 × 3600 = 5400 seconds: 3600 from the full hour plus 1800 from the half. Any decimal carries straight through the multiplication."
      }
    ]
  },
  {
    "slug": "days-to-weeks",
    "from": "Days",
    "to": "Weeks",
    "inverse": "weeks-to-days",
    "metaTitle": "Days to Weeks Converter | Time Calculator",
    "metaDescription": "Convert days to weeks by dividing by 7. 14 days is 2 weeks and 21 days is 3. Free converter, formula, and value table for whole and fractional day counts.",
    "h1": "Days to Weeks",
    "question": "How many weeks is 14 days?",
    "answer": "14 days is 2 weeks, because one week is 7 days and 14 divided by 7 is 2. To convert days to weeks, divide the day count by 7. Pick the Week format to read any number of days as weeks, so 21 days returns 3 Weeks.",
    "intro": "A 42-day training block, a 63-day notice period, a return window counted in days: these read better as weeks. Divide the days by 7 and you have the answer. So 42 days becomes 6 weeks, and 63 days becomes 9 weeks. Day counts that do not divide evenly print as decimals, so 30 days reads as 4.2857143 weeks.",
    "formula": "Divide the number of days by 7 to get weeks: 14 days ÷ 7 = 2 weeks, and 3.5 days ÷ 7 = 0.5 weeks.",
    "expr": "14 days",
    "format": "Week",
    "result": "2 Weeks",
    "table": [
      {
        "label": "3.5 Days",
        "result": "0.5 Weeks"
      },
      {
        "label": "7 Days",
        "result": "1 Week"
      },
      {
        "label": "10.5 Days",
        "result": "1.5 Weeks"
      },
      {
        "label": "14 Days",
        "result": "2 Weeks"
      },
      {
        "label": "21 Days",
        "result": "3 Weeks"
      },
      {
        "label": "28 Days",
        "result": "4 Weeks"
      },
      {
        "label": "35 Days",
        "result": "5 Weeks"
      },
      {
        "label": "49 Days",
        "result": "7 Weeks"
      },
      {
        "label": "70 Days",
        "result": "10 Weeks"
      },
      {
        "label": "84 Days",
        "result": "12 Weeks"
      }
    ],
    "faqs": [
      {
        "q": "How many weeks is 30 days?",
        "a": "30 days is 4.2857143 weeks, because 30 ÷ 7 leaves a remainder. The whole part covers 4 full weeks (28 days), and the leftover 2 days divide by 7 to give the 0.2857143. For calendar planning, read it as 4 weeks and 2 days."
      },
      {
        "q": "How many weeks are in 365 days?",
        "a": "365 days is 52.1428571 weeks. A common year covers 52 full weeks (364 days) plus one extra day, which is why the same date falls one weekday later each common year."
      },
      {
        "q": "How many weeks is a 90-day period?",
        "a": "90 days is 12.8571429 weeks. The first 84 days make 12 full weeks, and the remaining 6 days add 0.8571429. A 90-day trial therefore runs a little under 13 weeks."
      }
    ]
  },
  {
    "slug": "years-to-days",
    "from": "Years",
    "to": "Days",
    "inverse": "days-to-years",
    "metaTitle": "Years to Days Converter | Time Calculator",
    "metaDescription": "Convert years to days by multiplying by 365. 1 year is 365 days and 2 years is 730. See the formula, a value table, and a live calculator for any year count.",
    "h1": "Years to Days",
    "question": "How many days is 2 years?",
    "answer": "2 years is 730 days, because the calculator counts each year as 365 days and 2 times 365 is 730. To convert years to days, multiply the years by 365. Choose the Day format to turn any year count into days, so 5 years returns 1825 Days.",
    "intro": "Loan terms, warranty periods, and age milestones often start as years and end up needing a day count. Multiply the years by 365 to convert. A 3-year warranty covers 1095 days; a 10-year plan spans 3650 days. The calculator uses a fixed 365-day year, so leap days stay out of the count.",
    "formula": "Multiply the number of years by 365 to get days: 2 years × 365 = 730 days, and 0.5 years × 365 = 182.5 days.",
    "expr": "2 years",
    "format": "Day",
    "result": "730 Days",
    "table": [
      {
        "label": "0.5 Years",
        "result": "182.5 Days"
      },
      {
        "label": "1 Year",
        "result": "365 Days"
      },
      {
        "label": "2 Years",
        "result": "730 Days"
      },
      {
        "label": "3 Years",
        "result": "1095 Days"
      },
      {
        "label": "4 Years",
        "result": "1460 Days"
      },
      {
        "label": "5 Years",
        "result": "1825 Days"
      },
      {
        "label": "10 Years",
        "result": "3650 Days"
      },
      {
        "label": "20 Years",
        "result": "7300 Days"
      },
      {
        "label": "50 Years",
        "result": "18250 Days"
      },
      {
        "label": "100 Years",
        "result": "36500 Days"
      }
    ],
    "faqs": [
      {
        "q": "How many days are in 1 year?",
        "a": "One year is 365 days in this converter. Calendar years alternate between 365 and 366 days because of leap years, but for duration math the fixed 365-day year keeps every result consistent: 4 years is 1460 days rather than the calendar's 1461."
      },
      {
        "q": "How many days is 1.5 years?",
        "a": "1.5 years is 547.5 days, since 1.5 × 365 = 547.5. The full year contributes 365 days and the half year adds 182.5. Fractions carry straight through the multiplication."
      },
      {
        "q": "How many days is 7 years?",
        "a": "7 years is 2555 days, because 7 × 365 = 2555. On the calendar the same span usually includes one or two leap days on top, so a 7-year anniversary lands 2556 or 2557 calendar days after the start."
      }
    ]
  },
  {
    "slug": "days-to-years",
    "from": "Days",
    "to": "Years",
    "inverse": "years-to-days",
    "metaTitle": "Days to Years Converter | Time Calculator",
    "metaDescription": "Convert days to years by dividing by 365. 730 days is 2 years and 1825 days is 5. Read decimal results like 2.739726 years and convert any day count instantly.",
    "h1": "Days to Years",
    "question": "How many years is 730 days?",
    "answer": "730 days is 2 years, because the calculator counts each year as 365 days and 730 divided by 365 is 2. To convert days to years, divide the day count by 365. Pick the Year format to read any number of days as decimal years.",
    "intro": "A 1000-day streak, a sobriety counter, a service record kept in days: at some point you want the figure in years. Divide the days by 365 and you have it. So 1825 days becomes 5 years, and 1000 days becomes 2.739726 years on the fixed 365-day year this calculator uses.",
    "formula": "Divide the number of days by 365 to get years: 730 days ÷ 365 = 2 years, and 182.5 days ÷ 365 = 0.5 years.",
    "expr": "730 days",
    "format": "Year",
    "result": "2 Years",
    "table": [
      {
        "label": "73 Days",
        "result": "0.2 Years"
      },
      {
        "label": "182.5 Days",
        "result": "0.5 Years"
      },
      {
        "label": "365 Days",
        "result": "1 Year"
      },
      {
        "label": "730 Days",
        "result": "2 Years"
      },
      {
        "label": "1095 Days",
        "result": "3 Years"
      },
      {
        "label": "1825 Days",
        "result": "5 Years"
      },
      {
        "label": "3650 Days",
        "result": "10 Years"
      },
      {
        "label": "7300 Days",
        "result": "20 Years"
      },
      {
        "label": "18250 Days",
        "result": "50 Years"
      },
      {
        "label": "36500 Days",
        "result": "100 Years"
      }
    ],
    "faqs": [
      {
        "q": "How many years is 10000 days?",
        "a": "10000 days is 27.3972603 years on the 365-day year this calculator uses. Divide 10000 by 365 to get it. The 10000th day of a life lands a few months after the 27th birthday."
      },
      {
        "q": "How many years is 500 days?",
        "a": "500 days is 1.369863 years. The first 365 days complete one year, and the remaining 135 days divide by 365 to give the 0.369863. Call it 1 year and about 4.5 months."
      },
      {
        "q": "Does the converter account for leap years?",
        "a": "No. It uses a fixed 365-day year, so 730 days always returns 2 years. Calendar spans that cross a leap day run one day longer, which shifts the decimal by about 0.003 years per leap day."
      }
    ]
  }
]

export function getConversion(slug: string): Conversion | undefined {
  return CONVERSIONS.find((c) => c.slug === slug)
}

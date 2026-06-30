// Use-case / how-to guides. Content is generated + engine-verified (every
// example result is the actual engine output). The hub (/guides) and the
// per-guide page (/guides/[slug]) read from here; prerender crawlLinks makes
// each one static.
export interface GuideStep { title: string; body: string }
export interface GuideExample { expr: string; format: string; result: string; note: string }
export interface GuideFaq { q: string; a: string }
export interface Guide {
  slug: string
  query: string
  h1: string
  metaTitle: string
  metaDescription: string
  answer: string
  intro: string
  steps: GuideStep[]
  examples: GuideExample[]
  faqs: GuideFaq[]
  related: string[]
  useCaseLine: string
}

// Last content review — feeds dateModified in the per-guide schema.
export const GUIDE_UPDATED = '2026-06-30'

export const GUIDES: Guide[] = [
  {
    "slug": "add-hours-and-minutes",
    "query": "add up hours and minutes",
    "h1": "How do I add up hours and minutes?",
    "metaTitle": "Add Up Hours and Minutes (Free Time Calculator)",
    "metaDescription": "Add up hours and minutes in one line. Type each duration like 8h 15m, join them with +, and pick a format. Free time calculator for timesheets, web and apps.",
    "answer": "Type each duration with its unit, join them with a plus sign, and the calculator returns one clean total. For example, enter \"8h 15m + 7h 45m\" on a single line. Pick a result format like \"Hour Minute,\" and it carries every 60 minutes into an hour for you automatically.",
    "intro": "Adding hours and minutes by hand means tracking two columns and carrying every 60 minutes into the next hour. It is the kind of arithmetic that is easy to fumble at the end of a long week. This calculator handles the carrying for you. You write the durations the way you would say them, and it returns one total in whatever format you choose.",
    "useCaseLine": "Reviewers like Sharon Lloyd use it to total their work timesheets, which makes doing timesheets for work much easier.",
    "steps": [
      {
        "title": "Write each duration with its unit",
        "body": "Every number needs a unit. Type hours as h and minutes as m, so a shift becomes 8h 15m. You can write 8h, 45m, or 8h 15m, but never a bare 8.25. The unit is what tells the calculator whether you mean hours or minutes."
      },
      {
        "title": "Join the durations with a plus sign",
        "body": "Put a + between each entry and keep everything on one line: 8h 15m + 7h 45m + 8h 30m. Add as many shifts as you need. To take time off, use a minus sign, like 9h 30m - 45m for an unpaid lunch break."
      },
      {
        "title": "Pick a result format",
        "body": "Choose how the total reads from the format picker. Hour Minute gives you something like 40 Hours 25 Minutes for payroll. Day Hour Minute is handy when a total runs past 24 hours, and Minute gives a single number when you need to multiply by a rate."
      },
      {
        "title": "Read the carried total",
        "body": "The calculator rolls every 60 minutes into an hour, so you never see a result like 39 Hours 85 Minutes. The same expression can be shown in several formats, so switch the picker to view the same total as hours, days, or plain minutes."
      }
    ],
    "examples": [
      {
        "expr": "8h 15m + 7h 45m + 8h 30m + 6h 50m + 9h 5m",
        "format": "Hour Minute",
        "result": "40 Hours 25 Minutes",
        "note": "Five daily shifts added into one weekly timesheet total."
      },
      {
        "expr": "8h 15m + 7h 45m + 8h 30m + 6h 50m + 9h 5m",
        "format": "Day Hour Minute",
        "result": "1 Day 16 Hours 25 Minutes",
        "note": "The same week shown as days, hours, and minutes when the total tops 24 hours."
      },
      {
        "expr": "9h 30m - 45m",
        "format": "Hour Minute",
        "result": "8 Hours 45 Minutes",
        "note": "Subtract an unpaid lunch break from a single shift."
      },
      {
        "expr": "8h 15m × 5",
        "format": "Hour Minute",
        "result": "41 Hours 15 Minutes",
        "note": "Multiply one identical shift by five days instead of typing it five times."
      }
    ],
    "faqs": [
      {
        "q": "Do I have to convert minutes into decimals first?",
        "a": "No. Type the minutes as minutes, like 45m, and leave them alone. The calculator does the carrying, so 8h 15m + 7h 45m comes out as a clean hours-and-minutes total. You never have to turn 45 minutes into 0.75 by hand."
      },
      {
        "q": "What if my total goes over 24 hours?",
        "a": "It still works. A full week of shifts can easily pass 40 hours, and the calculator shows it correctly in Hour Minute. Switch the format to Day Hour Minute if you would rather see it broken into days, hours, and minutes."
      },
      {
        "q": "Can I subtract a break from the total?",
        "a": "Yes. Use a minus sign for any time you need to remove, such as 9h 30m - 45m to drop a 45 minute lunch. You can mix plus and minus signs in the same line to add shifts and subtract breaks together."
      }
    ],
    "related": [
      "timesheet-total-hours",
      "hours-worked-between-two-times",
      "add-and-subtract-time"
    ]
  },
  {
    "slug": "hours-worked-between-two-times",
    "query": "hours worked between two times",
    "h1": "How do you calculate hours worked between two times?",
    "metaTitle": "Hours Worked Between Two Times: How to Calculate",
    "metaDescription": "Calculate hours worked between two clock times. Write each time as hours and minutes from midnight, then subtract: 17h 45m - 9h 15m gives 8 Hours 30 Minutes.",
    "answer": "Write each clock time as hours and minutes counted from midnight, then subtract the start from the end. So 9:15 becomes 9h 15m, 17:45 becomes 17h 45m, and typing 17h 45m - 9h 15m gives 8 Hours 30 Minutes. The calculator does the borrow. It works for same-day shifts; for an overnight, add 24h to the end.",
    "intro": "The trick is to treat each clock time as a duration counted from midnight. Quarter past nine in the morning is 9h 15m into the day; quarter to six in the evening is 17h 45m. Subtract one from the other and you have the shift length, with the awkward minute borrow handled for you. This holds as long as both times fall on the same day.",
    "useCaseLine": "A warehouse worker reads clock-in and clock-out times off a paper card and needs the paid hours per shift, lunch removed, before submitting the week.",
    "steps": [
      {
        "title": "Write each clock time as hours and minutes",
        "body": "Count from midnight on a 24-hour clock. 9:15 in the morning is 9h 15m. 5:45 in the evening is 17:45, which is 17h 45m. Afternoon and evening times pass 12, so 2 p.m. is 14h, not 2h."
      },
      {
        "title": "Subtract the start from the end",
        "body": "Put the later time first and subtract the earlier one: 17h 45m - 9h 15m. The calculator borrows across the hour for you, so you skip the carry-the-minutes step. The answer is the shift length."
      },
      {
        "title": "For an overnight shift, add 24h",
        "body": "When the clock-out is the next morning, add a day to it. A 22:00 to 06:00 shift is 6h + 24h - 22h, which comes to 8 Hours. The +24h carries the end time past midnight so the subtraction stays positive."
      },
      {
        "title": "Subtract breaks and pick a format",
        "body": "Take off an unpaid lunch with another minus, like 17h 45m - 9h 15m - 30m. Choose Hour Minute for payroll, or chain whole shifts with + to total a day or a week."
      }
    ],
    "examples": [
      {
        "expr": "17h 45m - 9h 15m",
        "format": "Hour Minute",
        "result": "8 Hours 30 Minutes",
        "note": "A 9:15 to 17:45 shift, by subtracting the two clock times written as durations from midnight."
      },
      {
        "expr": "17h 45m - 9h 15m - 30m",
        "format": "Hour Minute",
        "result": "8 Hours",
        "note": "The same shift with a 30-minute unpaid lunch removed."
      },
      {
        "expr": "6h + 24h - 22h",
        "format": "Hour Minute",
        "result": "8 Hours",
        "note": "An overnight 22:00 to 06:00 shift: add 24h to the 6 a.m. clock-out."
      },
      {
        "expr": "8h 30m + 7h 45m",
        "format": "Hour Minute",
        "result": "16 Hours 15 Minutes",
        "note": "Add two finished shift lengths into a running total."
      }
    ],
    "faqs": [
      {
        "q": "Can I just type the clock times like 9:15 and 17:45?",
        "a": "Not with a colon, but you get the same answer a different way. Write each time as hours and minutes from midnight (9:15 is 9h 15m, 17:45 is 17h 45m) and subtract: 17h 45m - 9h 15m gives 8 Hours 30 Minutes. This works for any two times in the same day."
      },
      {
        "q": "How do I handle a shift that crosses midnight?",
        "a": "Add 24h to the clock-out time, since it falls the next day. A 22:00 to 06:00 shift is 6h + 24h - 22h, which is 8 Hours. Without the +24h the subtraction would go negative, because 6 is less than 22."
      },
      {
        "q": "How do I subtract a lunch break?",
        "a": "Add another minus to the same line. A 9:15 to 17:45 shift with a 30-minute lunch is 17h 45m - 9h 15m - 30m, which gives 8 Hours. Chain more minus signs to remove several breaks."
      }
    ],
    "related": [
      "add-hours-and-minutes",
      "timesheet-total-hours",
      "add-and-subtract-time"
    ]
  },
  {
    "slug": "add-and-subtract-time",
    "query": "add and subtract time",
    "h1": "How do I add and subtract time durations across units?",
    "metaTitle": "Add and Subtract Time Durations Across Units",
    "metaDescription": "Add and subtract time across hours, minutes, days, and weeks in one line. Type \"2 days - 4h\" and read the result in any format. Free, no conversion needed.",
    "answer": "Type each duration with its unit on one line, separated by + or -, like \"2 days - 4h\" or \"5h 30m + 2h 15m\". The calculator handles mixed units for you, so you never convert to minutes first. Pick a result format such as Hour Minute or Day Hour Minute to read the answer.",
    "intro": "Most time math goes wrong at the unit boundaries. You add 50 minutes to 40 minutes and have to remember it rolls past an hour, or you subtract 4 hours from 2 days and stall on the borrow. This tool keeps the units intact. You write the durations the way you say them, mix hours with days with weeks, and it carries and borrows across the boundaries on its own.",
    "useCaseLine": "A scheduler blocks out two full days for a task, then trims four hours for a meeting and needs the remaining duration without doing the borrow in their head.",
    "steps": [
      {
        "title": "Write each duration with its unit",
        "body": "Every number needs a unit attached. Use h or hour, m or minute, d or day, w or week, s or second. So you type 2 days, not 2, and 30m, not 30. You can glue parts together like 5h 30m to mean five hours and thirty minutes."
      },
      {
        "title": "Join durations with + and -",
        "body": "Put a plus to add and a minus to subtract between durations, on one line. Chain as many as you like: 1w 3d + 2 days - 4h is valid. The units can differ at every step, so weeks, days, and hours sit side by side in the same expression."
      },
      {
        "title": "Let it carry and borrow across units",
        "body": "You do not convert anything to minutes first. Subtract 4h from 2 days and the calculator borrows from the day for you. Add minutes past 60 and they roll into the next hour. The running total stays exact across every unit you mix in."
      },
      {
        "title": "Choose how the result reads",
        "body": "Pick a format from the picker. Hour Minute gives an answer like 7 Hours 45 Minutes. Day Hour Minute breaks a long total into days and hours. Week Day groups it into weeks. The same expression can be read in whichever unit fits."
      }
    ],
    "examples": [
      {
        "expr": "5h 30m + 2h 15m",
        "format": "Hour Minute",
        "result": "7 Hours 45 Minutes",
        "note": "Adding two hour-and-minute durations; the minutes carry past 60 cleanly."
      },
      {
        "expr": "2 days - 4h",
        "format": "Day Hour Minute",
        "result": "1 Day 20 Hours",
        "note": "Subtracting hours from days borrows across the unit boundary, no conversion needed."
      },
      {
        "expr": "1 day + 12h 30m",
        "format": "Day Hour Minute",
        "result": "1 Day 12 Hours 30 Minutes",
        "note": "Mixing a whole day with hours and minutes in one expression."
      },
      {
        "expr": "1w - 2d",
        "format": "Week Day",
        "result": "5 Days",
        "note": "Subtracting days from a week, read back in week and day terms."
      }
    ],
    "faqs": [
      {
        "q": "Do I have to convert everything to minutes first?",
        "a": "No. That is the point. You can write 2 days - 4h directly and the calculator borrows across the day, hour, and minute boundaries for you. Each number keeps its own unit, and the running total stays exact no matter which units you mix."
      },
      {
        "q": "Can I mix hours, days, and weeks in the same calculation?",
        "a": "Yes. An expression like 1w 3d + 2 days - 4h is valid. Units can differ at every step. The calculator combines them into one total, then shows it in whatever result format you pick, such as Day Hour Minute or Week Day."
      },
      {
        "q": "Why does my result show a decimal in some formats?",
        "a": "A format only carries down to its smallest listed unit. If you choose Week Day and the total has a leftover smaller than a day, it appears as a fraction of a day. Switch to Day Hour Minute or Hour Minute to see that remainder as whole hours and minutes."
      }
    ],
    "related": [
      "add-hours-and-minutes",
      "convert-time-units",
      "multiply-and-divide-time"
    ]
  },
  {
    "slug": "timesheet-total-hours",
    "query": "total timesheet hours",
    "answer": "To total timesheet or time card hours, type each day's worked time as a duration and add them with plus signs on one line, like 8h 12m + 7h 48m + 8h 30m, then pick a result format such as Hour Minute. The calculator carries minutes over into whole hours and shows the weekly total instantly.",
    "h1": "How do I total the hours on a weekly timesheet?",
    "metaTitle": "Total Timesheet Hours: Add Up a Week Fast",
    "metaDescription": "Add up your weekly timesheet or time card hours in seconds. Type each day as hours and minutes, hit plus, and get a clean Hour Minute total. Free, in your browser.",
    "intro": "Adding hours and minutes by hand is where timesheets go wrong: 45 plus 50 minutes is not 95, it rolls into an extra hour. This calculator handles that carry for you. Type each shift as a duration, join them with plus signs, and read the weekly total. Drivers, hourly staff, and freelancers use the same one-line method every week.",
    "useCaseLine": "A truck driver logging different start and finish times every day can type all five shifts on one line and get the week's payable total without touching a spreadsheet.",
    "steps": [
      {
        "title": "Write each day as a duration",
        "body": "For every day you worked, write the hours and minutes together: 8h 12m, 7h 48m, 9h 6m. Every number needs a unit, so use h for hours and m for minutes. There is no need to convert minutes to decimals first."
      },
      {
        "title": "Join the days with plus signs",
        "body": "Put a + between each day on a single line: 8h 12m + 7h 48m + 8h 30m + 9h 6m + 7h 54m. Add as many days as you like. The order does not matter, and the calculator updates as you type."
      },
      {
        "title": "Pick a result format",
        "body": "Choose Hour Minute for a normal weekly total. The calculator rolls extra minutes into whole hours automatically, so you never end up with 90-minute remainders. Use Day Hour Minute when a heavy week passes 24 hours of driving."
      },
      {
        "title": "Adjust and reformat without retyping",
        "body": "Subtract an unpaid break with a minus sign, or switch the format to Minute to see the total in plain minutes for a payroll system. The same expression re-totals instantly in whichever unit you need."
      }
    ],
    "examples": [
      {
        "expr": "8h 12m + 7h 48m + 8h 30m + 9h 6m + 7h 54m",
        "format": "Hour Minute",
        "result": "41 Hours 30 Minutes",
        "note": "A standard five-day week summed into one clean total, minutes carried into hours."
      },
      {
        "expr": "10h 30m + 9h 15m + 11h + 8h 45m + 10h 20m",
        "format": "Day Hour Minute",
        "result": "2 Days 1 Hour 50 Minutes",
        "note": "A heavy driving week passes 24 hours, so Day Hour Minute breaks it down clearly."
      },
      {
        "expr": "8h 15m × 5",
        "format": "Hour Minute",
        "result": "41 Hours 15 Minutes",
        "note": "Five identical 8h 15m shifts multiplied by a plain number instead of adding each one."
      },
      {
        "expr": "45h 50m - 5h",
        "format": "Hour Minute",
        "result": "40 Hours 50 Minutes",
        "note": "Subtract unpaid break time from a running weekly total with a minus sign."
      }
    ],
    "faqs": [
      {
        "q": "Do I have to convert minutes into decimals first?",
        "a": "No. Type minutes as minutes, like 7h 48m. The calculator handles the 60-minute carry itself, so 45m plus 50m correctly becomes 1 hour 35 minutes instead of 95."
      },
      {
        "q": "How do I subtract an unpaid lunch or break?",
        "a": "Use a minus sign in the same line. For example, 42h 30m - 30m removes a half-hour break, and the calculator returns the adjusted payable total."
      },
      {
        "q": "Can I see the total in plain hours or minutes for payroll?",
        "a": "Yes. Switch the result format. Pick Minute to get the whole week as a single minute count, or Hour Minute for hours and minutes. The same expression re-totals instantly."
      }
    ],
    "related": [
      "add-hours-and-minutes",
      "hours-worked-between-two-times",
      "add-and-subtract-time"
    ]
  },
  {
    "slug": "multiply-and-divide-time",
    "query": "multiply or split time",
    "answer": "To multiply or split a duration, type the time block, then × or ÷ with a plain number: \"8h 15m × 3\" repeats the block three times, and \"1 day ÷ 4\" splits a day into four equal parts. Pick a result format like Hour Minute, and the calculator returns the total instantly.",
    "h1": "How do I multiply or split a time duration?",
    "metaTitle": "Multiply or Split Time: Repeat or Divide a Duration",
    "metaDescription": "Multiply or split a time duration in seconds. Type \"8h 15m × 3\" to repeat a block or \"1 day ÷ 4\" to divide it evenly. Free, right in your browser.",
    "intro": "Multiplying and dividing time is the awkward part of any time math, because you cannot just multiply hours and minutes separately the way you would whole numbers. This calculator handles the carrying for you. You type the block once, multiply by how many times it repeats, or divide by how many ways you are splitting it, and read the answer in whatever unit you need.",
    "useCaseLine": "A freelancer billing a 45-minute task across six clients, or a manager splitting a workday evenly between four people, needs exact totals without doing carry-the-hour arithmetic by hand.",
    "steps": [
      {
        "title": "Type the duration block",
        "body": "Write the time you want to repeat or split, with a unit on every number. For example, type \"8h 15m\" for an eight-and-a-quarter-hour shift, or \"45m\" for a short task. A bare number with no unit is only allowed as the multiplier or divisor."
      },
      {
        "title": "Add × to multiply or ÷ to divide",
        "body": "Follow the block with × (or *) to repeat it, or ÷ (or /) to split it, then a plain number. \"8h 15m × 3\" repeats the block three times. \"1 day ÷ 4\" splits one day into four equal parts. The number after × or ÷ is always plain, never a duration."
      },
      {
        "title": "Pick a result format",
        "body": "Choose how you want the answer shown from the format picker: Hour Minute, Day Hour Minute, Minute, Second, and more. The same total can read as hours and minutes, as total minutes, or as plain seconds, depending on what you need to record."
      },
      {
        "title": "Read and reuse the result",
        "body": "The calculator carries minutes into hours and hours into days automatically, so the answer is always normalized. Chain more steps if needed, like multiplying a block and then subtracting a break, all on one line."
      }
    ],
    "examples": [
      {
        "expr": "8h 15m × 3",
        "format": "Hour Minute",
        "result": "24 Hours 45 Minutes",
        "note": "Repeats an 8h 15m shift three times; minutes carry into the hour total."
      },
      {
        "expr": "1 day ÷ 4",
        "format": "Hour Minute",
        "result": "6 Hours",
        "note": "Splits one full day evenly four ways."
      },
      {
        "expr": "45m × 6",
        "format": "Hour Minute",
        "result": "4 Hours 30 Minutes",
        "note": "Bills a 45-minute task across six clients."
      },
      {
        "expr": "2h 30m × 4",
        "format": "Hour",
        "result": "10 Hours",
        "note": "Four repeats of a 2h 30m block, shown as whole hours."
      }
    ],
    "faqs": [
      {
        "q": "Can I multiply two durations together, like 2 hours × 3 hours?",
        "a": "No. Multiplying two durations would give an area-like unit that is not time, so it is not allowed. The × and ÷ operators only work with a plain number, such as \"2h 30m × 3\" or \"1 day ÷ 4\". The number is the count of repeats or splits."
      },
      {
        "q": "What happens when a division does not come out evenly?",
        "a": "The calculator keeps the exact value and shows it in the format you pick. If you split a duration that does not divide cleanly into whole hours, choose a finer format like Minute or Second to see the precise remainder instead of a rounded figure."
      },
      {
        "q": "Do I need a unit on the multiplier?",
        "a": "No. The number after × or ÷ is a plain count, so \"45m × 6\" is correct, not \"45m × 6m\". Every other number in the expression does need a unit, like the 45m here."
      }
    ],
    "related": [
      "add-and-subtract-time",
      "timesheet-total-hours",
      "convert-time-units"
    ]
  },
  {
    "slug": "convert-time-units",
    "query": "convert minutes to seconds, hours to minutes, etc.",
    "h1": "How do I convert between time units like minutes to seconds or hours to minutes?",
    "metaTitle": "Convert Time Units: Minutes, Seconds, Hours, Days",
    "metaDescription": "Convert minutes to seconds, hours to minutes, seconds to hours, and milliseconds with a free time calculator. Type the duration, pick an output format, done.",
    "answer": "To convert a time unit, type the duration with its unit (like \"90 min\" or \"2h 15m\") and pick the output format you want, such as Second or Minute. The calculator restates the same length of time in the new units. It handles years down to milliseconds, all in one expression.",
    "intro": "Converting time units is just restating one length of time in a different unit. Ninety minutes and 5,400 seconds are the same duration written two ways. This calculator does that translation for you: type the value and unit, choose how you want the answer displayed, and read the result. It supports years, months, weeks, days, hours, minutes, seconds, and milliseconds, which makes it useful for audio and video editing, software timing, and any work that crosses unit boundaries.",
    "useCaseLine": "An audio editor checking that a 90-minute mix equals 5,400 seconds, or a developer reading a 250 ms delay in real time, gets the answer without doing the math by hand.",
    "steps": [
      {
        "title": "Type the duration with its unit",
        "body": "Enter the value followed by its unit, like \"90 min\", \"3h\", or \"250 ms\". Every number needs a unit. You can also combine units in one line, such as \"2h 30m\", and the calculator treats the whole thing as a single duration."
      },
      {
        "title": "Pick the output format",
        "body": "Open the result format picker and choose the unit you want the answer in. Pick \"Second\" to convert to seconds, \"Minute\" to convert to minutes, or \"Hour\" for hours. Multi-unit formats like \"Day Hour Minute\" break a long duration into parts."
      },
      {
        "title": "Read the converted result",
        "body": "The result restates your duration in the chosen units. The underlying length never changes, only how it is displayed. Switch the format again at any time to see the same duration in another unit without retyping it."
      },
      {
        "title": "Scale before converting if needed",
        "body": "Multiply or divide by a plain number first when you need a repeated or split duration, like \"250 ms × 8\" or \"1 day ÷ 4\". Then read the result in whatever unit fits, such as Second or Hour."
      }
    ],
    "examples": [
      {
        "expr": "90 min",
        "format": "Second",
        "result": "5400 Seconds",
        "note": "Minutes to seconds: a 90-minute audio mix as a raw second count."
      },
      {
        "expr": "2h 15m",
        "format": "Minute",
        "result": "135 Minutes",
        "note": "Hours and minutes flattened to a single minute total."
      },
      {
        "expr": "3600 sec",
        "format": "Hour Minute",
        "result": "1 Hour",
        "note": "Seconds back up to hours, confirming 3,600 seconds is one hour."
      },
      {
        "expr": "250 ms × 8",
        "format": "Second",
        "result": "2 Seconds",
        "note": "Eight 250 ms frames scaled up, then read in seconds."
      }
    ],
    "faqs": [
      {
        "q": "Can I convert milliseconds?",
        "a": "Yes. Type a value in milliseconds using \"ms\", like \"1500 ms\", and pick a format such as Second or Minute Second. Milliseconds make this useful for editing and software timing where sub-second precision matters."
      },
      {
        "q": "Do I have to type a unit on every number?",
        "a": "Yes. Each number needs a unit, so write \"90 min\" rather than \"90\". The only exception is the multiplier in × or ÷, where a plain number is expected, like \"3h × 2\"."
      },
      {
        "q": "Can I convert in both directions?",
        "a": "Yes. The format picker works either way. Enter seconds and read hours, or enter hours and read seconds. The duration stays the same length; only the displayed unit changes."
      }
    ],
    "related": [
      "multiply-and-divide-time",
      "add-and-subtract-time",
      "add-hours-and-minutes"
    ]
  },
  {
    "slug": "convert-time-to-decimal",
    "query": "convert time to decimal hours",
    "h1": "Convert Time to Decimal Hours",
    "metaTitle": "Convert Time to Decimal Hours for Payroll",
    "metaDescription": "Convert hours and minutes to decimal hours for payroll. See why 8h 15m = 8.25, the 15/30/45 rule, and how to handle repeating decimals like 8.3333333.",
    "answer": "To convert time to decimal hours, divide the minutes by 60 and add the whole hours. So 8h 15m becomes 8 + 15/60 = 8.25 hours. In the calculator, type the duration and pick the single \"Hour\" format to get the decimal directly: 15m is .25, 30m is .5, 45m is .75.",
    "intro": "Most payroll and timesheet systems want hours as a decimal, not as hours and minutes. They expect 8.25, not 8h 15m. The conversion is just minutes divided by 60, added to the whole hours. The calculator does it for you: enter the duration and choose the single \"Hour\" result format to read the decimal straight off. The clean quarters are easy to memorize (15m = .25, 30m = .5, 45m = .75), but odd minute counts produce repeating decimals like 8.3333333, which payroll usually rounds to two places.",
    "useCaseLine": "For a payroll clerk who has to enter each employee's daily hours as a decimal into the wage system.",
    "steps": [
      {
        "title": "Enter the duration with units",
        "body": "Type the worked time as a number-plus-unit duration, for example 8h 15m. Each value needs a unit; the engine reads hours and minutes, not clock times. If you started from a clock span, calculate that first (for example 17h 45m - 9h 15m) and convert the result."
      },
      {
        "title": "Choose the single \"Hour\" format",
        "body": "Set the result format to \"Hour\". This single-unit format returns decimal hours instead of splitting the answer into hours and minutes. So 8h 15m reads as 8.25 Hours and 90 min reads as 1.5 Hours."
      },
      {
        "title": "Read the quarter-hour shortcuts",
        "body": "Quarter hours convert to clean decimals: 15m = .25, 30m = .5, 45m = .75. Any whole-hour amount plus one of these stays exact, so 8h 30m is 8.5 and 8h 45m is 8.75. These are worth memorizing for quick timesheet checks."
      },
      {
        "title": "Round repeating decimals for payroll",
        "body": "Odd minute counts do not divide evenly by 60, so they produce repeating decimals. The engine shows 7 digits, so 8h 20m becomes 8.3333333 Hours. Payroll systems usually round to 2 decimal places, making that 8.33. Round only the final total, not each daily figure, to avoid drift."
      }
    ],
    "examples": [
      {
        "expr": "8h 15m",
        "format": "Hour",
        "result": "8.25 Hours",
        "note": "A standard shift with a quarter hour, the classic payroll example."
      },
      {
        "expr": "8h 45m",
        "format": "Hour",
        "result": "8.75 Hours",
        "note": "Three quarters of an hour converts to a clean .75 decimal."
      },
      {
        "expr": "8h 20m",
        "format": "Hour",
        "result": "8.3333333 Hours",
        "note": "An odd minute count gives a repeating decimal that payroll rounds to 8.33."
      },
      {
        "expr": "8h 15m",
        "format": "Minute",
        "result": "495 Minutes",
        "note": "Same shift shown as total minutes if your system wants minutes instead."
      }
    ],
    "faqs": [
      {
        "q": "How do I convert hours and minutes to decimal hours?",
        "a": "Divide the minutes by 60 and add the whole hours. For 8h 15m, that is 8 + 15/60 = 8.25. In the calculator, type the duration and select the single \"Hour\" format to get the decimal automatically."
      },
      {
        "q": "Why is 8h 15m equal to 8.25 and not 8.15?",
        "a": "Decimal hours are fractions of an hour, not the minute count written after a dot. 15 minutes is a quarter of an hour, which is 0.25, so 8h 15m is 8.25 hours. The 15 is not the decimal; 15/60 is."
      },
      {
        "q": "What are 15, 30, and 45 minutes in decimal?",
        "a": "15 minutes is .25, 30 minutes is .5, and 45 minutes is .75. These are the quarter-hour values, the most common conversions on a timesheet. So 6h 30m is 6.5 and 2h 45m is 2.75."
      },
      {
        "q": "Why does 8h 20m show 8.3333333?",
        "a": "20 minutes is 20/60 of an hour, which is 0.3333... repeating. The calculator displays 7 digits, so you see 8.3333333. Payroll systems round this to two places, giving 8.33."
      },
      {
        "q": "Can I convert a duration to total minutes instead?",
        "a": "Yes. Use the single \"Minute\" format and the result comes back as total minutes. For example, 8h 15m returns 495 Minutes, useful when a system tracks minutes rather than decimal hours."
      }
    ],
    "related": [
      "timesheet-total-hours",
      "add-hours-and-minutes",
      "billable-hours"
    ]
  },
  {
    "slug": "time-between-two-times",
    "query": "time between two times",
    "h1": "How to Calculate the Time Between Two Times",
    "metaTitle": "Time Between Two Times: How to Calculate Elapsed Time",
    "metaDescription": "Find the time between two times by writing each clock time as a duration from midnight, then subtracting. Examples for parking, ovens, study blocks, and flights.",
    "answer": "Write each clock time as a duration from midnight, then subtract the earlier from the later. 5:30 PM minus 9:15 AM becomes \"17h 45m - 9h 15m\", which equals 8h 30m. If the span crosses midnight, add 24h to the end time before subtracting.",
    "intro": "You want to know how long something lasted: a parking session, an oven timer, a study block, or a long flight. The trick is to stop thinking in clock labels and start thinking in durations. Convert each clock time into hours and minutes counted from midnight, then subtract the start from the end. This calculator does duration math only. It has no concept of \"now\", today's date, or the calendar, so it answers \"how long between these two times\" but not \"what time is it after this delay\".",
    "useCaseLine": "Measure how long a parking session, oven timer, study block, flight, or overnight span lasted by subtracting two clock times.",
    "steps": [
      {
        "title": "Turn each clock time into a duration from midnight",
        "body": "Read each time off the clock and rewrite it as hours and minutes since 12:00 midnight. 9:15 AM becomes 9h 15m. 5:45 PM becomes 17h 45m, because afternoon hours keep counting up: 1 PM is 13, 2 PM is 14, and so on. Midnight itself is 0h. This is the step that lets a plain subtraction work."
      },
      {
        "title": "Subtract the earlier time from the later time",
        "body": "Put the later duration first and subtract the earlier one: \"17h 45m - 9h 15m\". The calculator handles the minute borrowing for you, so you never have to convert to a decimal or borrow 60 minutes by hand. The result is the elapsed time, for example 8h 30m."
      },
      {
        "title": "If the span crosses midnight, add 24h to the end",
        "body": "When the end time is on the next day, such as parking from 10:30 PM to 6:15 AM, add 24h to the end before subtracting: \"6h 15m + 24h - 22h 30m\". The 24h represents one full day, so the math lands on the real overnight length instead of a negative number."
      },
      {
        "title": "Pick the result format you want to read",
        "body": "Choose Hour Minute for a clean \"8 hours 30 minutes\" readout, or switch to the single Hour format to get decimal hours like 8.5 for spreadsheets and billing. The Minute format gives the whole span as total minutes, handy for timers and cooking."
      }
    ],
    "examples": [
      {
        "expr": "14h 20m - 9h 45m",
        "format": "Hour Minute",
        "result": "4 Hours 35 Minutes",
        "note": "Parking session from 9:45 AM to 2:20 PM."
      },
      {
        "expr": "19h 50m - 19h 05m",
        "format": "Minute",
        "result": "45 Minutes",
        "note": "Oven timer set at 7:05 PM and pulled at 7:50 PM."
      },
      {
        "expr": "16h 30m - 13h 15m",
        "format": "Hour",
        "result": "3.25 Hours",
        "note": "An afternoon study block from 1:15 PM to 4:30 PM, in decimal hours."
      },
      {
        "expr": "6h 15m + 24h - 22h 30m",
        "format": "Hour Minute",
        "result": "7 Hours 45 Minutes",
        "note": "An overnight stretch from 10:30 PM to 6:15 AM the next morning."
      }
    ],
    "faqs": [
      {
        "q": "How do I calculate the time between two times?",
        "a": "Write each clock time as a duration from midnight, then subtract the earlier from the later. For 9:15 AM to 5:45 PM, enter \"17h 45m - 9h 15m\" to get 8h 30m. The calculator does the minute borrowing, so you do not convert anything by hand."
      },
      {
        "q": "What if the second time is on the next day?",
        "a": "Add 24h to the end time before subtracting. A span from 10:30 PM to 6:15 AM becomes \"6h 15m + 24h - 22h 30m\", which equals 7h 45m. The 24h stands in for the full day that passed overnight."
      },
      {
        "q": "Can it tell me what time it will be in 3 hours?",
        "a": "No. This is a duration calculator. It measures how long a span lasts when you give it both ends, but it has no idea what time it is now and cannot add a delay to the current clock or to a calendar date."
      },
      {
        "q": "How do I get the answer in decimal hours?",
        "a": "Use the single Hour format. A 3 hour 15 minute span shows as 3.25 Hours, and 45 minutes shows as 0.75 Hours. This is the format to use for timesheets, billing, or any spreadsheet that expects a decimal."
      }
    ],
    "related": [
      "hours-worked-between-two-times",
      "add-and-subtract-time",
      "convert-time-units"
    ]
  },
  {
    "slug": "add-video-audio-lengths",
    "query": "add up video and audio lengths",
    "h1": "Add Up Video and Audio Lengths (mm:ss and Milliseconds)",
    "metaTitle": "Add Up Video & Audio Lengths: mm:ss Calculator",
    "metaDescription": "Total clip and track lengths in minutes and seconds, roll past an hour, and work in milliseconds. A free mm:ss calculator built for video editors and audio work.",
    "answer": "To total video or audio lengths, enter each clip as minutes and seconds and add them: \"2m 45s + 3m 12s + 1m 58s\" returns 7 Minutes 55 Seconds in the Minute Second format. The seconds roll into minutes automatically, and minutes roll into hours when you pick the Hour Minute Second format.",
    "intro": "Editors, podcasters, and musicians stack clip and track lengths constantly, and the math is annoying because 45s plus 30s is not 75, it is 1:15. This calculator carries seconds into minutes and minutes into hours for you. Enter each length as a number plus a unit, add them, and read the total in whichever mm:ss or h:mm:ss format you need. It also works in milliseconds, which most time calculators drop. The web version is free and ad-supported, running the same engine as the mobile apps.",
    "useCaseLine": "For video editors, podcasters, and musicians totalling clip runtimes and track lengths down to the millisecond.",
    "steps": [
      {
        "title": "Type each clip as minutes and seconds",
        "body": "Write a length as a number and a unit with no colon: a 2:45 clip is \"2m 45s\", a 12-second sting is \"12s\". Use \"m\" for minutes and \"s\" for seconds. A bare number is only allowed as a multiplier, so always attach a unit to each length."
      },
      {
        "title": "Add them with the plus sign",
        "body": "Chain the clips with +, for example \"2m 45s + 3m 12s + 1m 58s\". The engine sums everything in the background and carries 60 seconds up into a minute, so you never have to fix overflowing seconds by hand."
      },
      {
        "title": "Pick Minute Second for short reels",
        "body": "Set the result format to Minute Second to read totals as whole minutes and seconds, like 7 Minutes 55 Seconds. This is the format you want for a single reel, a song, or a short clip stack that stays under an hour."
      },
      {
        "title": "Switch to Hour Minute Second once you cross an hour",
        "body": "For a full playlist or episode, choose Hour Minute Second. A four-clip set like \"18m 30s + 22m 15s + 12m 45s + 14m 50s\" reads 1 Hour 8 Minutes 20 Seconds, with the minutes rolling cleanly into one hour."
      },
      {
        "title": "Work in milliseconds for audio and frames",
        "body": "Add the ms unit for sub-second precision most calculators skip. Use \"1s - 250ms\" to find a 750 ms gap, or multiply a frame duration: \"41ms * 30\" with the Hour Minute Second MSecond format gives 0 Hours 0 Minutes 1 Second 230 MSeconds. Pick a format ending in MSecond to keep the millisecond digits."
      }
    ],
    "examples": [
      {
        "expr": "2m 45s + 3m 12s + 1m 58s",
        "format": "Minute Second",
        "result": "7 Minutes 55 Seconds",
        "note": "Total three short clips for a reel; seconds carry into minutes automatically."
      },
      {
        "expr": "18m 30s + 22m 15s + 12m 45s + 14m 50s",
        "format": "Hour Minute Second",
        "result": "1 Hour 8 Minutes 20 Seconds",
        "note": "Sum a playlist of segments that crosses the one-hour mark."
      },
      {
        "expr": "1s - 250ms",
        "format": "MSecond",
        "result": "750 MSeconds",
        "note": "Find the millisecond gap left after trimming a quarter-second from a one-second cue."
      },
      {
        "expr": "41ms * 30",
        "format": "Hour Minute Second MSecond",
        "result": "1 Second 230 MSeconds",
        "note": "Multiply one frame at 41 ms by 30 frames to get the clip length to the millisecond."
      }
    ],
    "faqs": [
      {
        "q": "How do I total clip lengths in mm:ss?",
        "a": "Type each clip as minutes and seconds with a unit, like \"3m 20s\", join them with +, and set the result format to Minute Second. The calculator carries every 60 seconds into a minute, so \"3m 20s + 2m 50s\" returns 6 Minutes 10 Seconds rather than 5:70."
      },
      {
        "q": "What if my total goes over an hour?",
        "a": "Switch the result format to Hour Minute Second. The same sum then rolls 60 minutes into an hour, so a long playlist shows as something like 1 Hour 8 Minutes 20 Seconds instead of 68 minutes."
      },
      {
        "q": "Can it handle milliseconds?",
        "a": "Yes. Use the ms unit, which many time calculators lack. You can compute \"1s - 250ms\" to get 750 MSeconds, or multiply a frame or sample duration. Pick any result format ending in MSecond to keep the millisecond digits visible."
      },
      {
        "q": "Why do I have to add a unit to every number?",
        "a": "Each value needs a unit so the engine knows whether 3 means minutes, seconds, or milliseconds. A bare number is only valid as a multiplier or divisor, as in \"41ms * 30\" or \"6m / 2\". \"2 + 2\" alone is not a valid time expression."
      },
      {
        "q": "Does this know the actual clock time or release date?",
        "a": "No. It works with durations only. It adds, subtracts, multiplies, and divides lengths of time. It does not track wall-clock time, calendar dates, or the current moment, so it cannot tell you when a render will finish in real time."
      }
    ],
    "related": [
      "convert-time-units",
      "multiply-and-divide-time",
      "add-and-subtract-time"
    ]
  },
  {
    "slug": "billable-hours",
    "query": "calculate billable hours",
    "h1": "Billable Hours Calculator",
    "metaTitle": "Billable Hours Calculator: Total Time to Decimal",
    "metaDescription": "Add up billable time across client sessions and convert the total to decimal hours for invoicing. Sum durations, multiply repeated tasks, and get a clean decimal.",
    "answer": "To calculate billable hours, add each session duration with the + operator (for example 1h 15m + 45m + 2h 30m = 4h 30m), then switch the result format to the single \"Hour\" option to get the decimal total, 4.5 hours. Invoices and billing software expect decimals, so this converts your tracked time directly.",
    "intro": "Freelancers, lawyers, and agencies bill in decimal hours, not hours and minutes. Most invoicing tools want 4.5, not 4h 30m. This calculator adds every tracked session, multiplies repeated tasks, and converts the total to a clean decimal you can drop straight into an invoice. Everything stays as duration math, so the engine handles the rounding for you.",
    "useCaseLine": "Total client sessions and convert to decimal hours for invoicing.",
    "steps": [
      {
        "title": "Enter each session as a duration",
        "body": "Type every work block with a unit attached: 1h 15m for a meeting, 45m for a call, 2h 30m for deep work. Hours use h, minutes use m. Each value needs a unit, so write 45m, not a bare 45."
      },
      {
        "title": "Add the sessions with +",
        "body": "Join the durations with the plus operator: 1h 15m + 45m + 2h 30m. The calculator returns 4h 30m. Keep stacking sessions across the day or the week the same way to build one running total."
      },
      {
        "title": "Multiply any repeated task",
        "body": "For a task that ran several times at the same length, multiply instead of retyping it. Six 25-minute calls become 25m * 6, which equals 2h 30m. The count is a bare number because it acts as a multiplier."
      },
      {
        "title": "Switch the result to decimal hours",
        "body": "Set the result format to the single \"Hour\" option. Your 4h 30m total becomes 4.5 hours, and 8h 15m becomes 8.25 hours. This is the figure invoices and billing software expect, so copy it straight onto the line item."
      },
      {
        "title": "Apply your rate",
        "body": "Use the rate panel to multiply the decimal total by your hourly rate and read the money amount, or paste the decimal hours into your own invoicing tool. The time result itself never includes currency, so the rate panel is where the dollar figure appears."
      }
    ],
    "examples": [
      {
        "expr": "1h 15m + 45m + 2h 30m",
        "format": "Hour Minute",
        "result": "4 Hours 30 Minutes",
        "note": "Add three client sessions logged in one day to see the running total."
      },
      {
        "expr": "1h 15m + 45m + 2h 30m",
        "format": "Hour",
        "result": "4.5 Hours",
        "note": "Same total shown as decimal hours, ready to type onto an invoice."
      },
      {
        "expr": "25m * 6",
        "format": "Hour Minute",
        "result": "2 Hours 30 Minutes",
        "note": "Bill a repeated 25-minute support call that happened six times."
      },
      {
        "expr": "25m * 6",
        "format": "Hour",
        "result": "2.5 Hours",
        "note": "The same repeated block as a decimal for the line item."
      }
    ],
    "faqs": [
      {
        "q": "How do I total my billable hours?",
        "a": "Enter each session as a duration and join them with the + operator, like 1h 15m + 45m + 2h 30m. The calculator returns the combined total, 4h 30m. Keep every value tagged with a unit (h for hours, m for minutes) so the engine reads it correctly."
      },
      {
        "q": "How do I convert billable time to decimal hours?",
        "a": "Calculate your total, then set the result format to the single \"Hour\" option. A total of 4h 30m becomes 4.5 hours, and 8h 15m becomes 8.25 hours. Totals that do not divide evenly show seven digits, so 1h 20m reads 1.3333333 hours."
      },
      {
        "q": "How do I bill the same task repeated several times?",
        "a": "Multiply one session by the count. For six 25-minute calls, type 25m * 6 to get 2h 30m, or 2.5 hours in decimal format. A bare number is allowed only as a multiplier or divisor, so the unit stays on the duration."
      },
      {
        "q": "Can the calculator turn my hours into a money amount?",
        "a": "Yes. The calculator has a rate panel that multiplies a duration by your hourly rate to show a dollar figure. The plain result string only reports time, so use the decimal hours total there or paste it into your invoicing software."
      }
    ],
    "related": [
      "convert-time-to-decimal",
      "timesheet-total-hours",
      "multiply-and-divide-time"
    ]
  }
]

export function getGuide(slug: string): Guide | undefined {
  return GUIDES.find((g) => g.slug === slug)
}

export function relatedGuides(slug: string): Guide[] {
  const g = getGuide(slug)
  if (!g) return []
  return g.related.map(getGuide).filter((x): x is Guide => Boolean(x))
}

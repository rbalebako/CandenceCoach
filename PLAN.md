# Cadence Coach: what the watch does on each run

This file describes what the app actually does, taken from the code in `source/`. `specs.md` is the training plan the app is based on. The section at the end lists where the two differ.

## Before every run

1. **Goal screen.** It shows the session name and one or two sentences on the goal of the run. Press START.
2. **Ready screen.** It shows the first step, your baseline (with "(default)" if it is still 160), and the GPS status. Press START to begin. BACK on either screen returns to the session list.

## What it tracks automatically

| What | How |
|---|---|
| **Activity file** | A normal FIT **Run** with GPS, heart rate, distance and pace, recorded by the watch as usual and synced to Garmin Connect. |
| **Laps** | A lap is added at every step change, so each interval is its own lap in Connect. In the W4 Run 1 cool-down (the last step), pressing LAP adds a lap. |
| **Live cadence** | Read once a second from the watch (wrist sensor, or an HRM-Pro or footpod if paired). |
| **Baseline** (W1 Run 1 only) | Average cadence over the 60 s "Baseline" step. It's stored when you **Save** the run (not if you Discard) and used for every "baseline + N" target. A non-zero baseline in Settings overrides it. |
| **Avg cadence** | The average of all cadence samples while the workout is running. Warm-ups, recoveries and walk-downs are included. Paused time and the post-run drills are not. If the sensor drops out, it shows "--" and those seconds aren't counted. |
| **On target %** | Only counts steps that have a target, ignoring the first 5 s of each one. A sample counts as on target if it's within ±3 spm. |
| **Time** | Active time only (pauses excluded), plus a countdown or count-up for the current step. |
| **Last result** | Each session's average cadence is saved and shown next to it in the session menu, which updates as soon as you save. |

**Summary screen:** time, average cadence, on-target %, and either "New baseline" (W1 Run 1) or "vs baseline ±N".

## Cues it gives you

| Cue | When |
|---|---|
| Start tone | When you start or resume |
| Stop tone | When you pause |
| **3-2-1 beeps and buzzes** | In the last 3 s of a timed step, if the next step is a cadence interval, stride or the baseline measurement |
| High alert tone + long buzz | When a cadence interval, stride or measurement starts. The step name turns **orange**. |
| Lap tone + short buzz | When any other step starts (easy, recovery, "press LAP" steps) |
| **Metronome** | Only during cadence intervals, at the target spm. Beep, vibrate or both, on every step or on the right foot only (see Settings). |
| **Cadence color** | Green: within ±3 of target. Orange: below target. Red: more than 8 below. Blue: above target. White: no target. |
| Cue text | A short phrase under the cadence, such as "Land under hips" or "Elbows back, tall" |
| "press LAP" | Shown in green when the step waits for you (landmark, hill base, drills) |
| **"Run done!" reminder** | When the main run ends in weeks 1–3, the screen names the drill that comes next. The high alert tone and a buzz repeat every 30 s until you press LAP (or Save to skip). |
| **Drill instructions** | Each drill step replaces the cadence readout with how to do the drill, taken from the spec. Example: "15 m: skip rhythmically, knees to hip height, land softly on your midfoot." |
| Success tone + 1 s buzz | Workout finished |

There are no 3-2-1 beeps before a step you start yourself with LAP (landmark pickups, hill strides, drills). They start right away with the high alert tone.

## Session by session

| Session | Steps on the watch | Target / metronome |
|---|---|---|
| **W1 Run 1** | 12 min easy → 3-2-1 → **60 s Baseline** → 12 min easy → A-skips 2 × LAP | None. Measures the baseline. |
| **W1 Run 2** | 10 min warm-up → 4 × (30 s pickup, 90 s jog) → A-skips 2 × LAP | 170, metronome |
| **W2 Run 1** | 7 min easy → 4 × 1 min, with 2 min jogs between → easy until 25:00 → high knees 2 × 20 s | baseline + 6, metronome |
| **W2 Run 2** | 6 × (easy until LAP at a landmark → 30 s pickup) → easy until 30:00 → high knees 2 × 20 s | baseline + 6, metronome |
| **W3 Run 1** | 10 min warm-up → 3 × (2 min block, 2 min walk/jog) → cool-down until LAP → butt kicks 2 × LAP | baseline + 8, metronome |
| **W3 Run 2** | 10 min warm-up → 4 × (LAP at hill base → 15 s stride) → LAP → cool-down until LAP → butt kicks 2 × LAP | None (the hill sets the cadence) |
| **W4 Run 1** | 10 min warm-up → 5 min → 3 min walk/jog → 5 min → cool-down until START → Save | 172, metronome |
| **W4 Run 2** | 30 min "light and quick" | None. The summary compares you with your baseline. |

Drills are optional. To skip them, press START → Save at "Run done!". In week 3, the cool-down cue reads "LAP: drills next".

**Saving:** if you choose Save from the pause menu, the watch ends the workout and shows the summary screen first. START then saves and exits. BACK opens Save / Discard instead. If you finish every step, the summary appears on its own, and START opens Save / Discard.

## Differences from specs.md

### Choices the app makes where the spec gives a range or leaves something out

| Spec | App |
|---|---|
| W1 Run 1: easy run of 20–30 min | Fixed 25 min (12 + 1 + 12) |
| W1 Run 1: count right-foot steps for 60 s and multiply by 2 | Measured automatically, nothing to count |
| W2: metronome 5–8 above baseline | Fixed at +6 |
| W2 Run 2: "your target cadence" (not defined) | baseline + 6, with a metronome (the spec doesn't mention one) |
| W3 Run 1: 5–10 above starting cadence | Fixed at +8 |
| W3 Run 2: no warm-up listed | 10 min warm-up added |
| W4 Run 1: 170–175 | Fixed at 172 |
| W4 Run 2: check your watch now and then to see if your cadence is higher | No mid-run prompts. The comparison is on the summary screen at the end. |
| Relative targets before any baseline exists | Uses a default baseline of 160 |

### Additions not in the spec

- The drill runs after **both** runs of weeks 1–3. The spec lists one drill per week, placed after Run 2.
- Cool-downs with no fixed length at the end of W3 Run 1, W3 Run 2 and W4 Run 1.
- On-target % scoring, the average-cadence history in the menu, colored cadence, and the goal screen.

### Things in the spec the app doesn't do

- **Pacing the 4 weeks.** Any session can be started at any time. The app doesn't track which week you're in or warn about ramping up too fast, which is the calf and shin risk the spec mentions.
- **Form cues during W4 Run 1.** "Relax shoulders" and "Breathe rhythmically" are text only, as in every session. There are no extra prompts.

### Notes on the numbers

- **Avg cadence** includes warm-up, walking and recovery (not drills), so for interval sessions it reads lower than your cadence in the intervals. It's most meaningful for W4 Run 2.
- W1 Run 2 and W4 Run 1 use absolute targets (170 and 172), as the spec does, even if your baseline is far lower. The spec's own Week 2 advice ("don't jump straight to 180 if you're at 150") suggests being careful with these.

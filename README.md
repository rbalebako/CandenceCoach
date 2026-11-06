# Cadence Coach: Connect IQ app for Fenix 7S

A watch app that runs your 4-week cadence and form plan. It has every session built in, a beep/vibration metronome, live cadence colored against your target, automatic baseline measurement, and post-run drill prompts. Each workout saves as a normal **Run** activity in Garmin Connect, with GPS and laps.

## Buttons during a workout

| Button | Action |
|---|---|
| **START** | Start the workout / pause it (opens Resume · Save · Discard) |
| **BACK** | **LAP**: ends a "press LAP" step (landmark, hill, drill, Week 3 cool-down), or skips the current step |

When you open a session, a short **goal screen** comes first (that week's goal and what this run is for, from `specs.md`). Press START to go to the ready screen, then START again to begin.

The touchscreen is ignored during a workout so a sweaty tap or swipe can't pause or skip anything.

## Cadence colors

Green means within ±3 spm of the target. Orange means below it, red means more than 8 below, and blue means above it.

## The sessions

| Menu | What the watch does |
|---|---|
| W1 Run 1 | 12 min easy → **60 s baseline measurement** (3-2-1 beeps first) → 12 min easy. The measured average becomes your baseline. |
| W1 Run 2 | 10 min warm-up → 4 × (30 s @ 170 with metronome, 90 s recovery) |
| W2 Run 1 | 7 min easy → 4 × 1 min @ baseline+6 with 2 min jogs → easy until 25:00 |
| W2 Run 2 | 6 × (easy until you press LAP at a landmark → 30 s @ baseline+6) → easy until 30:00 |
| W3 Run 1 | 10 min warm-up → 3 × (2 min @ baseline+8, 2 min walk/jog) → cool-down (LAP when done) → butt kicks |
| W3 Run 2 | 10 min warm-up* → 4 × (LAP at the hill base → 15 s stride) → cool-down (LAP when done) → butt kicks |
| W4 Run 1 | 10 min warm-up → 5 min @ 172 → 3 min easy → 5 min @ 172 → cool-down |
| W4 Run 2 | 30 min "light and quick". The summary shows your average versus your baseline. |

\*Your plan doesn't list a warm-up for the hill strides, so I added a short one. Weeks 1–3 end with that week's drill (A-skips, high knees or butt kicks). It's optional: press START → Save to skip it.

**Stopping early:** START → Save shows the summary screen first (time, average cadence, on-target %, baseline). Press START again to save and exit.

Relative targets (baseline+6, +8) use the baseline measured in W1 Run 1 (stored when you save that run). Until you've done that run, they use 160 (shown as "default"). You can also enter a baseline yourself in the app settings.

## Settings (Connect IQ app on your phone → Cadence Coach → Settings)

- **Baseline cadence**: 0 = use the measured value.
- **Metronome**: Beep / Vibrate / Beep + vibrate / Off.
- **Beat on**: Every step, or right foot only (half rate, quieter).

The watch only beeps if **System → Sounds & Alerts → Tones** is on.

## Build and install (first time)

1. Install **VS Code** and the **Monkey C** extension (by Garmin).
2. Install the **Connect IQ SDK Manager** from developer.garmin.com/connect-iq/sdk. Sign in, download the latest SDK, and under *Devices* download **fēnix 7S**.
3. In VS Code, run `Ctrl/Cmd+Shift+P` → **Monkey C: Verify Installation**. When it asks, let it **generate a developer key**.
4. Open this `CadenceCoach` folder. Then press `Ctrl/Cmd+Shift+P` → **Monkey C: Run** → choose *fenix7s* to try it in the simulator. Under *Simulation → Activity Data* you can feed it fake cadence.
5. To put it on the watch: press `Ctrl/Cmd+Shift+P` → **Monkey C: Build for Device** → *fenix7s*. This produces `CadenceCoach.prg`. Plug the watch into your computer by USB and copy the file to **GARMIN/APPS/** on the watch. Unplug the watch. The app appears in the activity list (START → scroll → Cadence Coach).

On a Mac, use **OpenMTP** to see the watch's files.

## Notes

- The metronome uses the watch's software timer, so there may be slight jitter at 170+ bpm. If it bothers you, switch to *Right foot only* or *Vibrate*.
- The cadence comes from the watch's wrist sensor. If you have an HRM-Pro or a footpod, the watch uses that instead.

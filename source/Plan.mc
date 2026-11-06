import Toybox.Lang;
import Toybox.Application;

// The 4-week cadence & form plan, expressed as lists of segments.
//
// Each segment is a Dictionary:
//   :name  short title shown at the top of the screen
//   :cue   short coaching cue (keep it under ~20 characters for the 7S screen)
//   :kind  KIND_TIMED      ends after :dur seconds
//          KIND_MANUAL     ends when you press LAP (BACK button)
//          KIND_UNTIL_TOTAL ends when total workout time reaches :dur seconds
//          KIND_OPEN       no time limit (cool-down): LAP moves on if a segment
//                          follows, otherwise it runs until you stop the workout
//   :tgt   TGT_NONE / TGT_ABS (:cad is the cadence) / TGT_REL (:cad is added to baseline)
//   :met   true = metronome plays during this segment
//   :cd    true = 3-2-1 countdown beeps before this segment starts
//   :measure true = average cadence in this segment becomes your new baseline
//   :rep   e.g. "2/4"
module Plan {

    const KIND_TIMED = 0;
    const KIND_MANUAL = 1;
    const KIND_UNTIL_TOTAL = 2;
    const KIND_OPEN = 3;

    const TGT_NONE = 0;
    const TGT_ABS = 1;
    const TGT_REL = 2;

    const ST_READY = 0;
    const ST_RUNNING = 1;
    const ST_PAUSED = 2;
    const ST_DONE = 3;

    // Cadence used for relative targets until a baseline has been measured.
    const DEFAULT_BASELINE = 160;

    // ---- segment helpers -------------------------------------------------

    function easy(name, cue, dur) {
        return { :name => name, :cue => cue, :kind => KIND_TIMED, :dur => dur, :tgt => TGT_NONE };
    }

    function work(name, cue, dur, tgt, cad, met) {
        return { :name => name, :cue => cue, :kind => KIND_TIMED, :dur => dur,
                 :tgt => tgt, :cad => cad, :met => met, :cd => true };
    }

    function manual(name, cue) {
        return { :name => name, :cue => cue, :kind => KIND_MANUAL, :tgt => TGT_NONE };
    }

    function untilTotal(name, cue, total) {
        return { :name => name, :cue => cue, :kind => KIND_UNTIL_TOTAL, :dur => total, :tgt => TGT_NONE };
    }

    function open(name, cue) {
        return { :name => name, :cue => cue, :kind => KIND_OPEN, :tgt => TGT_NONE };
    }

    function withRep(seg, i, n) {
        seg[:rep] = i.format("%d") + "/" + n.format("%d");
        return seg;
    }

    // ---- session catalogue ----------------------------------------------

    // [id, menu label, menu sub-label]
    function catalogue() {
        return [
            [:w1r1, "W1 Run 1", "Baseline easy run"],
            [:w1r2, "W1 Run 2", "4x30s @170"],
            [:w2r1, "W2 Run 1", "4x1min base+6"],
            [:w2r2, "W2 Run 2", "Fartlek 6x30s"],
            [:w3r1, "W3 Run 1", "3x2min base+8"],
            [:w3r2, "W3 Run 2", "Hill strides 4x15s"],
            [:w4r1, "W4 Run 1", "2x5min @172"],
            [:w4r2, "W4 Run 2", "Light & quick 30min"]
        ];
    }

    // Short goal text shown before each run starts (from specs.md).
    // Kept to ~100 characters so it fits the round 7S screen in FONT_XTINY.
    function goal(id) {
        if (id == :w1r1) {
            return "Find your natural rhythm. Run easy; the watch measures your cadence for 60 s mid-run. Notice the feel.";
        } else if (id == :w1r2) {
            return "Short, low-stress pickups: 4 x 30 s at 170 with the beat. Light, quick steps, then jog easy.";
        } else if (id == :w2r1) {
            return "Build cadence memory: 4 x 1 min at baseline +6. Build gradually, don't force 180.";
        } else if (id == :w2r2) {
            return "Cadence play: at each landmark, quicken your turnover for 30 s, then settle back. 6 times.";
        } else if (id == :w3r1) {
            return "Quick turnover with good form: 3 x 2 min at baseline +8. Short stride, land under your hips.";
        } else if (id == :w3r2) {
            return "Hill strides on a gentle incline: 15 s up, elbows back, stand tall. Hills stop overstriding.";
        } else if (id == :w4r1) {
            return "Make it your new normal: 2 x 5 min nonstop at 172. Relax your shoulders, breathe in rhythm.";
        } else if (id == :w4r2) {
            return "Only cue: light and quick. See if your easy cadence now sits higher than on day 1.";
        }
        return "";
    }

    // Menu sub-label: plan summary plus the last saved average cadence.
    function menuSub(id) {
        var c = catalogue();
        for (var i = 0; i < c.size(); i++) {
            if (c[i][0] == id) {
                var sub = c[i][2];
                var last = Application.Storage.getValue("avg_" + c[i][1]);
                if (last != null) {
                    sub = sub + " | " + last.format("%d");
                }
                return sub;
            }
        }
        return "";
    }

    function shortName(id) {
        var c = catalogue();
        for (var i = 0; i < c.size(); i++) {
            if (c[i][0] == id) {
                return c[i][1];
            }
        }
        return "Run";
    }

    // Post-run form drills, per week. Optional: stop the workout to skip them.
    function drills(week) {
        var s = [];
        var i;
        if (week == 1) {
            s.add(manual("Run done!", "LAP: start drills"));
            for (i = 1; i <= 2; i++) {
                s.add(withRep(manual("A-Skips", "15 m, LAP when done"), i, 2));
            }
        } else if (week == 2) {
            s.add(manual("Run done!", "LAP: start drills"));
            for (i = 1; i <= 2; i++) {
                if (i > 1) {
                    s.add(manual("High knees", "LAP for set 2"));
                }
                var hk = work("High knees", "Fast feet!", 20, TGT_NONE, 0, false);
                s.add(withRep(hk, i, 2));
            }
        } else if (week == 3) {
            s.add(manual("Run done!", "LAP: start drills"));
            for (i = 1; i <= 2; i++) {
                s.add(withRep(manual("Butt kicks", "15 m, LAP when done"), i, 2));
            }
        }
        // Drill time is left out of the run's cadence stats.
        for (i = 0; i < s.size(); i++) {
            s[i][:drill] = true;
        }
        return s;
    }

    function build(id) {
        var s = [];
        var i;

        if (id == :w1r1) {
            s.add(easy("Easy run", "Relaxed & chatty", 12 * 60));
            var m = { :name => "Baseline", :cue => "Run naturally", :kind => KIND_TIMED,
                      :dur => 60, :tgt => TGT_NONE, :cd => true, :measure => true };
            s.add(m);
            s.add(easy("Easy run", "Notice the feel", 12 * 60));
            s.addAll(drills(1));

        } else if (id == :w1r2) {
            s.add(easy("Warm-up", "Easy jog", 10 * 60));
            for (i = 1; i <= 4; i++) {
                s.add(withRep(work("Pickup", "Light quick steps", 30, TGT_ABS, 170, true), i, 4));
                s.add(withRep(easy("Recover", "Jog normally", 90), i, 4));
            }
            s.addAll(drills(1));

        } else if (id == :w2r1) {
            s.add(easy("Easy", "Settle in", 7 * 60));
            for (i = 1; i <= 4; i++) {
                s.add(withRep(work("Cadence", "Match the beat", 60, TGT_REL, 6, true), i, 4));
                if (i < 4) {
                    s.add(withRep(easy("Easy jog", "Relax", 120), i, 3));
                }
            }
            s.add(untilTotal("Easy", "Finish at 25:00", 25 * 60));
            s.addAll(drills(2));

        } else if (id == :w2r2) {
            for (i = 1; i <= 6; i++) {
                s.add(withRep(manual("Easy", "LAP at landmark"), i, 6));
                s.add(withRep(work("Pickup", "Quick turnover", 30, TGT_REL, 6, true), i, 6));
            }
            s.add(untilTotal("Easy", "Finish at 30:00", 30 * 60));
            s.addAll(drills(2));

        } else if (id == :w3r1) {
            s.add(easy("Warm-up", "Easy jog", 10 * 60));
            for (i = 1; i <= 3; i++) {
                s.add(withRep(work("Cadence block", "Land under hips", 120, TGT_REL, 8, true), i, 3));
                s.add(withRep(easy("Walk / jog", "Recover", 120), i, 3));
            }
            s.add(open("Cool-down", "LAP when done"));
            s.addAll(drills(3));

        } else if (id == :w3r2) {
            // The plan doesn't specify a warm-up here; 10 min easy is added for safety.
            s.add(easy("Warm-up", "Easy to the hill", 10 * 60));
            for (i = 1; i <= 4; i++) {
                var label = (i == 1) ? "At the hill" : "Walk down";
                s.add(withRep(manual(label, "LAP at hill base"), i, 4));
                s.add(withRep(work("Hill stride", "Elbows back, tall", 15, TGT_NONE, 0, false), i, 4));
            }
            s.add(manual("Walk down", "LAP: cool-down"));
            s.add(open("Cool-down", "LAP when done"));
            s.addAll(drills(3));

        } else if (id == :w4r1) {
            s.add(easy("Warm-up", "Easy jog", 10 * 60));
            s.add(withRep(work("Metronome", "Relax shoulders", 5 * 60, TGT_ABS, 172, true), 1, 2));
            s.add(easy("Walk / jog", "Recover", 3 * 60));
            s.add(withRep(work("Metronome", "Breathe rhythmically", 5 * 60, TGT_ABS, 172, true), 2, 2));
            s.add(open("Cool-down", "START to finish"));

        } else if (id == :w4r2) {
            s.add(easy("Easy run", "Light and quick", 30 * 60));
        }

        return s;
    }
}

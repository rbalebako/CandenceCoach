import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// Run screen, laid out for the round 240x240 Fenix 7S display (scales by fraction).
class WorkoutView extends WatchUi.View {

    hidden var e;

    function initialize(engine) {
        View.initialize();
        e = engine;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (e.state == Plan.ST_READY && e.showGoal) {
            drawGoal(dc);
        } else if (e.state == Plan.ST_READY) {
            drawReady(dc);
        } else if (e.state == Plan.ST_DONE) {
            drawSummary(dc);
        } else {
            drawRun(dc);
        }
    }

    hidden function text(dc, y, font, color, str) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, y, font, str,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    static function fmt(sec) {
        if (sec == null) {
            return "--:--";
        }
        if (sec < 0) {
            sec = 0;
        }
        var h = sec / 3600;
        var m = (sec % 3600) / 60;
        var s = sec % 60;
        if (h > 0) {
            return h.format("%d") + ":" + m.format("%02d") + ":" + s.format("%02d");
        }
        return m.format("%d") + ":" + s.format("%02d");
    }

    hidden function cadenceColor(cad, tgt) {
        if (tgt == null || cad == null || cad <= 0) {
            return Graphics.COLOR_WHITE;
        }
        var d = cad - tgt;
        if (d.abs() <= 3) {
            return Graphics.COLOR_GREEN;
        }
        if (d < -8) {
            return Graphics.COLOR_RED;
        }
        return (d < 0) ? Graphics.COLOR_ORANGE : Graphics.COLOR_BLUE;
    }

    // Goal page: shown when a session is opened, before the ready screen.
    hidden function drawGoal(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        text(dc, h * 0.14, Graphics.FONT_TINY, Graphics.COLOR_ORANGE, e.title + " goal");
        var body = Graphics.fitTextToArea(Plan.goal(e.id), Graphics.FONT_XTINY,
                                          (w * 0.76).toNumber(), (h * 0.56).toNumber(), true);
        if (body != null) {
            text(dc, h * 0.50, Graphics.FONT_XTINY, Graphics.COLOR_WHITE, body);
        }
        text(dc, h * 0.87, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, "START: continue");
    }

    hidden function drawReady(dc) {
        var h = dc.getHeight();
        text(dc, h * 0.18, Graphics.FONT_MEDIUM, Graphics.COLOR_WHITE, e.title);
        var first = e.segments[0];
        var firstStr = first[:name];
        if (first[:kind] == Plan.KIND_TIMED) {
            firstStr += " " + fmt(first[:dur]);
        }
        text(dc, h * 0.34, Graphics.FONT_TINY, Graphics.COLOR_LT_GRAY, firstStr);
        var b = "Baseline " + e.baseline.format("%d") + (e.baselineIsDefault ? " (default)" : "");
        text(dc, h * 0.48, Graphics.FONT_TINY, Graphics.COLOR_LT_GRAY, b);
        if (e.gpsOk) {
            text(dc, h * 0.62, Graphics.FONT_SMALL, Graphics.COLOR_GREEN, "GPS ready");
        } else {
            text(dc, h * 0.62, Graphics.FONT_SMALL, Graphics.COLOR_YELLOW, "GPS searching");
        }
        text(dc, h * 0.80, Graphics.FONT_SMALL, Graphics.COLOR_WHITE, "START to begin");
    }

    // Drill steps: the instruction replaces the cadence readout, which
    // means nothing while skipping or running in place.
    hidden function drawDrill(dc, s) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var name = s[:name];
        if (s[:rep] != null) {
            name += " " + s[:rep];
        }
        var titleColor = (s[:cd] == true) ? Graphics.COLOR_ORANGE : Graphics.COLOR_WHITE;
        text(dc, h * 0.13, Graphics.FONT_SMALL, titleColor, name);

        var body = Graphics.fitTextToArea(s[:how], Graphics.FONT_XTINY,
                                          (w * 0.80).toNumber(), (h * 0.46).toNumber(), true);
        if (body != null) {
            text(dc, h * 0.47, Graphics.FONT_XTINY, Graphics.COLOR_WHITE, body);
        }

        if (s[:kind] == Plan.KIND_MANUAL) {
            text(dc, h * 0.79, Graphics.FONT_SMALL, Graphics.COLOR_GREEN, s[:cue]);
        } else {
            text(dc, h * 0.79, Graphics.FONT_MEDIUM, Graphics.COLOR_WHITE, fmt(e.remaining()));
        }

        if (e.state == Plan.ST_PAUSED) {
            text(dc, h * 0.91, Graphics.FONT_XTINY, Graphics.COLOR_YELLOW, "PAUSED - START");
        } else {
            text(dc, h * 0.91, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, fmt(e.totalElapsed));
        }
    }

    hidden function drawRun(dc) {
        var h = dc.getHeight();
        var s = e.current();
        if (s[:how] != null) {
            drawDrill(dc, s);
            return;
        }
        var tgt = e.targetFor(s);

        // segment title
        var name = s[:name];
        if (s[:rep] != null) {
            name += " " + s[:rep];
        }
        var titleColor = (s[:cd] == true) ? Graphics.COLOR_ORANGE : Graphics.COLOR_WHITE;
        text(dc, h * 0.12, Graphics.FONT_SMALL, titleColor, name);

        // time
        var k = s[:kind];
        if (k == Plan.KIND_MANUAL) {
            text(dc, h * 0.27, Graphics.FONT_MEDIUM, Graphics.COLOR_GREEN, "press LAP");
        } else if (k == Plan.KIND_OPEN) {
            text(dc, h * 0.27, Graphics.FONT_NUMBER_MILD, Graphics.COLOR_WHITE, fmt(e.segElapsed));
        } else {
            text(dc, h * 0.27, Graphics.FONT_NUMBER_MEDIUM, Graphics.COLOR_WHITE, fmt(e.remaining()));
        }

        // cadence
        var cad = e.cadence;
        var cadStr = (cad != null && cad > 0) ? cad.format("%d") : "--";
        text(dc, h * 0.50, Graphics.FONT_NUMBER_MEDIUM, cadenceColor(cad, tgt), cadStr);

        if (tgt != null) {
            text(dc, h * 0.67, Graphics.FONT_SMALL, Graphics.COLOR_LT_GRAY, "spm  target " + tgt.format("%d"));
        } else {
            text(dc, h * 0.67, Graphics.FONT_SMALL, Graphics.COLOR_LT_GRAY, "spm");
        }

        // cue
        text(dc, h * 0.78, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, s[:cue]);

        // footer
        if (e.state == Plan.ST_PAUSED) {
            text(dc, h * 0.89, Graphics.FONT_TINY, Graphics.COLOR_YELLOW, "PAUSED - START");
        } else {
            text(dc, h * 0.89, Graphics.FONT_TINY, Graphics.COLOR_WHITE, fmt(e.totalElapsed));
        }
    }

    hidden function drawSummary(dc) {
        var h = dc.getHeight();
        text(dc, h * 0.14, Graphics.FONT_MEDIUM, Graphics.COLOR_GREEN, "Done!");
        text(dc, h * 0.28, Graphics.FONT_TINY, Graphics.COLOR_WHITE, "Time " + fmt(e.totalElapsed));

        var y = 0.40;
        var avg = e.avgCadence();
        if (avg != null) {
            text(dc, h * y, Graphics.FONT_TINY, Graphics.COLOR_WHITE, "Avg cadence " + avg.format("%d"));
            y += 0.12;
        }
        var pct = e.onTargetPct();
        if (pct != null) {
            text(dc, h * y, Graphics.FONT_TINY, Graphics.COLOR_WHITE, "On target " + pct.format("%d") + "%");
            y += 0.12;
        }
        if (e.newBaseline != null) {
            text(dc, h * y, Graphics.FONT_TINY, Graphics.COLOR_ORANGE, "New baseline " + e.newBaseline.format("%d"));
            y += 0.12;
        } else if (avg != null && !e.baselineIsDefault) {
            var d = avg - e.baseline;
            var sign = (d >= 0) ? "+" : "";
            text(dc, h * y, Graphics.FONT_TINY, Graphics.COLOR_ORANGE,
                 "vs baseline " + sign + d.format("%d"));
            y += 0.12;
        }
        text(dc, h * 0.86, Graphics.FONT_TINY, Graphics.COLOR_LT_GRAY, "START to save");
    }
}

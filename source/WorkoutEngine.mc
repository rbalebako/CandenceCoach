import Toybox.Lang;
import Toybox.Timer;
import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Attention;
import Toybox.Application;
import Toybox.Position;
import Toybox.WatchUi;

// Runs one session: steps through segments, plays the metronome,
// samples cadence, and records a normal FIT running activity.
class WorkoutEngine {

    var id;
    var title;
    var segments;
    var idx = 0;
    var segElapsed = 0;     // seconds in current segment (active time)
    var totalElapsed = 0;   // seconds of active time in the workout
    var state = Plan.ST_READY;
    var showGoal = true;    // goal page comes first, before the ready screen
    var menuItem = null;    // session-list entry, updated after a save
    var saveChosen = false; // Save picked from the pause menu; summary is showing

    var cadence = null;     // latest cadence (spm) from the watch
    var gpsOk = false;
    var baseline;
    var baselineIsDefault = false;

    // stats
    var cadSum = 0;
    var cadN = 0;
    var measSum = 0;
    var measN = 0;
    var onTgt = 0;
    var tgtN = 0;
    var newBaseline = null;

    hidden var _session = null;
    hidden var _tick = null;
    hidden var _met = null;
    hidden var _metMode = 2;   // 0 tone, 1 vibe, 2 both, 3 off

    function initialize(sessionId) {
        id = sessionId;
        title = Plan.shortName(sessionId);
        segments = Plan.build(sessionId);
        _metMode = readProp("metronomeMode", 2);
        loadBaseline();

        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        _tick = new Timer.Timer();
        _tick.start(method(:onTick), 1000, true);
    }

    // ---- settings / storage --------------------------------------------

    function readProp(key, dflt) {
        try {
            var v = Application.Properties.getValue(key);
            if (v != null) {
                return v;
            }
        } catch (e) {
        }
        return dflt;
    }

    function loadBaseline() {
        var p = readProp("baselineCadence", 0);
        if (p > 0) {
            baseline = p;
            baselineIsDefault = false;
            return;
        }
        var st = Application.Storage.getValue("baseline");
        if (st != null) {
            baseline = st;
            baselineIsDefault = false;
        } else {
            baseline = Plan.DEFAULT_BASELINE;
            baselineIsDefault = true;
        }
    }

    // ---- segment info ---------------------------------------------------

    function current() {
        return segments[idx];
    }

    function nextSeg() {
        return (idx + 1 < segments.size()) ? segments[idx + 1] : null;
    }

    function targetFor(seg) {
        if (seg == null) {
            return null;
        }
        var t = seg[:tgt];
        if (t == Plan.TGT_ABS) {
            return seg[:cad];
        }
        if (t == Plan.TGT_REL) {
            return baseline + seg[:cad];
        }
        return null;
    }

    // Seconds left in the segment, or null when not time-limited.
    function remaining() {
        var s = current();
        var k = s[:kind];
        if (k == Plan.KIND_TIMED) {
            return s[:dur] - segElapsed;
        }
        if (k == Plan.KIND_UNTIL_TOTAL) {
            var r = s[:dur] - totalElapsed;
            return (r < 0) ? 0 : r;
        }
        return null;
    }

    // ---- controls -------------------------------------------------------

    function start() {
        if (state != Plan.ST_READY) {
            return;
        }
        _session = ActivityRecording.createSession({
            :name => "Cad " + title,
            :sport => ActivityRecording.SPORT_RUNNING,
            :subSport => ActivityRecording.SUB_SPORT_GENERIC
        });
        _session.start();
        state = Plan.ST_RUNNING;
        tone(Attention.TONE_START);
        enterSegment();
    }

    function pause() {
        if (state != Plan.ST_RUNNING) {
            return;
        }
        _session.stop();
        stopMetronome();
        state = Plan.ST_PAUSED;
        tone(Attention.TONE_STOP);
    }

    function resume() {
        if (state != Plan.ST_PAUSED) {
            return;
        }
        _session.start();
        state = Plan.ST_RUNNING;
        tone(Attention.TONE_START);
        updateMetronome();
    }

    // LAP (BACK button): ends a manual segment, or skips a timed one.
    // An open segment (cool-down) moves on if something follows it (drills);
    // if it's the last segment, LAP just marks a lap.
    function lap() {
        if (state != Plan.ST_RUNNING) {
            return;
        }
        if (current()[:kind] == Plan.KIND_OPEN && nextSeg() == null) {
            _session.addLap();
            tone(Attention.TONE_LAP);
        } else {
            advance();
        }
        WatchUi.requestUpdate();
    }

    function save() {
        if (_session != null) {
            if (_session.isRecording()) {
                _session.stop();
            }
            _session.save();
            _session = null;
        }
        storeResult();
        cleanup();
    }

    function discard() {
        if (_session != null) {
            if (_session.isRecording()) {
                _session.stop();
            }
            _session.discard();
            _session = null;
        }
        cleanup();
    }

    function cleanup() {
        stopMetronome();
        if (_tick != null) {
            _tick.stop();
            _tick = null;
        }
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    // ---- engine ---------------------------------------------------------

    function onPosition(info as Position.Info) as Void {
        gpsOk = (info.accuracy != null && info.accuracy >= Position.QUALITY_USABLE);
    }

    function onTick() as Void {
        // Take the value as-is (including null) so a dropped sensor shows "--"
        // instead of freezing the last reading on screen and in the stats.
        var ai = Activity.getActivityInfo();
        cadence = (ai != null) ? ai.currentCadence : null;

        if (state == Plan.ST_RUNNING) {
            segElapsed++;
            totalElapsed++;
            sample();

            var s = current();
            var k = s[:kind];
            var rem = remaining();
            // "Run done!" keeps nudging every 30 s until you press LAP.
            if (s[:remind] == true && segElapsed % 30 == 0) {
                tone(Attention.TONE_ALERT_HI);
                vibe(100, 500);
            }
            if (k == Plan.KIND_TIMED || k == Plan.KIND_UNTIL_TOTAL) {
                var nx = nextSeg();
                if (rem > 0 && rem <= 3 && nx != null && nx[:cd] == true) {
                    tone(Attention.TONE_ALERT_LO);
                    vibe(60, 120);
                }
                if (rem <= 0) {
                    advance();
                }
            }
        }
        WatchUi.requestUpdate();
    }

    hidden function sample() {
        var s = current();
        // Drills (A-skips, high knees, butt kicks) aren't running cadence.
        if (cadence == null || cadence <= 0 || s[:drill] == true) {
            return;
        }
        cadSum += cadence;
        cadN++;
        if (s[:measure] == true) {
            measSum += cadence;
            measN++;
        }
        var t = targetFor(s);
        // give yourself 5 s to settle into a new target before scoring
        if (t != null && segElapsed > 5) {
            tgtN++;
            if ((cadence - t).abs() <= 3) {
                onTgt++;
            }
        }
    }

    hidden function advance() {
        var s = current();
        if (s[:measure] == true && measN > 0) {
            // Used for the rest of this run; only stored if the run is saved.
            newBaseline = (measSum.toFloat() / measN + 0.5).toNumber();
            if (readProp("baselineCadence", 0) == 0) {
                baseline = newBaseline;
                baselineIsDefault = false;
            }
        }
        if (_session != null) {
            _session.addLap();
        }
        idx++;
        segElapsed = 0;
        if (idx >= segments.size()) {
            idx = segments.size() - 1;
            finish();
        } else {
            enterSegment();
        }
    }

    hidden function enterSegment() {
        var s = current();
        if (s[:cd] == true) {
            tone(Attention.TONE_ALERT_HI);
            vibe(100, 600);
        } else {
            tone(Attention.TONE_LAP);
            vibe(80, 300);
        }
        updateMetronome();
    }

    // Ends the workout and shows the summary. Called when the last step
    // finishes, or when you choose Save from the pause menu.
    function finish() {
        stopMetronome();
        if (_session != null && _session.isRecording()) {
            _session.stop();
        }
        state = Plan.ST_DONE;
        tone(Attention.TONE_SUCCESS);
        vibe(100, 1000);
    }

    hidden function storeResult() {
        if (newBaseline != null) {
            Application.Storage.setValue("baseline", newBaseline);
        }
        if (cadN > 0) {
            Application.Storage.setValue("avg_" + title, avgCadence());
        }
        // Refresh the session list entry so it shows this run's average.
        if (menuItem != null) {
            menuItem.setSubLabel(Plan.menuSub(id));
        }
    }

    function avgCadence() {
        return (cadN > 0) ? (cadSum.toFloat() / cadN + 0.5).toNumber() : null;
    }

    function onTargetPct() {
        return (tgtN > 0) ? (onTgt * 100 / tgtN) : null;
    }

    // ---- metronome -------------------------------------------------------

    hidden function updateMetronome() {
        stopMetronome();
        var s = current();
        var t = targetFor(s);
        if (state != Plan.ST_RUNNING || s[:met] != true || t == null || _metMode == 3) {
            return;
        }
        var div = readProp("beatDivider", 1);
        var periodMs = (60000.0 * div / t).toNumber();
        _met = new Timer.Timer();
        _met.start(method(:onBeat), periodMs, true);
    }

    hidden function stopMetronome() {
        if (_met != null) {
            _met.stop();
            _met = null;
        }
    }

    function onBeat() as Void {
        if (_metMode == 0 || _metMode == 2) {
            tone(Attention.TONE_KEY);
        }
        if (_metMode == 1 || _metMode == 2) {
            vibe(50, 40);
        }
    }

    // ---- feedback helpers -------------------------------------------------

    hidden function tone(t) {
        if (t != null && Attention has :playTone) {
            Attention.playTone(t);
        }
    }

    hidden function vibe(strength, ms) {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(strength, ms)]);
        }
    }
}

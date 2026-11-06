import Toybox.Lang;
import Toybox.WatchUi;

// START = start / pause (opens menu)   BACK = LAP (next step)
class WorkoutDelegate extends WatchUi.BehaviorDelegate {

    hidden var e;

    function initialize(engine) {
        BehaviorDelegate.initialize();
        e = engine;
    }

    function onSelect() as Boolean {
        if (e.state == Plan.ST_READY) {
            if (e.showGoal) {
                e.showGoal = false;     // goal page -> ready screen
            } else {
                e.start();
            }
        } else if (e.state == Plan.ST_RUNNING) {
            e.pause();
            openMenu();
        } else if (e.state == Plan.ST_DONE && e.saveChosen) {
            // Summary after "Save" in the pause menu: START saves and exits.
            e.save();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        } else {
            openMenu();
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        if (e.state == Plan.ST_READY) {
            e.cleanup();
            return false;          // leave to the session list
        }
        if (e.state == Plan.ST_RUNNING) {
            e.lap();
        } else {
            openMenu();
        }
        return true;
    }

    // Ignore the touchscreen so sweaty taps/swipes don't pause or skip.
    function onTap(evt) as Boolean {
        return true;
    }

    function onSwipe(evt) as Boolean {
        return true;
    }

    hidden function openMenu() {
        var m = new WatchUi.Menu2({ :title => (e.state == Plan.ST_DONE) ? "Finished" : "Paused" });
        if (e.state != Plan.ST_DONE) {
            m.addItem(new WatchUi.MenuItem("Resume", null, :resume, null));
        }
        m.addItem(new WatchUi.MenuItem("Save", null, :save, null));
        m.addItem(new WatchUi.MenuItem("Discard", null, :discard, null));
        WatchUi.pushView(m, new PauseMenuDelegate(e), WatchUi.SLIDE_UP);
    }
}

class PauseMenuDelegate extends WatchUi.Menu2InputDelegate {

    hidden var e;

    function initialize(engine) {
        Menu2InputDelegate.initialize();
        e = engine;
    }

    function onSelect(item) {
        var id = item.getId();
        if (id == :resume) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            e.resume();
        } else if (id == :save && e.state != Plan.ST_DONE) {
            // Stopped early: end the workout and show the summary first.
            // START on the summary then saves (see WorkoutDelegate.onSelect).
            e.finish();
            e.saveChosen = true;
            WatchUi.popView(WatchUi.SLIDE_DOWN);        // menu -> summary
        } else if (id == :save || id == :discard) {
            if (id == :save) {
                e.save();
            } else {
                e.discard();
            }
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);   // menu
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);   // workout screen
        }
    }

    // BACK just closes the menu; the workout stays paused (START reopens it).
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class SessionMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var engine = new WorkoutEngine(item.getId());
        engine.menuItem = item;
        WatchUi.pushView(new WorkoutView(engine), new WorkoutDelegate(engine), WatchUi.SLIDE_LEFT);
    }
}

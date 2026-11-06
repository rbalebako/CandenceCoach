import Toybox.Lang;
import Toybox.Application;
import Toybox.WatchUi;

class CadenceCoachApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var menu = new WatchUi.Menu2({ :title => "Cadence Coach" });
        var c = Plan.catalogue();
        for (var i = 0; i < c.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(c[i][1], Plan.menuSub(c[i][0]), c[i][0], null));
        }
        return [menu, new SessionMenuDelegate()];
    }
}

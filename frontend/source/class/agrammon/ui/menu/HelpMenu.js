/* ************************************************************************

************************************************************************ */

qx.Class.define('agrammon.ui.menu.HelpMenu', {
    extend: qx.ui.menu.Menu,

    construct: function () {
        this.base(arguments);

        var about = agrammon.ui.About.getInstance();
        var aboutCommand = new qx.ui.command.Command();
        aboutCommand.addListener("execute",
            function(e) {
                about.open();
            }, this);
        var aboutButton =
            new qx.ui.menu.Button(this.tr("About AGRAMMON"),
                                  null, aboutCommand);
        this.add(aboutButton);

        return;

    }, // construct

    members :
    {
    }

});

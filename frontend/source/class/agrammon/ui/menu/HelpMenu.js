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
        var aboutButton = new qx.ui.menu.Button(this.tr("About AGRAMMON"), null, aboutCommand);
        this.add(aboutButton);

        var changelog = agrammon.Changelog.getInstance();
        var changelogCommand = new qx.ui.command.Command();
        changelogCommand.addListener("execute",
            function(e) {
                changelog.open();
            }, this);
        var changelogButton = new qx.ui.menu.Button(this.tr("CHANGELOG"), null,changelogCommand);
        this.add(changelogButton);
    },

    members : {
    }

});

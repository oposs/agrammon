/*****************************************
  Agrammon
   Copyright: OETIKER+PARTNER AG, 2021-
   Authors:   Fritz Zaucker
 *****************************************/

/**
 * @asset(agrammon/*)
 */

// TODO @ignore -> qx-showdown

qx.Class.define("agrammon.Changelog", {
    extend : qx.ui.window.Window,
    type : "singleton",

    construct : function() {
        this.base(arguments);
        this.set({
            caption : this.tr('Changelog'),
            layout  : new qx.ui.layout.VBox(10),
            minWidth : 600,
            minHeight : 400,
            centerOnAppear: true
        });

        let docu = new qx.ui.embed.Html();
        qxShowdown.Load;

        this.addListenerOnce('appear', function() {
           let req = new qx.io.remote.Request("doc/CHANGELOG.md");
           req.addListener("completed", function (e) {
                let md = e.getContent();
                let converter = new showdown.Converter();
                docu.setHtml(converter.makeHtml(md));
            });
            req.send();
        }, this);

        docu.set({
            minWidth : 500,
            minHeight : 350
        });
        // This makes the docu scrollable ad infinitum
        docu.setOverflow("auto", "auto");
        this.add(docu);

    },

    members: {
    }

});

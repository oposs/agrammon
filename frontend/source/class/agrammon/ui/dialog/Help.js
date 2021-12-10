/* ************************************************************************
   Copyright: 2008, OETIKER+PARTNER AG
   License: GPL
   Author: Fritz Zaucker
************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/help-faq.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-close.png)
 */

/**
 */
qx.Class.define('agrammon.ui.dialog.Help', {
    extend : qx.ui.window.Window,

    construct : function() {
        this.base(arguments);

        this.set({
            modal          : false,
            showMinimize   : true,
            showMaximize   : true,
            resizable      : true,
            contentPadding : 10,
            allowGrowX: true,
            allowGrowY: true,
            icon: "icon/16/actions/help-faq.png"
        });
        this.getChildControl("pane").setBackgroundColor("white");
        this.setLayout(new qx.ui.layout.VBox(10));

        var scrollBox = new qx.ui.container.Stack();
        scrollBox.setMinWidth(500);
        scrollBox.setMinHeight(250);
        scrollBox.setAllowGrowX(true);
        scrollBox.setAllowGrowY(true);
        scrollBox.setBackgroundColor("white");

        var help = new qx.ui.embed.Html();
        help.setOverflow("auto", "auto");
        help.setPadding(10);
        help.setBackgroundColor("white");
        help.setAllowStretchX(true);
        help.setAllowGrowY(true);

        scrollBox.add(help);
        this.add(scrollBox, {flex: 1});

        var box = new qx.ui.container.Composite;
        box.setLayout(new qx.ui.layout.HBox(5, "right"));
        this.add(box);

        var btn = new qx.ui.form.Button("Close", "icon/16/actions/dialog-close.png");
        var that = this;

        this.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                btn.execute();
            }
        });

        btn.addListener("execute", function(e) {
            that.close();
        });

        box.add(btn);

        qx.event.message.Bus.subscribe('help', function(msg) {
            var data = msg.getData();
            var caption  = data.caption;
            var helpText = data.helpText;
            caption = caption.replace(/\[.+\]/,'[]');
            that.setCaption(caption);

            if (helpText != undefined && helpText != null) {
                help.setHtml(helpText);
            }
            else {
                help.setHtml(this.tr("Help undefined"));
            }
            that.center();
            that.open();
            btn.focus();
        });
    },

    members : {
    }
});

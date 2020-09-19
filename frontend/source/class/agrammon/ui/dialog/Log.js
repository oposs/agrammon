/* ************************************************************************
   Copyright: 2008, OETIKER+PARTNER AG
   License: GPL
   Authors: Tobias Oetiker
************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/help-faq.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-close.png)
 */

/**
 * An Error Popup Window that shows messages
 * sent to to 'error' message bus.
 * Usage:
 * qx.event.message.Bus.dispatchByName('error', [ this.tr("Error test"),
 *                                          this.tr("This is just a test.") ]);
 */
qx.Class.define('agrammon.ui.dialog.Log', {
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
                   height: 500,
            icon: "icon/16/actions/help-faq.png"
        });
        this.getChildControl("pane").setBackgroundColor("white");
        this.setLayout(new qx.ui.layout.VBox(10));

        var scrollBox = new qx.ui.container.Stack();
        scrollBox.setMinWidth(500);
        scrollBox.setMinHeight(500);
        scrollBox.setAllowGrowX(true);
        scrollBox.setAllowGrowY(true);
        scrollBox.setBackgroundColor("white");

        var help = new qx.ui.embed.Html();
        help.setOverflow("auto", "auto");
        help.setPadding(10);
        help.setBackgroundColor("white");
        help.setAllowStretchX(true);
        help.setAllowGrowY(true);

//        scrollBox.add(help, {flex: 1});
//        scrollBox.add(help);
//        this.add(scrollBox, {flex: 1});
        this.add(help, {flex: 1});

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

        qx.event.message.Bus.subscribe('log', function(msg) {
            var data = msg.getData();
            var caption  = data.caption;
            var logData = data.log;
            var locale = qx.locale.Manager.getInstance().getLocale();
            locale = locale.replace(/_.+/,'');
            var i, len = logData.length;
            var logText = '';
            for (i=0; i<len; i++) {
                logText += '<dt><b>'+logData[i]['msg'][locale]+'</b></dt>';
                logText += '<dd>('+logData[i]['var']+')</dd>';
            }
            caption = caption.replace(/\[.+\]/,'[]');
            that.setCaption(caption);

            if (logText != undefined && logText != null && logText != '') {
                help.setHtml('<dl>' + logText + '</dl>');
            }
            else {
                help.setHtml(that.tr("No log messages."));
            }
            that.center();
            that.open();
            btn.focus();
        });
    },

    members :
    {
    }
});

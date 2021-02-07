/* ************************************************************************
   Copyright: 2008, OETIKER+PARTNER AG
   License: GPL
   Authors: Tobias Oetiker
************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/32/status/dialog-error.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
 */

/**
 * An Error Popup Window that shows messages
 * sent to to 'error' message bus.
 * Usage:
 * qx.event.message.Bus.dispatchByName('error', [ this.tr("Error test"),
 *                                          this.tr("This is just a test."),
 *                                          'info' or 'error', // selects mode
 *                                          { msg: msg, data: data}   // dispatch msg (optional)
 *                                        ]);
 */
qx.Class.define('agrammon.ui.dialog.Error', {
    extend : qx.ui.window.Window,

    construct : function() {
        this.base(arguments);

        this.set({
            modal          : true,
            showMinimize   : false,
            showMaximize   : false,
            resizable      : true,
            contentPadding : 20,
            zIndex: 10000
        });

        this.setLayout(new qx.ui.layout.VBox(10));
        var error = new qx.ui.basic.Atom(null, "icon/32/status/dialog-error.png");
        error.setRich(true);
        error.setGap(10);
        error.setWidth(400);
        this.add(error);

        var box = new qx.ui.container.Composite;
        box.setLayout(new qx.ui.layout.HBox(5, "right"));
        this.add(box);

        var btn = new qx.ui.form.Button("OK", "icon/16/actions/dialog-ok.png");
        var that = this;

        this.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                btn.execute();
            }
        });

        btn.addListener("execute", function(e) {
            if (that.__msg) {
                qx.event.message.Bus.dispatchByName(that.__msg.msg, that.__msg.data);
            }
            that.close();
        });

        box.add(btn);

        qx.event.message.Bus.subscribe('error', function(m) {
            var data = m.getData();
            that.setCaption(data[0]);
            error.setLabel(data[1]);
            if (data[2] == 'info') {
                error.setIcon(null);
//                that.setModal(false);
            }
            else {
                error.setIcon('icon/32/status/dialog-error.png');
                that.setModal(true);
            }
            that.__msg = data[3];
            that.center();
            that.open();
            btn.focus();
        });
    },

    members :
    {
        __msg: null
    }
});

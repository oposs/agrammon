/* ************************************************************************

************************************************************************ */

/**
  * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
  * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
  */

qx.Class.define('agrammon.ui.dialog.Confirm', {
    extend: qx.ui.window.Window,

    // FIX ME: context is not used
    //         recycle this widget; perhaps join with Dialog widget
    //         or use Dialog contrib?
    construct: function (title, label, execFunc, context, infoOnly) {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox(10));

        // qx.locale.Manager.getInstance().addListener("changeLocale",
        //                                                 this._update, this);

        this.set({modal: true, showClose: false, // centered: true,
                  padding:0, height: 100, width: 300});
        this.setCaption(title);

        var vbox = new qx.ui.container.Composite(new qx.ui.layout.VBox());
        this.add(vbox);

        var question = new qx.ui.basic.Label(label);
        question.setRich(true);
        vbox.add(question);

        var btnOK = new qx.ui.form.Button("Ok", "icon/16/actions/dialog-ok.png");

        btnOK.addListener("execute", function(e) {
            execFunc(this);
        }, this);

        this.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                btnCancel.execute();
            }
        });

        var buttonRow = new qx.ui.container.Composite(new qx.ui.layout.HBox(10,'right'));
        if (!infoOnly) {
            var btnCancel =
                new qx.ui.form.Button(this.tr("Cancel"), "icon/16/actions/dialog-cancel.png");
            btnCancel.addListener("execute", function(e) {
                this.close();
            }, this);
            buttonRow.add(btnCancel);
        }

        buttonRow.add(btnOK);
        this.add(buttonRow);

        this.addListener('appear', function() {
            if (!infoOnly) {
                btnCancel.focus();
            }
            else {
                btnOK.focus();
            }
        }, this);

        this.addListenerOnce("resize", this.center, this);
        this.open();
    }, // construct

    members :
    {
    }
});

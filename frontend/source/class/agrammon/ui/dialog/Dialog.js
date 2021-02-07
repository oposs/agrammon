/* ************************************************************************

************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/utilities-text-editor.png)
 */

qx.Class.define('agrammon.ui.dialog.Dialog', {
    extend: qx.ui.window.Window,

    // FIX ME: navBar is not used
    //         recycle this widget; perhaps join with Confirm
    //         or use Dialog contrib?
    construct: function (title, label, value, execFunc, navBar) {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox(10));

        if (value == null) {
            value = '';
        }
        // qx.locale.Manager.getInstance().addListener("changeLocale",
        //                                                 this._update, this);

        this.navBar = navBar;
        this.set({modal: true, showClose: false, // centered: true,
                  padding:0, height: 100, width: 300});
        this.setCaption(title);

        var vbox = new qx.ui.container.Composite(new qx.ui.layout.VBox());
        this.add(vbox);

        this.setIcon("icon/16/apps/utilities-text-editor.png");
        var nameLabel = new qx.ui.basic.Label(label);
        vbox.add(nameLabel);

        var nameField = new qx.ui.form.TextField(value);
        this.nameField = nameField;
        vbox.add(nameField);
        nameField.focus();

        var btnCancel =
            new qx.ui.form.Button(this.tr("Cancel"), "icon/16/actions/dialog-cancel.png");
        btnCancel.addListener("execute", function(e) {
            this.close();
        }, this);

        var btnOK = new qx.ui.form.Button("Ok", "icon/16/actions/dialog-ok.png");

        btnOK.addListener("execute", function(e) {
            execFunc(this);
        }, this);

        this.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                btnOK.execute();
            }
        });

        var buttonRow = new qx.ui.container.Composite(new qx.ui.layout.HBox(10));
        buttonRow.add(btnCancel);
        buttonRow.add(btnOK);
        this.add(buttonRow);

        this.addListenerOnce("resize", this.center, this);
        this.open();
        return this;
    }, // construct

    members :
    {
    }
});

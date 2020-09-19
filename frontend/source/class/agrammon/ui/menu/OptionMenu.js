/* ************************************************************************

************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/utilities-text-editor.png)
 */

qx.Class.define('agrammon.ui.menu.OptionMenu', {
    extend: qx.ui.menu.Menu,

     /**
       * TODOC
       *
       * @return {var} TODOC
       * @lint ignoreDeprecated(alert)
       */
    construct: function () {
        this.base(arguments);

        this.__info = agrammon.Info.getInstance();
        this.__rpc  = agrammon.io.remote.Rpc.getInstance();

	var username = this.__info.getUserName();

        var langCommand = new qx.ui.command.Command();

        langCommand.addListener("execute",
            function(e) {
                var locale = e.getData().getLabel();
                qx.locale.Manager.getInstance().setLocale(locale);
        });
        var langMenu = new qx.ui.menu.Menu;
        var enButton = new qx.ui.menu.Button("en", null, langCommand);
        var deButton = new qx.ui.menu.Button("de", null, langCommand);
        var frButton = new qx.ui.menu.Button("fr", null, langCommand);
        langMenu.add(enButton);
        langMenu.add(deButton);
        langMenu.add(frButton);

//        var itButton = new qx.ui.menu.Button("it", null, langCommand);
//        langMenu.add(itButton);
        var langButton = new qx.ui.menu.Button(this.tr("Set language ..."),
                                               null, null, langMenu);

        var passwordDialog =
            new qx.ui.window.Window(this.tr("Changing password for ")
                                           + username,
                                    "icon/16/apps/utilities-text-editor.png");
        passwordDialog.setLayout(new qx.ui.layout.VBox(10));

        var hbox = new qx.ui.container.Composite(new qx.ui.layout.HBox());
        passwordDialog.add(hbox);

        var ibox = new qx.ui.container.Composite(new qx.ui.layout.VBox());

        var vbox = new qx.ui.container.Composite(new qx.ui.layout.VBox());
        hbox.add(vbox);
        vbox.add(ibox);

        var oldPassword = new agrammon.ui.form.VarPassword(this.tr("Current password"),
                                                '','','');
        this.oldPassword = oldPassword;
        ibox.add(oldPassword);
        oldPassword.setPadding(5);

        var newPassword1 =
            new agrammon.ui.form.VarPassword(this.tr("New password (at least 6 characters)"),
                                                '','','');
        this.newPassword1 = newPassword1;
        ibox.add(newPassword1);
        newPassword1.setPadding(5);

        var newPassword2 =
            new agrammon.ui.form.VarPassword(this.tr("Confirm password"),'','','');
        this.newPassword2 = newPassword2;
        ibox.add(newPassword2);
        newPassword2.setPadding(5);

        var bbox = new qx.ui.container.Composite(new qx.ui.layout.HBox(10));
        vbox.add(bbox);

        var btnOK = new qx.ui.form.Button("Ok",
                                        "icon/16/actions/dialog-ok.png");
        var btnCancel = new qx.ui.form.Button(this.tr("Cancel"),
                                        "icon/16/actions/dialog-cancel.png");

        btnCancel.addListener("execute",
            function(e) {
                this.newPassword1.clearValue();
                this.newPassword2.clearValue();
                this.oldPassword.clearValue();
                passwordDialog.close();
            },
            this
        );

        btnOK.addListener("execute",
            function(e) {
                var oldPW  = this.oldPassword.getValue();
                var newPW1 = this.newPassword1.getValue();
                var newPW2 = this.newPassword2.getValue();
                if (newPW1 != newPW2) {
                    alert(this.tr("Passwords did not match. Please try again."));
                }
                else {
                    // this.debug('password: ' + oldPW + ' -> ' + newPW1);
                    this.__rpc.callAsync(
                        qx.lang.Function.bind(this.__changePassword, this),
//                        'change_password', oldPW, newPW1
                        'change_password', {old : oldPW, 'new' : newPW1}
                    );
                }
                this.newPassword1.clearValue();
                this.newPassword2.clearValue();
                this.oldPassword.clearValue();
                passwordDialog.close();
            },
            this
        );

        this.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                btnOK.execute();
            }
        });


        bbox.add(btnCancel);
        bbox.add(btnOK);

        var passwordCommand = new qx.ui.command.Command();
        passwordCommand.addListener("execute",
            function(e) {
        	var username = this.__info.getUserName();
                passwordDialog.setCaption(this.tr("Changing password for ")
                                          + username);
                passwordDialog.open();
                // var cmd = e.getData().getLabel();
                //alert(cmd + ' not yet implemented');
            },
            this
        );

        var passwordButton = new qx.ui.menu.Button(this.tr("Change password"),
                                                   null, passwordCommand);
        this.add(langButton);
        this.add(passwordButton);

        return;

    }, // construct

    members :
    {
        __rpc:  null,
        __info: null,

        __changePassword: function(data, exc, id) {
            if (exc == null) {
                qx.event.message.Bus.dispatchByName('error',
                                    [ this.tr("Info"),
                                      this.tr("Password changed successfully."),
                                      'info'
                                    ]);
            }
            else {
                qx.event.message.Bus.dispatchByName('error',
                                [ this.tr("Info"),
                                  this.tr("Password change failed, please try again.") ]);
            }
        }

    }
});

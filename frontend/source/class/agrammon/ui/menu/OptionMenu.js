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

        // Model-version submenu. Hidden until setVersions() is called with
        // a non-empty Versions block; populated lazily so labels match the
        // current config and the active entry is disabled.
        var versionMenu = new qx.ui.menu.Menu;
        var versionButton = new qx.ui.menu.Button(this.tr("Set model version ..."),
                                                  null, null, versionMenu);
        versionButton.exclude();
        this.__versionMenu = versionMenu;
        this.__versionButton = versionButton;

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
            new agrammon.ui.form.VarPassword(this.tr("New password (at least 8 characters)"),
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
                        'change_password', {oldPassword : oldPW, newPassword : newPW1}
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
        this.add(versionButton);
        this.add(passwordButton);

        return;

    }, // construct

    members :
    {
        __rpc:  null,
        __info: null,
        __versionMenu:   null,
        __versionButton: null,
        __activeVersion: null,

        /**
         * Populate the model-version submenu.
         *
         * @param versions {Array}  list of { label, url, version, title }
         * @param activeVersion {String}  Model.version string of THIS process
         */
        setVersions: function(versions, activeVersion) {
            this.__activeVersion = activeVersion;
            this.__versionMenu.removeAll();

            if (!versions || !versions.length) {
                this.__versionButton.exclude();
                return;
            }

            for (var i = 0; i < versions.length; i++) {
                var v = versions[i];
                var btn = new qx.ui.menu.Button(v.guiVersion);
                btn.setUserData('versionEntry', v);
                if (v.version === activeVersion) {
                    // Can't switch to ourselves — make it visually obvious
                    // and unclickable.
                    btn.setEnabled(false);
                }
                else {
                    btn.addListener('execute', this.__onVersionPick, this);
                }
                this.__versionMenu.add(btn);
            }
            this.__versionButton.show();
        },

        __onVersionPick: function(e) {
            var entry = e.getTarget().getUserData('versionEntry');
            if (!entry) return;

            if (this.__isOlder(entry.version, this.__activeVersion)) {
                var prevActive = this.__activeVersion;
                var dialog = new agrammon.ui.dialog.Confirm(
                    this.tr("Switch to older model version?"),
                    this.tr("You are switching from the current model version %1 to the older version %2. Inputs from %1 that did not exist yet in %2 will either be converted and displayed in orange, or in certain instances, hidden entirely. You find information about the changes between model versions in the documents “Information on the version of Agrammon” at https://agrammon.ch/en/downloads/",
                            prevActive, entry.version),
                    function () {
                        dialog.close();
                        window.location.assign(entry.url);
                    },
                    this,
                    false
                );
                dialog.open();
            }
            else {
                window.location.assign(entry.url);
            }
        },

        /**
         * true iff `a` is strictly older than `b`.
         *
         * Only pure dotted-numeric versions (e.g. "6.6.0") are accepted.
         * Pre-release tags (-rc1, -alpha), build metadata (+build),
         * "v" prefixes and the like are not parsed: callers get a console
         * warning and the version is treated as not-older, so navigation
         * proceeds without the downgrade-confirm dialog.
         */
        __isOlder: function(a, b) {
            if (!a || !b) return false;
            var pa = this.__parseVersion(a);
            var pb = this.__parseVersion(b);
            if (pa === null || pb === null) return false;
            var n = Math.max(pa.length, pb.length);
            for (var i = 0; i < n; i++) {
                var x = pa[i] || 0, y = pb[i] || 0;
                if (x < y) return true;
                if (x > y) return false;
            }
            return false;
        },

        /** Returns Array<Number> for "1.2.3", or null (and warns) otherwise. */
        __parseVersion: function(v) {
            var s = String(v);
            if (!/^\d+(\.\d+)*$/.test(s)) {
                this.warn("OptionMenu: version string '" + s + "' is not pure dotted-numeric; downgrade comparison disabled for it.");
                return null;
            }
            return s.split('.').map(Number);
        },

        __changePassword: function(data, exc, id) {
            if (exc == null && ! data.error) {
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

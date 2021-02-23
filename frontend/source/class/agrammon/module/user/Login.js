/* ************************************************************************

************************************************************************ */

/**
 * @asset(agrammon/help-about.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
 */

qx.Class.define('agrammon.module.user.Login', {
    extend: qx.ui.window.Window,

    construct: function (title, sudo) {
        this.base(arguments);
        this.__rpc  = agrammon.io.remote.Rpc.getInstance();
        this.__baseUrl = this.__rpc.getBaseUrl();
        this.setLayout(new qx.ui.layout.HBox(10));

        var that = this;
        this.set({
            modal: true,
            showClose: false, showMinimize: false, showMaximize: false,
            centerOnAppear : true,
            caption: title
        });

        var leftBox =
            new qx.ui.container.Composite(new qx.ui.layout.VBox(10));
        leftBox.setWidth(300);
        var rightBox =
            new qx.ui.container.Composite(new qx.ui.layout.VBox(10));
        this.add(leftBox, {flex:1});
        this.add(new qx.ui.core.Spacer(50));
        if (!sudo) {
            this.add(rightBox);
        }

        qx.locale.Manager.getInstance().addListener("changeLocale", this.__changeLanguage, this);

        var user = this.__user = new agrammon.ui.form.VarInput(this.tr("Username"), '', '', '', 'Enter username');
        leftBox.add(user);
        user.setPadding(5);
        user.setPaddingBottom(0);

        var password = this.__password = new agrammon.ui.form.VarPassword(this.tr("Password"));
        password.setPadding(5);
        password.setPaddingTop(0);
        if (!sudo) {
            leftBox.add(password);
        }

        if (this.supports_html5_storage() && !sudo) {
            var remember = new qx.ui.form.CheckBox(this.tr("Remember"));
            this.__remember = remember;
            leftBox.add(remember);
        }

        leftBox.add(new qx.ui.core.Spacer(50));

        var bbox = new qx.ui.container.Composite(new qx.ui.layout.HBox(10));
        bbox.setPaddingLeft(5);
        bbox.setPaddingRight(5);
        leftBox.add(bbox);
        var btnOK =
            new qx.ui.form.Button("Login", "icon/16/actions/dialog-ok.png");

        var btnNew =
            new qx.ui.form.Button(this.tr("Create New Account"),
                                  "icon/16/actions/dialog-ok.png");
        this.btnNew = btnNew;

        var btnPassword =
            new qx.ui.form.Button(this.tr("Reset Password"),
                                  "icon/16/actions/dialog-ok.png");
        this.btnPassword = btnPassword;

        var btnHelp =
            new qx.ui.form.Button(this.tr("Help"),
                                  "agrammon/help-about.png");
        var btnCancel =
            new qx.ui.form.Button(this.tr("Cancel"),
                                  "icon/16/actions/dialog-cancel.png");

        btnCancel.addListener("execute", function(e) {
            this.__user.clearValue();
            this.__password.clearValue();
            if (sudo) {
                that.close();
            }
        }, this);

        // FIX ME: deal with sub locales
        var locale = qx.locale.Manager.getInstance().getLocale();
        locale = locale.replace(/_.+/,'');
        var help = this.__help = new agrammon.ui.dialog.DocWindow(
            this.tr("Help"),
            this.__baseUrl + 'doc/login.' + locale + '.html'
        );
        btnHelp.addListener("execute", function(e) {
            this.__user.clearValue();
            this.__password.clearValue();
            help.open();
        }, this);

        btnOK.addListener("execute", function(e) {
            var username = this.__user.getValue();
            var password = this.__password.getValue();
            var remember = false;
            if (that.supports_html5_storage() && !sudo) {
                remember = that.__remember.getValue();
            }

            this.__password.clearValue();
            qx.event.message.Bus.dispatchByName(
                'agrammon.main.login',
                {
                    username : username, password : password,
                    remember : remember, sudo : sudo
                }
            );
            this.close();
        }, this);

        btnNew.addListener("execute", function(e) {
            var username  = this.__user.getValue();
            var newDialog = new agrammon.module.user.Account(this.tr("Create new account"), username, 'userCreate');
            newDialog.open();
            this.__password.clearValue();
            this.close();
        } ,this);

        btnPassword.addListener("execute", function(e) {
            var username  = this.__user.getValue();
            var newDialog = new agrammon.module.user.Account(this.tr("Reset password"), username, 'reset');
            newDialog.open();
            this.__password.clearValue();
            this.close();
        }, this);

        bbox.add(btnCancel, {flex : 1});
        bbox.add(btnOK, {flex : 1});
        rightBox.add(new qx.ui.core.Spacer(1), {flex : 1});
        rightBox.add(btnHelp, {flex : 0});
        rightBox.add(btnPassword, {flex : 0});
        rightBox.add(btnNew, {flex : 0});

        this.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                btnOK.execute();
            }
        });

        var idx = 1;
        user.setTabIndex(idx++);
        password.setTabIndex(idx++);
        if (this.supports_html5_storage() && !sudo) {
            remember.setTabIndex(idx++);
        }
        btnCancel.setTabIndex(idx++);
        btnOK.setTabIndex(idx++);
        btnHelp.setTabIndex(idx++);
        btnPassword.setTabIndex(idx++);
        btnNew.setTabIndex(idx++);

        this.addListener('appear', function() {
            var appUsername, appPassword, appRemember;
            if (this.supports_html5_storage()) {
                appUsername = localStorage.getItem('agrammonUsername');
                appPassword = localStorage.getItem('agrammonPassword');
                appRemember = (localStorage.getItem('agrammonRemember') == 'true');
            }

            if (remember != undefined && appRemember != null) {
                remember.setValue(appRemember);
            }
            if (appUsername != null && !sudo) {
                user.setValue(appUsername);
            }
            if (appPassword != null) {
                password.setValue(appPassword);
            }

            if (!user.getValue()) {
                user.focus();
            }
            else if (!password.getValue()) {
                password.getInputField().focus();
            }
            else {
                btnOK.focus();
            }

        }, this);

    }, // construct

    members :
    {
        __rpc      : null,
        __baseUrl  : null,
        __user     : null,
        __help     : null,
        __password : null,

        supports_html5_storage: function() {
            try {
                return 'localStorage' in window && window['localStorage'] !== null;
            } catch (e) {
                return false;
            }
        },

        __changeLanguage: function() {
            // FIX ME: deal with sub locales
            var locale = qx.locale.Manager.getInstance().getLocale();
            locale = locale.replace(/_.+/,'');
            this.debug('Login: locale='+locale);
            this.__help.setSource(this.__baseUrl + 'doc/login.' + locale + '.html');
        }

    }
});

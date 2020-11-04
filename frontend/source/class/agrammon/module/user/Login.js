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
        this.set({modal: true,
                  showClose: false, showMinimize: false, showMaximize: false,
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

        qx.locale.Manager.getInstance().addListener("changeLocale",
                                                    this.__changeLanguage,
                                                    this);

        var user = new agrammon.ui.form.VarInput(this.tr("Username"), '', '', '', 'Enter username');
        this.user = user;
        leftBox.add(user);
        user.setPadding(5);
        user.setPaddingBottom(0);

        var password = new agrammon.ui.form.VarPassword(this.tr("Password"));
        password.setPadding(5);
        password.setPaddingTop(0);
        this.password = password;
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
            this.user.clearValue();
            this.password.clearValue();
            if (sudo) {
                that.close();
            }
        }, this);

        // FIX ME: deal with sub locales
        var locale = qx.locale.Manager.getInstance().getLocale();
        locale = locale.replace(/_.+/,'');
//        this.debug('Login: locale='+locale);
        var help = new agrammon.ui.dialog.DocWindow(this.tr("Help"),
                                             this.__baseUrl + 'doc/login.'
                                             + locale + '.html');
        this.help = help;
        btnHelp.addListener("execute",
            function(e) {
                this.user.clearValue();
                this.password.clearValue();
                help.open();
            },
            this
        );

        btnOK.addListener("execute",
            function(e) {
                var username      = this.user.getValue();
                var password      = this.password.getValue();
                var remember = false;
                if (that.supports_html5_storage() && !sudo) {
                    remember = that.__remember.getValue();
                }
                
			    var userShortcuts = {
                    'fz': 'fritz.zaucker@oetiker.ch',
                    'rp': 'roman.plessl@oetiker.ch',
                    'to': 'tobias@oetiker.ch',
                    'mo': 'manuel@oetiker.ch',
                    'hr': 'hr@bjengineering.ch',
                    'cb': 'cyrill.bonjour@bjengineering.ch',
                    'hm': 'harald.menzi@bfh.ch',
                    'ba': 'beat.achermann@bafu.admin.ch',
                    'cl': 'christian.leuenberger@leupro.ch',
                    'an': 'aurelia.nyfeler@bjengineering.ch',
                    'tk': 'thomas.kupper@bfh.ch',
                    'fb': 'fritz.birrer@lu.ch'
                };
                for (var key in userShortcuts) {
                    if (username == key) {
                        username = userShortcuts[key];
                        break;
                    }
                }
                this.password.clearValue();
                var sudoUser;
                if (sudo) {
                    sudoUser = agrammon.Info.getInstance().getUserName();
                }
                qx.event.message.Bus.dispatchByName('agrammon.main.login',
                                              {'user':     username,
                                               'password': password,
                                               'remember': remember,
                                               'sudoUser': sudoUser
                                               });
                this.close();
            },
           this
        );

        btnNew.addListener("execute",
            function(e) {
                this.debug('btNew: this='+this);
                var username    = this.user.getValue();
                var newDialog =
                    new agrammon.module.user.Account(this.tr("Create new account"),
                                                     username, 'userCreate');
                newDialog.open();
                this.password.clearValue();
                this.close();
            },
           this
        );

        btnPassword.addListener("execute",
            function(e) {
                this.debug('btPassword: this='+this);
                var username    = this.user.getValue();
                var newDialog =
                    new agrammon.module.user.Account(this.tr("Reset password"),
                                                     username, 'reset');
                newDialog.open();
                this.password.clearValue();
                this.close();
            },
           this
        );

        bbox.add(btnCancel, {flex : 1});
        bbox.add(btnOK, {flex : 1});
        rightBox.add(new qx.ui.core.Spacer(1), {flex : 1});
        rightBox.add(btnHelp, {flex : 0});
        rightBox.add(btnPassword, {flex : 0});
        rightBox.add(btnNew, {flex : 0});

        //  breaks internet explorer
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
            this.center();
            this.debug('login appear');
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

            if (user.getValue() != '' && password.getValue() != '') {
                btnOK.focus();
            }
            else if (user.getValue() != null) {
                password.focus();
            }
            else {
                user.focus();
            }

        }, this);

//        var root = qx.core.Init.getApplication().getRoot();
//        this.open();
//        root.add(this);
    }, // construct

    members :
    {
        __rpc: null,
        __baseUrl: null,

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
//            this.debug('Login: locale='+locale);
            locale = locale.replace(/_.+/,'');
            this.debug('Login: locale='+locale);
            this.help.setSource(this.__baseUrl
                                + 'doc/login.' + locale + '.html');
        }

    }
});

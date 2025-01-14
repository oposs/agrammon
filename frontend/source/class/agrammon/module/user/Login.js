/* ************************************************************************

************************************************************************ */

/**
 * @asset(agrammon/help-about.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
 */

qx.Class.define('agrammon.module.user.Login', {
    extend: qx.ui.window.Window,

    construct: function (title, sudo, retry) {
        this.base(arguments);
        this.__baseUrl = agrammon.io.remote.Rpc.getInstance().getBaseUrl();
        this.setLayout(new qx.ui.layout.HBox(10));
        qx.core.Id.getInstance().register(this, "Login");
        this.setQxObjectId("Login");

        // content of the form elements if they appear inside a form AND
        // the form has a name (firefox comes to mind).
        var el = this.getContentElement();
        var form = new qx.html.Element('form',null,{name: 'AgrammonLoginform', autocomplete: 'on'});
        form.insertBefore(el);
        el.insertInto(form);

        let that = this;
        this.set({
            modal: true,
            showClose: false, showMinimize: false, showMaximize: false,
            centerOnAppear : true
        });
        if (title !== undefined) {
            this.setCaption(title);
        }

        let leftBox =
            new qx.ui.container.Composite(new qx.ui.layout.VBox(10));
        leftBox.setWidth(300);
        let rightBox =
            new qx.ui.container.Composite(new qx.ui.layout.VBox(10));
        this.add(leftBox, {flex:1});
        this.add(new qx.ui.core.Spacer(50));
        if (!sudo) {
            this.add(rightBox);
        }

        qx.locale.Manager.getInstance().addListener("changeLocale", this.__changeLanguage, this);

        let user = this.__user = new agrammon.ui.form.VarInput(this.tr("Username"), '', '', '', 'Enter username');
        this.addOwnedQxObject(user, "Username");
        leftBox.add(user);
        user.setPadding(5);
        user.setPaddingBottom(0);

        let password = this.__password = new agrammon.ui.form.VarPassword(this.tr("Password"));
        this.addOwnedQxObject(password, "Password");
        password.setPadding(5);
        password.setPaddingTop(0);
        if (!sudo) {
            leftBox.add(password);
        }

        leftBox.add(new qx.ui.core.Spacer(50));

        let bbox = new qx.ui.container.Composite(new qx.ui.layout.HBox(10));
        bbox.setPaddingLeft(5);
        bbox.setPaddingRight(5);
        leftBox.add(bbox);

        let btnOK =
            new qx.ui.form.Button("Login", "icon/16/actions/dialog-ok.png");
        this.addOwnedQxObject(btnOK, "LoginButton");

        let btnNew =
            new qx.ui.form.Button(this.tr("Create New Account"), "icon/16/actions/dialog-ok.png");
        this.addOwnedQxObject(btnNew, "NewButton");
        this.btnNew = btnNew;

        let btnPassword =
            new qx.ui.form.Button(this.tr("Reset Password"), "icon/16/actions/dialog-ok.png");
        this.addOwnedQxObject(btnPassword, "PasswordButton");
        this.btnPassword = btnPassword;

        let btnHelp =
            new qx.ui.form.Button(this.tr("Help"), "agrammon/help-about.png");
        this.addOwnedQxObject(btnHelp, "HelpButton");

        let btnCancel =
            new qx.ui.form.Button(this.tr("Cancel"), "icon/16/actions/dialog-cancel.png");
        this.addOwnedQxObject(btnCancel, "CancelButton");

        btnCancel.addListener("execute", function(e) {
            this.__user.clearValue();
            this.__password.clearValue();
            if (sudo) {
                that.close();
            }
        }, this);

        // FIX ME: deal with sub locales
        let locale = qx.locale.Manager.getInstance().getLocale();
        locale = locale.replace(/_.+/,'');
        let help = this.__help = new agrammon.ui.dialog.DocWindow(
            this.tr("Help"),
            this.__baseUrl + 'doc/login.' + locale + '.html',
            this.getQxObjectId()
        );
        this.addOwnedQxObject(help, "HelpWindow");
        btnHelp.addListener("execute", function(e) {
            this.__user.clearValue();
            this.__password.clearValue();
            help.open();
        }, this);

        btnOK.addListener("execute", function(e) {
            let username = this.__user.getValue();
            let password = this.__password.getValue();

            this.__password.clearValue();
            qx.event.message.Bus.dispatchByName(
                'agrammon.main.login',
                {
                    username : username, password : password,
                    sudo : sudo, retry : retry
                }
            );
            this.close();
        }, this);

        btnNew.addListener("execute", function(e) {
            let newDialog = new agrammon.module.user.SelfService(this.tr("Create new account"), 'userCreate');
            newDialog.open();
            this.__password.clearValue();
            this.close();
        } ,this);

        btnPassword.addListener("execute", function(e) {
            let newDialog = new agrammon.module.user.SelfService(this.tr("Reset password"), 'reset');
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

        let idx = 1;
        user.setTabIndex(idx++);
        password.setTabIndex(idx++);
        btnCancel.setTabIndex(idx++);
        btnOK.setTabIndex(idx++);
        btnHelp.setTabIndex(idx++);
        btnPassword.setTabIndex(idx++);
        btnNew.setTabIndex(idx++);

        this.addListener('appear', function() {
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

        // this.addListener('disappear', () => this.destroy(), this);

    }, // construct

    members :
    {
        __baseUrl  : null,
        __user     : null,
        __help     : null,
        __password : null,

        __changeLanguage: function() {
            // FIX ME: deal with sub locales
            let locale = qx.locale.Manager.getInstance().getLocale();
            locale = locale.replace(/_.+/,'');
            this.debug('Login: locale='+locale);
            this.__help.setSource(this.__baseUrl + 'doc/login.' + locale + '.html');
        }

    }
});

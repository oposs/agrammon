/* ************************************************************************

************************************************************************ */

/*
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
 */

qx.Class.define('agrammon.module.user.SelfService', {
    extend: qx.ui.window.Window,

     /**
       * TODOC
       *
       * @return {var} TODOC
       * @lint ignoreDeprecated(alert)
       */
     construct: function (title, action) {
        this.base(arguments);
        let that = this;
        this.set({ layout:new qx.ui.layout.VBox(10),
                   width: 200, modal: true,
                   showClose: false, showMinimize: false, showMaximize: false,
                   caption: title
                 });

        this.__rpc  = agrammon.io.remote.Rpc.getInstance();
        let rpcAction;

        let passwordReset = (action == 'reset');
        // create the form manager
        let manager = new qx.ui.form.validation.Manager();
        // create a validator function
        let passwordLengthValidator = function(value, item) {
            let valid = value != null && value.length >= 8;
            if (!valid) {
                item.setInvalidMessage(that.tr("Password must have at least 8 characters."));
            }
            return valid;
        };

        let pbox = new qx.ui.container.Composite(new qx.ui.layout.VBox());
        this.pbox = pbox;
        this.add(pbox);

        if (passwordReset) {
            this.user = new agrammon.ui.form.VarInput(
                this.tr("eMail (your username)"),
                '', '', ''
            );
        }
        else {
            this.user = new agrammon.ui.form.VarInput(
                this.tr("eMail (will be your username)"),
                '', '', ''
            );
        }
        pbox.add(this.user);
        this.user.setPadding(5);

        this.password1 = new agrammon.ui.form.VarPassword(
                this.tr("Password (minimum 8 characters)"),
                '', '', ''
        );
        pbox.add(this.password1);
        this.password1.setPadding(5);

        this.password2 = new agrammon.ui.form.VarPassword(
            this.tr("Repeat Password"),
            '', '', ''
        );
        pbox.add(this.password2);
        this.password2.setPadding(5);

        let msg;

        if (!passwordReset) {
            let firstName = new agrammon.ui.form.VarInput(
                this.tr("First name (optional)"),
                '', '', ''
            );
            this.firstName = firstName;
            firstName.setPadding(5);
            pbox.add(firstName);

            let lastName = new agrammon.ui.form.VarInput(
                this.tr("Last name (optional)"),
                '', '', ''
            );
            this.lastName = lastName;
            pbox.add(lastName);
            lastName.setPadding(5);

            let organisation = new agrammon.ui.form.VarInput(
                this.tr("Organisation (optional)"),
                '', '', ''
            );
            this.organisation = organisation;
            pbox.add(organisation);
            organisation.setPadding(5);

            this.msg0 = this.tr("Create Account");
            // rpcAction = 'self_create_account';
            rpcAction = 'create_account';
            msg = this.tr("An activation link will be sent to you by eMail.");
        }
        else {
            this.setCaption(this.tr("Reset password"));
            this.msg0 = this.tr("Reset Password");
            // rpcAction = 'self_reset_password';
            rpcAction = 'reset_password';
            msg = this.tr("A confirmation link will be sent to you by eMail.");
        }
        this.setCaption(this.msg0);


        // add the email with a predefined email validator
        manager.add(this.user.getInputField(), qx.util.Validate.email());
        // add the password fields with the notEmpty validator
        manager.add(this.password1.getInputField(), passwordLengthValidator);
        manager.add(this.password2.getInputField(), passwordLengthValidator);

        // add a validator to the manager itself (passwords must be equal)
        manager.setValidator(function(items) {
            let valid = that.password1.getValue() == that.password2.getValue();
            if (!valid) {
                let message = that.tr("Passwords must be equal.");
                that.password2.getInputField().setInvalidMessage(message);
                that.password2.getInputField().setValid(false);
            }
            return valid;
        });

        // add a listener to the form manager for the validation complete
        manager.addListener("complete", function() {
            if (! manager.getValid()) {
                alert(manager.getInvalidMessages().join("\n"));
            }
        }, this);


        this.msg1 = new qx.ui.basic.Label(
            '<font color=red><b>'+ msg + '</b></font>'
        ).set({rich: true});
        this.msg1.setPaddingLeft(5);
        this.msg1.setPaddingRight(5);
        this.msg1.setPaddingTop(5);

        pbox.add(this.msg1);

        let bbox = new qx.ui.container.Composite(new qx.ui.layout.HBox(10));
        // bbox.set({height: 'auto', width:'auto', padding: 5});
        bbox.setPaddingLeft(5);
        bbox.setPaddingRight(5);
        this.add(bbox);

        let btnOK = new qx.ui.form.Button(this.msg0, "icon/16/actions/dialog-ok.png");
        this.btnOK = btnOK;
        bbox.add(btnOK);

        this.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                btnOK.execute();
            }
        });

        let btnCancel = new qx.ui.form.Button(this.tr("Cancel"), "icon/16/actions/dialog-cancel.png");
        bbox.add(btnCancel);
        btnCancel.addListener("execute", function(e) {
            this.close();
            qx.event.message.Bus.dispatchByName('agrammon.main.logout');
        }, this);


        let accountHandler = function(data,exc,id) {
            console.log('accountHandler():', data);
            if (exc == null) {
                if (data.key && data.username) {
                    agrammon.ui.dialog.MsgBox.getInstance().info(
                        that.tr("Account creation successful"),
                        that.tr("Account activation key sent to %1", data.username)
                    );
                }
	        }
            else {
                agrammon.ui.dialog.MsgBox.getInstance().exc(exc);
            }
            qx.event.message.Bus.dispatchByName('agrammon.main.logout');
            that.close();
        };


        let createAccount = function(e) {
            this.debug('createAccount(): this='+this);
            if (! manager.validate()) {
                that.debug('createAccount(): Form is invalid');
                return;
            }
            let username = this.user.getValue();
            let password = this.password1.getValue();
            let firstName = this.firstName.getValue();
            let lastName  = this.lastName.getValue();
            let org       = this.organisation.getValue();
            let locale    = qx.locale.Manager.getInstance().getLocale().replace(/_.+/,'');

            this.__rpc.callAsync(
                accountHandler,
                rpcAction,
                {
                    email:     username,
                    password:  password,
                    firstname: firstName,
                    lastname:  lastName,
                    org:       org,
                    language:  locale
                }
            );
        };

        let resetPassword = function(e) {
            if (! manager.validate()) {
                that.debug('resetPassword(): Form is invalid');
                return;
            }
            let username  = this.user.getValue();
            let password  = this.password1.getValue();

            this.__rpc.callAsync(
                accountHandler,
                rpcAction,
                {
                    email:    username,
                    password: password,
                }
            );
        };


        if (passwordReset) {
             btnOK.addListener("execute", resetPassword, this);
        }
        else {
             btnOK.addListener("execute", createAccount, this);
        }

        this.center();
        return this;
    }, // construct

    members :
    {
        __rpc:        null,
        user:         null,
        password1:    null,
        password2:    null,
        firstName:    null,
        lastName:     null,
        organisation: null
    }
});

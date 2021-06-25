/* ************************************************************************

************************************************************************ */

/*
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
 */

qx.Class.define('agrammon.module.user.Account', {
    extend: qx.ui.window.Window,

     /**
       * TODOC
       *
       * @return {var} TODOC
       * @lint ignoreDeprecated(alert)
       */
     construct: function (title, username, action) {
        this.base(arguments);
        var that = this;
        this.set({ layout:new qx.ui.layout.VBox(10),
                   width: 200, modal: true,
                   showClose: false, showMinimize: false, showMaximize: false,
                   caption: title
                 });

        this.__rpc  = agrammon.io.remote.Rpc.getInstance();

        var passwordReset = (action == 'reset');
        var adminReset    = (action == 'adminReset');
        var adminCreate   = (action == 'adminCreate');

        // create the form manager
        var manager = new qx.ui.form.validation.Manager();
        // create a validator function
        var passwordLengthValidator = function(value, item) {
            var valid = value != null && value.length >= 6;
            if (!valid) {
                item.setInvalidMessage(that.tr("Password must have at least 6 characters."));
            }
            return valid;
        };

        var pbox = new qx.ui.container.Composite(new qx.ui.layout.VBox());
        this.pbox = pbox;
        this.add(pbox);
        // FIX ME: set username from function parameter
        if (passwordReset) {
            this.user = new agrammon.ui.form.VarInput(this.tr("eMail (your username)"),
                                            '', '', '');
        }
        else if (adminReset) {
            this.user = new agrammon.ui.form.VarInput(this.tr("eMail (username) for reset"),
                                            '', '', '');
        }
        else {
            this.user =
                new agrammon.ui.form.VarInput(this.tr("eMail (will be your username)"),
                                         '', '', '');
        }
        pbox.add(this.user);
        this.user.setPadding(5);

        this.password1 =
            new agrammon.ui.form.VarPassword(this.tr("Password (minimum 6 characters)"),
                                        '', '', '');
        pbox.add(this.password1);
        this.password1.setPadding(5);

        this.password2 = new agrammon.ui.form.VarPassword(this.tr("Repeat Password"),
                                             '', '', '');
        pbox.add(this.password2);
        this.password2.setPadding(5);

        if (!passwordReset && !adminReset) {
            var firstName =
                new agrammon.ui.form.VarInput(this.tr("First name (optional)"),
                                         '', '', '');
            this.firstName = firstName;
            firstName.setPadding(5);
            pbox.add(firstName);


            var lastName =
                new agrammon.ui.form.VarInput(this.tr("Last name (optional)"),
                                         '', '', '');
            this.lastName = lastName;
            pbox.add(lastName);
            lastName.setPadding(5);

            var organisation =
                new agrammon.ui.form.VarInput(this.tr("Organisation (optional)"),
                                         '', '', '');
            this.organisation = organisation;
            pbox.add(organisation);
            organisation.setPadding(5);

            this.msg0 = this.tr("Create Account");
        }
        else {
            this.msg0 = this.tr("Reset Password");
        }

        // add the email with a predefined email validator
        manager.add(this.user.getInputField(), qx.util.Validate.email());
        // add the password fields with the notEmpty validator
        manager.add(this.password1.getInputField(), passwordLengthValidator);
        manager.add(this.password2.getInputField(), passwordLengthValidator);

        // add a validator to the manager itself (passwords must be equal)
        manager.setValidator(function(items) {
            var valid = that.password1.getValue() == that.password2.getValue();
            if (!valid) {
                var message = that.tr("Passwords must be equal.");
                that.password1.getInputField().setInvalidMessage(message);
                that.password2.getInputField().setInvalidMessage(message);
                that.password1.getInputField().setValid(false);
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


        if (!adminCreate && !adminReset) {
	    var msg = this.tr("An activation key will be sent to you by eMail after pressing the button");
            this.msg1 =
                new qx.ui.basic.Label('<font color=red><b>'+ msg + ' ' + this.msg0 + '.</b></font>').set({rich: true});
            this.msg1.setPaddingLeft(5);
            this.msg1.setPaddingRight(5);
            this.msg1.setPaddingTop(5);

            pbox.add(this.msg1);
        }

        var key =
            new agrammon.ui.form.VarInput(this.tr("Key (sent by eMail)"),
                                     '', '', '');
        this.key = key;
        key.setPadding(5);

        var bbox = new qx.ui.container.Composite(new qx.ui.layout.HBox(10));
        // bbox.set({height: 'auto', width:'auto', padding: 5});
        bbox.setPaddingLeft(5);
        bbox.setPaddingRight(5);
        this.add(bbox);

        var btnOK = new qx.ui.form.Button(this.msg0,
                                          "icon/16/actions/dialog-ok.png");
        this.btnOK = btnOK;

        this.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                btnOK.execute();
            }
        });

        var btnCancel =
            new qx.ui.form.Button(this.tr("Cancel"),
                                  "icon/16/actions/dialog-cancel.png");
        btnCancel.addListener("execute", function(e) {
            this.close();
            qx.event.message.Bus.dispatchByName('agrammon.main.logout');
        }, this);

        var createAccountHandler = function(data,exc,id) {
            console.log('createAccountHandler(): data=', data)
            if (exc == null) {
                that.debug('createAccountHandler(): '+data);
                if (adminCreate) {
                    that.close();
                }
            }
            else {
                alert(exc);
                that.close();
            }
        };

        var activateAccountHandler = function(data,exc,id) {
            that.debug('activateAccountHandler()');
            if (exc == null) {
                if (!adminReset) {
                    that.debug('activateAccountHandler: '+data);
                    if (!passwordReset) {
                        that.setCaption(that.tr("Login with new account"));
                        that.msg1.setValue(that.tr("Account created."));
                    }
                    else {
                        that.setCaption(that.tr("Login with new password"));
                        that.password2.exclude();
                        that.msg1.setValue(that.tr("Password reset."));
                    }
                    that.pbox._addAfter(that.msg1, that.password1);
                    that.btnOK.setLabel(that.tr("Login"));
                    that.btnOK.addListener("execute", that.login, that);
                    that.user.setEnabled(true);
                    that.password1.setEnabled(true);
                }
                else {
                     that.close();
                }
            }
            else {
                alert(exc);
                that.close();
                qx.event.message.Bus.dispatchByName('agrammon.main.logout');
            }
        };

        var createAccount = function(e) {
            this.debug('createAccount(): this='+this);
            if (! manager.validate()) {
                that.debug('createAccount(): Form is invalid');
                return;
            }
            var username    = this.user.getValue();
            var password    = this.password1.getValue();

            if (passwordReset || adminReset) {
                this.setCaption(this.tr("Reset password"));
            }
            else {
                this.setCaption(this.tr("Activate new account"));
            }
            this.user.setLabel('Username' );
            this.user.setEnabled(false);
            this.password1.setEnabled(false);
            this.password2.setEnabled(false);

            if (passwordReset && ! adminReset) {
                this.location = this.password2;
                this.action = this.tr("Enter key below to re-activate your account");
            }
            else if (!adminCreate) {
                this.location = this.organisation;
                this.action = this.tr("Enter key below to activate your account");
            }
            // reverse order!
            if (!adminCreate && !adminReset) {
                this.pbox._addAfter(this.key, this.location);
                this.msg1.setValue('<font color=red><b>'
                                 + this.action + '</b></font>');
                this.pbox._addAfter(this.msg1, this.location);
            }

            var action;
            if (adminCreate) {
                 action = 'create_account';
            }
            else {
                 action = 'get_account_key';
            }
            console.log('rpc call '+action);
            var firstName, lastName, org;
            // not for self password reset
            if (this.firstName) {
                firstName = this.firstName.getValue();
                lastName  = this.lastName.getValue();
                org       = this.organisation.getValue();
            }
            this.__rpc.callAsync(
                createAccountHandler,
                action,
                {
                    email:     username,
                    password:  password,
                    firstname: firstName,
                    lastname:  lastName,
                    org:       org
                }
            );
            if (!passwordReset) {
                this.firstName.exclude();
                this.lastName.exclude();
                this.organisation.exclude();
                this.password2.exclude();
            }
            if (passwordReset || adminReset) {
                this.btnOK.setLabel(this.tr("Reset password"));
            }
            else if (!adminCreate) {
                this.btnOK.setLabel(this.tr("Activate Account"));
            }
            this.btnOK.removeListener("execute", this.createAccount, this);
            if (!adminCreate) {
               this.btnOK.addListener("execute", this.activateAccount, this);
            }
        };
        this.createAccount = createAccount;

        var activateAccount = function(e) {
            var username    = this.user.getValue();
            var password    = this.password1.getValue();
            var key         = this.key.getValue();

            if (passwordReset || adminReset) {
                this.__rpc.callAsync(
                    activateAccountHandler,
                    'reset_password',
                    {
                        email:     username,
                        password:  password,
                        key:       key
                    }
                );
            }
            else {
                var firstName   = this.firstName.getValue();
                var lastName    = this.lastName.getValue();
                var org         = this.organisation.getValue();
                var locale      = qx.locale.Manager.getInstance().getLocale().replace(/_.+/,'');
                this.__rpc.callAsync(
                    activateAccountHandler,
                    'create_account',
                    {
                        email:     username,
                        password:  password,
                        key:       key,
                        firstname: firstName,
                        lastname:  lastName,
                        org:       org,
                        language:  locale
                    }
                );
            }
            this.key.destroy();

            this.btnOK.removeListener("execute",
                                      this.activateAccount, this);
        };
        this.activateAccount = activateAccount;

        var login = function(e) {
            var username    = this.user.getValue();
            var password    = this.password1.getValue().toLowerCase();
            qx.event.message.Bus.dispatchByName(
                'agrammon.main.login',
                { username : username, password : password }
            );
            this.close();
        };
        this.login = login;

        if (!adminReset) {
             btnOK.addListener("execute", createAccount, this);
        }
        else {
             btnOK.addListener("execute", activateAccount, this);
        }

//        bbox.add(new qx.ui.core.Spacer(5));
        bbox.add(btnCancel);
        bbox.add(btnOK);
//        bbox.add(new qx.ui.core.Spacer(5));

        this.center();
//        this.open();
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

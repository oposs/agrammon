/* ************************************************************************

************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/utilities-text-editor.png)
 */

qx.Class.define('agrammon.ui.menu.AdminMenu', {
    extend: qx.ui.menu.Menu,

    construct: function () {
        this.base(arguments);

        var accountCommand = new qx.ui.command.Command();
        accountCommand.addListener("execute", this.__createAccount, this);
        this.add(new qx.ui.menu.Button(this.tr("Create account"), null, accountCommand));

        var resetCommand = new qx.ui.command.Command();
        resetCommand.addListener("execute", this.__resetPassword, this);
        this.add(new qx.ui.menu.Button(this.tr("Reset account password"), null, resetCommand));

        var sudoCommand = new qx.ui.command.Command();
        sudoCommand.addListener("execute", this.__sudo, this);
        var sudoButton = new qx.ui.menu.Button(this.tr("Change identity"), null, sudoCommand);
        this.__sudoButton = sudoButton;
        this.enableAdmin(false);
        this.add(sudoButton);

    }, // construct

    members :
    {
        __sudoButton: null,

        enableAdmin: function(enable) {
            this.__sudoButton.setEnabled(enable);
        },

        __createAccount: function() {
             var newDialog = new agrammon.module.user.Account(this.tr("Create account"), null, 'adminCreate');
            newDialog.open();
        },

        __resetPassword: function() {
            var newDialog =
                new agrammon.module.user.Account(this.tr("Reset password"), null, 'adminReset');
            newDialog.open();
        },

        __sudo: function() {
            var sudo = true;
            var loginDialog = new agrammon.module.user.Login(this.tr("Change to user account"), sudo);
            loginDialog.open();
        }

    }
});

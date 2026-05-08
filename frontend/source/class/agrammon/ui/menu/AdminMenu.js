/* ************************************************************************

************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/insert-text.png)
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

        var uploadAccountsPopup = this.__createAccountUploader();
        var uploadAccountsCommand = new qx.ui.command.Command();
        uploadAccountsCommand.addListener("execute", function() {
            uploadAccountsPopup.open();
        }, this);
        this.add(new qx.ui.menu.Button(this.tr("Upload accounts"), null, uploadAccountsCommand));

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
        },

        __createAccountUploader: function() {
            var popup = new qx.ui.window.Window(this.tr('Upload accounts')).set({
                layout: new qx.ui.layout.VBox(10),
                centerOnAppear: true,
                modal: true,
                width: 400
            });

            var infoLabel = new qx.ui.basic.Label(
                this.tr('Upload a CSV file with user account data.')
            );
            popup.add(infoLabel);

            var uploadBtn = new com.zenesis.qx.upload.UploadButton(this.tr("Select CSV file")).set({
                allowGrowX: false,
                alignX: 'left',
                alignY: 'middle',
                enabled: true,
                allowGrowY: false,
                icon: "icon/16/actions/insert-text.png"
            });

            var baseUrl = agrammon.io.remote.Rpc.getInstance().getBaseUrl();
            console.log("Base URL: " + baseUrl);
            var uploadUrl = "/upload_accounts";
            if (baseUrl != null) {
                uploadUrl = baseUrl + uploadUrl;
            }
            console.log("Upload URL: " + uploadUrl);
            var uploader = new com.zenesis.qx.upload.UploadMgr(uploadBtn, uploadUrl);
            var cancelBtn = new qx.ui.form.Button(this.tr('Cancel'));
            var okBtn = new qx.ui.form.Button(this.tr('OK'));

            cancelBtn.addListener('execute', function() {
                popup.close();
            }, this);

            okBtn.addListener('execute', function() {
                popup.close();
            }, this);

            var btnRow = new qx.ui.container.Composite(new qx.ui.layout.HBox(10), 'right');
            popup.add(btnRow);
            btnRow.add(uploadBtn);
            btnRow.add(new qx.ui.core.Spacer(1), {flex: 1});
            btnRow.add(cancelBtn);

            var progressRow = new qx.ui.container.Composite(new qx.ui.layout.HBox(10), 'right');
            popup.add(progressRow);
            var uploadProgress = new qx.ui.basic.Label();
            progressRow.add(uploadProgress);
            progressRow.add(new qx.ui.core.Spacer(1), {flex: 1});
            progressRow.add(okBtn);

            var uploadResponse = new qx.ui.basic.Label();
            popup.add(uploadResponse);

            popup.addListener('appear', function() {
                cancelBtn.setEnabled(true);
                okBtn.setEnabled(false);
                uploadBtn.setEnabled(true);
                uploadProgress.resetValue();
                uploadResponse.resetValue();
            }, this);

            var that = this;
            uploader.addListener("addFile", function(evt) {
                var file = evt.getData();
                cancelBtn.setEnabled(true);
                uploadBtn.setEnabled(false);

                var cancelListenerId = cancelBtn.addListener('execute', function(e) {
                    if (file.getState() == "uploading" || file.getState() == "not-started") {
                        uploader.cancel(file);
                    }
                }, this);

                var responseListenerId = file.addListener("changeResponse", function(e) {
                    var response = qx.lang.Json.parse(e.getData());
                    if (response.error) {
                        qx.event.message.Bus.dispatchByName('error', [that.tr("Error"), response.error]);
                        popup.close();
                        return;
                    }
                    if (response && response.created !== undefined) {
                        var createdCount = response.created.length;
                        var errorCount = response.errors ? response.errors.length : 0;
                        var msg = that.tr('Created %1 accounts', createdCount);
                        if (errorCount > 0) {
                            msg += ', ' + that.tr('%1 errors', errorCount);
                            qx.event.message.Bus.dispatchByName('error', [that.tr("Warning"), response.errors.join('\n'), 'warning']);
                        }
                        uploadResponse.setValue(msg);
                    }
                    else {
                        uploadResponse.setValue(that.tr('No valid accounts found in uploaded file.'));
                    }
                    if (progressListenerId) {
                        file.removeListenerById(progressListenerId);
                    }
                    if (stateListenerId) {
                        file.removeListenerById(stateListenerId);
                    }
                    if (cancelListenerId) {
                        cancelBtn.removeListenerById(cancelListenerId);
                    }
                    okBtn.setEnabled(true);
                    uploadBtn.setEnabled(true);
                    cancelBtn.setEnabled(false);
                }, this);

                var stateListenerId = file.addListener("changeState", function(evt) {
                    var state = evt.getData();
                    if (state == "uploading") {
                        that.debug(file.getFilename() + " (Uploading...)");
                    }
                    else if (state == "uploaded" || state == "cancelled") {
                        if (state == "uploaded") {
                            that.debug(file.getFilename() + " (Complete)");
                            uploadProgress.resetValue();
                        }
                        if (state == "cancelled") {
                            that.debug(file.getFilename() + " (Cancelled)");
                        }
                    }
                }, this);

                var progressListenerId = file.addListener("changeProgress", function(evt) {
                    uploadProgress.setValue(
                        "Upload " + file.getFilename() + ": "
                        + evt.getData() + " / " + file.getSize() + " - "
                        + Math.round(evt.getData() / file.getSize() * 100) + "%"
                    );
                }, this);

            }, this);

            return popup;
        }

    }
});

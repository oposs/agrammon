/* ************************************************************************

************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-close.png)
 * @asset(qx/icon/${qx.icontheme}/16/status/dialog-information.png)
 */

qx.Class.define('agrammon.ui.dialog.DocWindow', {
    extend: qx.ui.window.Window,

    construct: function (title, url, qxParentId) {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox());

        this.set({
            width:600, height:400,
            modal: true,
            showClose: true, showMinimize: false, showMaximize: false,
		    caption: title,
		    centerOnAppear : true
         });
        this.getChildControl("pane").setBackgroundColor("white");
        var vBox = new qx.ui.container.Composite(new qx.ui.layout.VBox(20));

        var docuText = new qx.ui.embed.Iframe();
        this.docuText = docuText;
        docuText.set({
            width: 600, height: 400, padding: 10,
            source: url
        });

        var btnCancel =
            new qx.ui.form.Button(this.tr("Close"),
                                  "icon/16/actions/dialog-close.png");
        this.addListenerOnce('appear', () => {
            this.addOwnedQxObject(btnCancel, "CloseButton");
            this.debug('docWindowID=', qx.core.Id.getAbsoluteIdOf(this));
            this.debug('btnCancelID=', qx.core.Id.getAbsoluteIdOf(btnCancel));
        }, this);

        this.btnCancel = btnCancel;
        btnCancel.setMaxWidth(120);

        btnCancel.addListener("execute", function(e) {
            this.close();
        }, this);

        vBox.add(docuText);
        vBox.add(btnCancel);

        this.setIcon("icon/16/status/dialog-information.png");

        this.add(vBox);

        return this;
    },

    members :
    {
        setSource: function(src) {
            this.docuText.setSource(src);
        }

    }
});

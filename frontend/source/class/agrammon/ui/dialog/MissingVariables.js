/* ************************************************************************
   Copyright: 2026, OETIKER+PARTNER AG
   License: GPL
************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/32/status/dialog-warning.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/edit-delete.png)
 */

/**
 * Dialog shown when loading a dataset that contains variables which no
 * longer fit the current model. This includes variables whose name is no
 * longer in the model, and enum-style variables whose stored value is no
 * longer a valid option.
 *
 * Usage:
 *   new agrammon.ui.dialog.MissingVariables(
 *       variables,         // Array of varName strings
 *       function(deleted)  // callback: true = delete, false = keep
 *   );
 */
qx.Class.define('agrammon.ui.dialog.MissingVariables', {
    extend: qx.ui.window.Window,

    construct: function(variables, execFunc) {
        this.base(arguments);
        qx.core.Id.getInstance().register(this, "MissingVariables");
        this.setQxObjectId("MissingVariables");

        var isAdmin = agrammon.Info.getInstance().isAdmin();

        this.set({
            modal:          true,
            showClose:      false,
            showMinimize:   false,
            showMaximize:   false,
            resizable:      true,
            contentPadding: 15,
            width:          500,
            height:         isAdmin ? 400 : 220,
            zIndex:         10001
        });
        this.setCaption(this.tr("Obsolete variables in dataset"));

        this.setLayout(new qx.ui.layout.VBox(10));

        var header = new qx.ui.basic.Atom(
            this.tr("This dataset contains %1 variable(s) that no longer match the current model (unknown variables or invalid enum values). They will not be used in any calculation. Do you want to delete them from the dataset?",
                    variables.length),
            "icon/32/status/dialog-warning.png"
        );
        header.setRich(true);
        header.setGap(10);
        this.add(header);

        // The detailed variable list is only useful to admins (who can act
        // on it). Hide it for ordinary users; the count and action are
        // sufficient for them. A flex spacer is added in either case so the
        // button row sits at the bottom of the window.
        if (isAdmin) {
            var listLabel = new qx.ui.basic.Label('<pre>' +
                qx.bom.String.escape(variables.join('\n')) + '</pre>');
            listLabel.setRich(true);
            listLabel.setSelectable(true);

            var scroll = new qx.ui.container.Scroll();
            scroll.add(listLabel);
            scroll.setBackgroundColor('white');
            this.add(scroll, { flex: 1 });
        }
        else {
            this.add(new qx.ui.core.Spacer(), { flex: 1 });
        }

        // buttons
        var btnKeep = new qx.ui.form.Button(
            this.tr("Keep"), "icon/16/actions/dialog-cancel.png");
        var btnDelete = new qx.ui.form.Button(
            this.tr("Delete from dataset"), "icon/16/actions/edit-delete.png");

        var finish = function(deleted) {
            this.close();
            if (execFunc) {
                execFunc(deleted);
            }
        };

        btnKeep.addListener("execute", function() { finish.call(this, false); }, this);
        btnDelete.addListener("execute", function() { finish.call(this, true);  }, this);

        this.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Escape') {
                btnKeep.execute();
            }
        });

        var btnRow = new qx.ui.container.Composite(
            new qx.ui.layout.HBox(10, 'right'));
        btnRow.add(btnKeep);
        btnRow.add(btnDelete);
        this.add(btnRow);

        this.addListener('disappear', function() {
            this.destroy();
        }, this);

        this.addListenerOnce("appear", function() {
            this.addOwnedQxObject(btnKeep,    "KeepButton");
            this.addOwnedQxObject(btnDelete,  "DeleteButton");
            btnKeep.focus();
        }, this);

        this.addListenerOnce("resize", this.center, this);
        this.open();
    },

    members: {
    }
});

/* ************************************************************************

************************************************************************ */

qx.Class.define('agrammon.module.output.OutputSelector', {
    extend: qx.ui.form.SelectBox,

    construct: function (changeSelectionHandler) {
        this.base(arguments);
        this.__changeSelectionHandler = changeSelectionHandler;

        this.set({width: 500, enabled: false});

        qx.locale.Manager.getInstance().addListener("changeLocale", this.__changeLanguage, this);

        this.setWidth(500);
        this.__itemSelect = new qx.ui.form.ListItem(this.tr("*** Select ***"), null);
        var enabled = this.isEnabled();
        this.setEnabled(true);
        this.add(this.__itemSelect);
        this.setEnabled(enabled);
        this.__reportData = new Array;

        this.addListener("changeSelection", this.__changeSelectionHandler, this);
    }, // construct

    members :
    {
        __itemSelect: null,
        __changeSelectionHandler: null,
        __reportData: null,

        __changeLanguage: function() {
            this.update(this.__reportData);
        },

        clearSelection: function() {
            var enabled = this.isEnabled();
            this.setEnabled(true);
            this.setSelection([this.__itemSelect]);
            this.setEnabled(enabled);
        },

        update: function(reportData) {
            this.__reportData = reportData; // save for changeLanguage

            this.removeListener("changeSelection", this.__changeSelectionHandler, this);

            var item, enabled;
            // save enable state and setEnabled(true) for adding of items
            enabled = this.isEnabled();
            this.setEnabled(true);

            this.removeAll();
            this.add(this.__itemSelect);

            var label, data, r, reports = 0,
                locale = qx.locale.Manager.getInstance().getLocale();
            locale = locale.replace(/_.+/,'');

            reports = reportData.length;
            for (let report of reportData) {
                if (report.resultView) continue;

                if (report.selector[locale] != null) {
                    label = report.selector[locale];
                }
                else {
                    label = report.selector.en;
                }

                data = report.name;
                item = new qx.ui.form.ListItem(label, null);
                item.setModel(data);
                this.add(item);
            }

            this.setSelection([this.__itemSelect]);
            this.addListener("changeSelection", this.__changeSelectionHandler, this);

            // return to previous enable state
            this.setEnabled(enabled);
        }

    }
});



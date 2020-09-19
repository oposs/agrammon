/* ************************************************************************

************************************************************************ */

qx.Class.define('agrammon.ui.form.LabelValue', {
    extend: qx.ui.container.Composite,

    construct: function (label, value) {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.HBox());

        // qx.locale.Manager.getInstance().addListener("changeLocale",
        //                                                 this._update, this);

        label = new qx.ui.basic.Label(label);
        this.__value = new qx.ui.basic.Label(value).set({font: 'bold'});

        this.add(label);
        this.add(this.__value);

        return this;
    }, // construct

    members :
    {
        __value: null,

        setValue: function(value) {
            this.__value.setValue(value);
            return;
        },

        getValue: function() {
            return this.__value.getValue();
        }
    }
});

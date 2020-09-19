/* ************************************************************************

************************************************************************ */

qx.Class.define('agrammon.ui.form.VarPassword', {
    extend: qx.ui.container.Composite,

    construct: function (tlabel, defaultValue, data_type, tooltip, placeholder) {
        this.base(arguments, null, tlabel, defaultValue);

        this.setLayout(new qx.ui.layout.VBox());
        // qx.locale.Manager.getInstance().addEventListener("changeLocale",
        //                                                 this._update, this);

        var reg_float =
            '^((-?\\d\\d*\\.\\d*)|(-?\\d\\d*)|(-?\\.\\d\\d*))([eE][-+]?\\d+)?$';
        var reg_integer = '^\\d+$';

        var validator;

        switch (data_type) {
        case 'float':
            validator = reg_float;
            break;
        case 'integer':
            validator = reg_integer;
            break;
        default:
            validator = '.*';
            break;
        }

        // this.set({verticalChildrenAlign: 'middle', width: 'auto', height: 'auto',
        //             spacing: 5});

        this.__label = new qx.ui.basic.Label(tlabel);
        this.add(this.__label);
        this.__var = new qx.ui.form.PasswordField();
        this.__label.setBuddy(this.__var);
        if (placeholder) {
            this.__var.setPlaceholder(placeholder);
        }
        // this.__var.set({
        //         height: 'auto',
        //         width: 150,
        //         value  : defaultValue
        //             });
        this.add(this.__var);

        // if (validator != undefined) {
        //     var var_validator =
        //         qx.ui.form.TextField.createRegExpValidator(new
        //                                                    RegExp(validator));
        //     var event_check = function(e){
        //         if (! this.isValid() && this.getValue() != null
        //                              && this.getValue() != ''){
        //             this.setBackgroundColor('#ffc4c4');
        //         }
        //         else {

        //             this.setBackgroundColor('#ffffff');
        //         }
        //     };
        //     this.__var.setValidator(var_validator);
        // }

//         if (tooltip != undefined) {
//             this._tooltip = new qx.legacy.ui.popup.ToolTip(tooltip);
//             this.__var.setToolTip(this._tooltip);
//             this.setToolTip(this._tooltip);
//             this._tooltip.setHideInterval(10000);
//         }

        return this;

    },
    members :
    {
        __var: null,
        __label: null,

       /**
         * TODOC
         *
         * @return {var} TODOC
         * @lint ignoreDeprecated(alert)
         */
        isValid: function(){
            alert(this.__var.isValid());
            return  this.__var.isValid();
        },
        getValue: function(){
            return this.__var.getValue();
        },
        setValue: function(val){
            this.__var.setValue(val);
        },
        getInputField: function(){
            return this.__var;
        },
        clearValue: function(e){
	    this.__var.setValue('');
        }
    }
});

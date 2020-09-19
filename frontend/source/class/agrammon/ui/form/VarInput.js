/* ************************************************************************

************************************************************************ */

qx.Class.define('agrammon.ui.form.VarInput', {
    extend: qx.ui.container.Composite,

    construct: function (tlabel, defaultValue, data_type,
                         tooltip, placeholder, hBox) {
        this.base(arguments, null, tlabel, defaultValue);
        if (hBox) {
            this.setLayout(new qx.ui.layout.HBox(5));
        }
        else {
            this.setLayout(new qx.ui.layout.VBox());
        }

        // qx.locale.Manager.getInstance().addEventListener("changeLocale",
        //                                                 this._update, this);

//         var reg_float =
//             '^((-?\\d\\d*\\.\\d*)|(-?\\d\\d*)|(-?\\.\\d\\d*))([eE][-+]?\\d+)?$';
//         var reg_integer = '^\\d+$';

//         var validator;

//         switch (data_type) {
//         case 'float':
//             validator = reg_float;
//             break;
//         case 'integer':
//             validator = reg_integer;
//             break;
//         default:
//             validator = '.*';
//             break;
//         }

        this.__var = new qx.ui.form.TextField();
        if (tlabel != '' && tlabel != null) {
            this.__label = new qx.ui.basic.Label(tlabel);
            this.add(this.__label);
            this.__label.setBuddy(this.__var);
            this.__label.setAlignY('middle');
	}
        this.add(this.__var, {flex: 1});
        if (placeholder) {
            this.__var.setPlaceholder(placeholder);
        }
        this.__var.setAlignY('middle');

        // if (validator != undefined) {
        //     var var_validator =
        //         qx.legacy.ui.form.TextField.createRegExpValidator(new
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
        //     this.__var.addListener('changeValue',event_check,this.__var);
        //     this.__var.setValidator(var_validator);
        // }

        if ((tooltip == undefined) ||
            (tooltip == null)      ||
            (tooltip == '')) {
            tooltip = 'Tooltip for ' + tlabel;
        }

//        var tt1 = new qx.ui.tooltip.ToolTip(tooltip);
//        tt1.set({ hideTimeout: 20000, showTimeout: 100});
        var tt2 = new qx.ui.tooltip.ToolTip(tooltip);
        tt2.set({ hideTimeout: 20000, showTimeout: 100});
//        this.__var.setToolTip(tt1);
        this.setToolTip(tt2);

        return;
    },

    members :
    {
        __label: null,
        __var:  null,

        /**
        * Add an event listener to the textfield
        */
        addListener: function(a0, a1, a2) {

 	        this.__var.addListener(a0, a1, a2);
        },

        /**
        * Remove an event listener from the textfield
        */
        removeListener: function(a0, a1, a2) {

 	        this.__var.removeListener(a0, a1, a2);
        },

        isValid: function(){
            return  this.__var.isValid();
        },
        getValue: function(){
            return this.__var.getValue();
        },
        setValue: function(val){
            return this.__var.setValue(val);
        },
        getLabel: function(){
            return this.__label.getContent();
        },
        getInputField: function(){
            return this.__var;
        },
        setLabel: function(label){
            return this.__label.setValue(label);
        },
        clearValue: function(e){
    	    this.__var.setValue('');
        },
        focus: function(e){
    	    this.__var.focus();
        }
    }
});

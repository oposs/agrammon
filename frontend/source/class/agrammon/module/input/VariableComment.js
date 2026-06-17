/* ************************************************************************
   Copyright: 2008, OETIKER+PARTNER AG
   License: GPL
************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/help-faq.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-close.png)
 */

/**
 */
qx.Class.define('agrammon.module.input.VariableComment', {
    extend : agrammon.ui.dialog.Comment,
    type : "singleton",

    construct : function() {
        this.base(arguments);
    },

    members : {

        __folder: null,

        // #420: the NavFolder whose instance the comment belongs to, set by
        // PropTable when the editor is opened. Used to resolve the instance-free
        // column-0 name back to the folder's current instance.
        setFolder: function(folder) {
            this.__folder = folder;
        },

        _storeComment: function(comment) {
            var variable = this._tableModel.getValue(0, this._commentRow);
            // #420: column 0 no longer carries the [instance]; resolve it back
            // to the folder's current instance so the comment is stored on the
            // right instance (and survives an instance rename).
            if (this.__folder) {
                variable = this.__folder.resolveVariable(variable) || variable;
            }
            var dataset  = this._info.getDatasetName();
            this._rpc.callAsync(qx.lang.Function.bind(
                this._storeCommentFunc,this),
                'store_input_comment',
                {
                    datasetName:    dataset,
                    comment:    comment,
                    variable:   variable
                }
            );
        },

        _setCaption: function(caption) {
           this.setCaption(this.tr("Comment on variable")
                              + ' ' + caption);
        }

    }
});

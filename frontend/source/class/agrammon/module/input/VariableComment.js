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

        _storeComment: function(comment) {
            var variable = this._tableModel.getValue(0, this._commentRow);
            var dataset  = this._info.getDatasetName();
            this.debug('_storeComment(): comment='+comment);
            this.debug('_storeComment(): dataset='+dataset);
            this.debug('_storeComment(): variable='+variable);
            this._rpc.callAsync(qx.lang.Function.bind(this._storeCommentFunc,this),
                               'store_variable_comment',
                               {
                                   dataset:    dataset,
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

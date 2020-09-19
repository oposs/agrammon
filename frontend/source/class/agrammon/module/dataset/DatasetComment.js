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
qx.Class.define('agrammon.module.dataset.DatasetComment', {
    extend : agrammon.ui.dialog.Comment,
    type : "singleton",

    construct : function() {
        this.base(arguments);
    },

    members : {

        _storeComment: function(comment) {
            var dataset = this._tableModel.getValue(0, this._commentRow);
            this._rpc.callAsync(qx.lang.Function.bind(this._storeCommentFunc,this),
                               'store_dataset_comment',
                               {
                                    dataset:      dataset,
                                    comment:      comment
                               }
            );
        },

        _setCaption: function(caption) {
           this.setCaption(this.tr("Comment on dataset")
                              + ' ' + caption);
        }

    }
});

/* ************************************************************************
   Copyright: 2008, OETIKER+PARTNER AG
   License: GPL
************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/apps/utilities-text-editor.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-close.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/edit-clear.png)
 */

/**
 */
qx.Class.define('agrammon.ui.dialog.Comment', {
    extend : qx.ui.window.Window,

    construct : function() {
        this.base(arguments);

        var that = this;
        this.set({
            modal          : true,
            showMinimize   : true,
            showMaximize   : true,
            resizable      : true,
            contentPadding : 10,
            allowGrowX: true,
            allowGrowY: true,
            icon: "icon/16/apps/utilities-text-editor.png"
        });
        this.getChildControl("pane").setBackgroundColor("white");
        this.setLayout(new qx.ui.layout.VBox(10));

        var scrollBox = new qx.ui.container.Stack();
        scrollBox.setMinWidth(500);
        scrollBox.setMinHeight(250);
        scrollBox.setAllowGrowX(true);
        scrollBox.setAllowGrowY(true);
        scrollBox.setBackgroundColor("white");


        this.__comment = new qx.ui.form.TextArea();
        this.__comment.setWrap(true);
        this.__comment.setPadding(10);
        this.__comment.setBackgroundColor("white");
        this.__comment.setAllowStretchX(true);
        this.__comment.setAllowGrowY(true);

//        scrollBox.add(this.__comment, {flex: 1});
        scrollBox.add(this.__comment);
        this.add(scrollBox, {flex: 1});

        var box = new qx.ui.container.Composite;
        box.setLayout(new qx.ui.layout.HBox(5, "right"));
        this.add(box);

//        var saveComment = function() {
//            that._saveComment(that.__comment.getValue());
//        };

        var btnSave = new qx.ui.form.Button(this.tr("Save comment"),
                                            "icon/16/actions/dialog-ok.png");
        btnSave.addListener("execute", function(e) {
            that._saveComment(that.__comment.getValue());
//            saveComment();
        }, this);

        var btnClear = new qx.ui.form.Button(this.tr("Clear"),
                                             "icon/16/actions/edit-clear.png");
        btnClear.addListener("execute", function(e) {
            this.__comment.setValue(null);
        }, this);

        var btnCancel =
            new qx.ui.form.Button(this.tr("Cancel"),
                                  "icon/16/actions/dialog-close.png");

        var buttonRow =
            new qx.ui.container.Composite(new qx.ui.layout.HBox(10, 'right'));
        buttonRow.add(btnCancel);
        buttonRow.add(btnClear);
        buttonRow.add(btnSave);
        buttonRow.setPaddingTop(20);

        btnCancel.addListener("execute", function(e) {
            that.close();
        });

        box.add(buttonRow);

        this.addListener("appear",  function(e) {
            this.center();
        }, this);

        this._info = agrammon.Info.getInstance();
        this._rpc  = agrammon.io.remote.Rpc.getInstance();
    },

    members : {
        __comment: null,
        __commentColumn: null,
        _commentRow: null,
        _tableModel: null,
        __table: null,
        _info: null,
        _rpc: null,

        init: function(table, column) {
            this.__table = table;
            this._tableModel = table.getTableModel();
            this.__commentColumn = column;
        },

        open: function(caption) {
            var data = this.__table.getSelectionModel().getSelectedRanges();
            this._commentRow = data[0]['minIndex'];
            var comment = this._tableModel.getValue(this.__commentColumn,
                                                     this._commentRow);
            // this.debug('setRow(): comment='+comment);
            // this.debug('setRow(): col/row='+this.__commentColumn+'/'+
            //            this._commentRow);
            if (comment) {
                this.__comment.setValue(comment);
            }
            else {
                this.__comment.setValue(null);
            }
            this._setCaption(caption);
            this.base(arguments);
        },

        _saveComment: function(comment) {
            this._tableModel.setValue(this.__commentColumn,this._commentRow,
                                       this.__comment.getValue());
            this._storeComment(comment);
//            this.close();
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
	  * @lint ignoreDeprecated(alert)
          */
        _storeCommentFunc: function(data, exc, id) {
            if (exc == null) {
                this.debug('_storeCommentFunc():' + data);
            }
            else {
                alert(exc);
            }
            this.close();
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
	  * @lint ignoreDeprecated(alert)
          */
        _setCaption: function() {
            alert('_setCaption should be overwritten!');
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
	  * @lint ignoreDeprecated(alert)
          */
        _storeComment: function() {
            alert('_storeComment should be overwritten!');
        }

    }
});

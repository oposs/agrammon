/* ************************************************************************

************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/document-save-as.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/document-new.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/document-send.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/insert-text.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/window-close.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/office-calendar.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/office-database.png)
 * @asset(agrammon/read-only_ts.png)
 */

qx.Class.define('agrammon.module.dataset.DatasetTable', {
    extend:  qx.ui.container.Composite,
    type:    'singleton',

     /**
       * TODOC
       *
       * @return {var} TODOC
       * @lint ignoreDeprecated(alert)
       */
    construct: function () {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox(5));
        this.set({allowShrinkY: true});
        this.__info = agrammon.Info.getInstance();
        this.__rpc  = agrammon.io.remote.Rpc.getInstance();
        var that = this;

        this.__table = this.__createTable();
        this.__toolBar = new qx.ui.toolbar.ToolBar();
        this.__table.setAllowShrinkY(true);
        var datasetFilter =
            new agrammon.ui.form.VarInput(null, null,null,
                                     this.tr("Incremental filter on dataset name"),
                                     this.tr("Filter on dataset name"), false);
        datasetFilter.addListener('input', function(e) {
              this.__searchFilter = e.getData().toLowerCase();
              this.__searchTimer.restart();
          }, this);

        this.__searchTimer = new qx.event.Timer(this.__searchTimeout);
        this.__searchTimer.addListener('interval', function(e) {
            this.__searchTimer.stop();
            this.updateView();
        }, this);

        this.add(this.__toolBar);
        this.__toolBar.setPadding(0,5,0,5);
        this.add(datasetFilter);
        datasetFilter.setMargin(10,10,0,10);
        this.__table.setMargin(0,10,0,10);
        this.add(this.__table, {flex: 1});
        this.__createToolbarButtons();

        // add handlers to buttons
        this.__btnDel.addListener("execute", function(e) {
            var data = this.__table.getSelectionModel().getSelectedRanges();
            var ranges = data.length;
            if (ranges <= 0) {
                alert('DatasetTable.__btnDel(): This should never happen, ranges='+ranges);
                return;
            }
            var dialog;
            var okFunction = qx.lang.Function.bind(function(self) {
                var dataset, i, j, ii, min, max, nDatasets;
                var datasets = new Array;
                var tableModel = this.__table.getTableModel();
                for (i=0; i<ranges; i++) {
                    min = data[i]['minIndex'];
                    max = data[i]['maxIndex'];
                    for (j=min; j<=max; j++) {
                        dataset = tableModel.getValue(0,j,1);
                        datasets.push(dataset);
                    }
                }
                nDatasets = datasets.length;
                if (nDatasets > 0) {
                    // disconnect current dataset in case it is one of
                    // the deleted ones
                    var currentDataset = this.__info.getDatasetName();
                    var deleteCurrent = false;
                    for (ii=0; ii<nDatasets; ii++) {
                        if (currentDataset == datasets[ii]) {
                            deleteCurrent = true;
                        }
                    }
                    if (deleteCurrent) {
                        qx.event.message.Bus.dispatchByName('agrammon.NavBar.clearTree');
                        var datasetHash = new Object;
                        datasetHash['name'] = '-';
                        this.__info.clearDatasetName();
                        // what is this for?
                        // can't be null message in qx 0.8
                        qx.event.message.Bus.dispatchByName('agrammon.NavBar.getInput',
                                                            datasetHash);
                    }
                    this.__rpc.callAsync( delete_datasets_func,
                                         'delete_datasets', { datasets : datasets });
                }
                self.close();
            }, this);
            dialog =
                new agrammon.ui.dialog.Confirm(this.tr("Deleting datasets from database"),
                                               this.tr("Really delete selected datasets from database?"),
                                               okFunction, this);
        }, this);

        var delete_datasets_func = function(data,exc,id) {
            if (exc == null) {
                var msg;
                var deleted = data.deleted;
                msg = (deleted == 1) ? that.tr("dataset") : that.tr("datasets");
                qx.event.message.Bus.dispatchByName('agrammon.DatasetCache.refresh', that.__info.getUserName());
                qx.event.message.Bus.dispatchByName(
                    'error',
                    [
                        that.tr("Info"),
                        deleted + ' ' + msg + ' ' + that.tr("deleted"),
                        'info'
                    ]
                );
            }
            else {
                alert(exc);
            }
        }; // delete_datasets_func()

        this.__btnSend.addListener("execute", function(e) {
            var data = this.__table.getSelectionModel().getSelectedRanges();
            var ranges = data.length;
            if (ranges <= 0) {
                alert('DatasetTable.__btnSend(): This should never happen, ranges='+ranges);
                return;
            }
            var dialog;
            var okFunction = qx.lang.Function.bind(function(self) {
                var dataset, i, j, min, max, nDatasets;
                var datasets = new Array;
                var tableModel = this.__table.getTableModel();
                for (i=0; i<ranges; i++) {
                    min = data[i]['minIndex'];
                    max = data[i]['maxIndex'];
                    for (j=min; j<=max; j++) {
                        dataset = tableModel.getValue(0,j,1);
                        datasets.push(dataset);
                    }
                }
                nDatasets = datasets.length;
                if (nDatasets > 0) {
                    var recipient = self.nameField.getValue();
                    var locale = qx.locale.Manager.getInstance().getLocale();
                    locale = locale.replace(/_.+/,'');
                    this.__rpc.callAsync(
                        function(data,exc,id) {
                            if (exc == null) {
                                var msg;
                                if (data.sent == 1) {
                                    msg = that.tr("dataset");
                                }
                                else {
                                    msg = that.tr("datasets");
                                }
                                qx.event.message.Bus.dispatchByName(
                                    'error',
                                    [
                                        that.tr("Info"),
                                        data.sent + ' ' + msg + ' ' + that.tr("sent"),
                                        'info'
                                    ]
                                );
                                var userName = that.__info.getUserName();
                                if (userName == recipient) {
                                    qx.event.message.Bus.dispatchByName('agrammon.DatasetCache.refresh', userName);
                                }
                            }
                            else {
                                console.error('send_datasets handler(): exc=', exc, ', data=', data);
                                alert(exc);
                            }
                        },
                        'send_datasets',
                        { recipient: recipient, datasets: datasets, language: locale }
                    );
                }
                self.close();
            }, this);
            dialog =
                new agrammon.ui.dialog.Dialog(
                    this.tr("Sending datasets"),
                    this.tr("Recipient of selected datasets"),
                    null, // value
                    okFunction,
                    this
                );
           this.resetSelection();
        }, this);

    }, // construct

    properties :
    {
        variant: { init: null,
                   check: "String"
                 }
    },

    members :
    {
        __commentColumn: null,
        __btnCopy: null,
        __btnSend: null,
        __btnOpen: null,
        __btnNew: null,
        __btnRename: null,
        __btnDel: null,
        __btnUpload: null,

        __btnSetReference: null,
        __btnClearReference: null,

        __table: null,
        __searchTimer: null,
        __searchFilter: null,
        __filterHash: null,
        __datasetStore: null,

        __searchTimeout: 250, // timeout after which SearchAsYouType view is updated
        __searchColumn:    0, // Dataset name
        __buttonRow: null,
        __toolBar: null,
        __rpc: null,
        __info: null,

     /**
       * TODOC
       *
       * @return {var} TODOC
       * @lint ignoreDeprecated(alert)
       */
        __createToolbarButtons: function() {

            this.__btnRename = new qx.ui.toolbar.Button(this.tr("Rename"),
                                         "icon/16/actions/document-save-as.png");
            this.__btnRename.setToolTip(new qx.ui.tooltip.ToolTip(this.tr("Rename selected dataset")));
            this.__btnSend = new qx.ui.toolbar.Button(this.tr("Send"),
                                         "icon/16/actions/document-send.png");
            this.__btnSend.setToolTip(new qx.ui.tooltip.ToolTip(this.tr("Send selected dataset(s) to other Agrammon user")));

            this.__btnNew = new qx.ui.toolbar.Button(this.tr("New"),
                                         "icon/16/actions/document-new.png");
            this.__btnNew.setToolTip(new qx.ui.tooltip.ToolTip(this.tr("Create new dataset")));
            this.__btnDel = new qx.ui.toolbar.Button(this.tr("Delete"),
                                         'icon/16/actions/window-close.png');
            this.__btnDel.setToolTip(new qx.ui.tooltip.ToolTip(this.tr("Delete selected dataset(s)")));
            this.__btnRename = new qx.ui.toolbar.Button(this.tr("Rename"),
                                         "icon/16/actions/document-save-as.png");

            var uploadPopup = this.__createUploader();
            this.__btnUpload = new qx.ui.toolbar.Button(this.tr("Upload")).set({
                icon : "icon/16/actions/insert-text.png",
                toolTip : new qx.ui.tooltip.ToolTip(this.tr("Upload dataset"))
            });

            this.__toolBar.add(this.__btnRename);
            this.__toolBar.add(this.__btnNew);
            this.__toolBar.add(this.__btnDel);
            this.__toolBar.add(this.__btnSend);
            this.__toolBar.add(this.__btnUpload);

            this.__btnUpload.addListener("execute", function(e) {
                uploadPopup.open();
            }, this);

            this.__btnNew.addListener("execute", function(e) {
                qx.event.message.Bus.dispatchByName('agrammon.FileMenu.openNew', this);
            }, this);

            var that = this;

            this.__datasetStore = agrammon.module.dataset.DatasetCache.getInstance();
            // FIX ME: implement refresh of table content after rename
            this.__btnRename.addListener("execute", function(e) {
                var data = this.__table.getSelectionModel().getSelectedRanges();
                var row = data[0]['minIndex'];
                var oldName = this.__table.getTableModel().getValue(0,row,1);
                var okFunction = qx.lang.Function.bind(function(self) {
                    var newName = self.nameField.getValue();
                    // Don't bother to rename to an already existing dataset name
                    if (this.__datasetStore.datasetExists(newName)) {
                        qx.event.message.Bus.dispatchByName('error',
                            [ this.tr("Error"),
                              this.tr("Dataset") + ' ' + newName
                            + ' ' +this.tr("already exists")]);
                        self.close();
                        return;
                    }

                    qx.event.message.Bus.dispatchByName('agrammon.Output.invalidate');

                    this.__rpc.callAsync(
                        function(data, exc) {
                            if (exc == null) {
                                var userName = that.__info.getUserName();
                                qx.event.message.Bus.dispatchByName('agrammon.DatasetCache.refresh', userName);
                                qx.event.message.Bus.dispatchByName(
                                    'error',
                                    [
                                        that.tr("Info"),
                                        that.tr("Dataset")
                                        + ' ' + oldName
                                        + ' ' + that.tr("renamed to")
                                        + ' ' + newName,
                                        'info'
                                    ]
                                );
                                that.updateView();

                                // change current dataset name if we renamed currently connected dataset
                                if (that.__info.getDatasetName() == oldName ) {
                                    that.__info.setDatasetName(newName);
                                }
                            }
                            else {
                                alert(exc + ': ' + data.error);
                            }
                        },
                        'rename_dataset',
                        { oldName: oldName, newName: newName }
                    );
                    self.close();
                }, this);
                var dialog = new agrammon.ui.dialog.Dialog(this.tr("Rename dataset"),
                                                       this.tr("New name"),
                                                       oldName,
                                                       okFunction, this);
            }, this);


        },

        enableButtons: function(n) {
            switch (n) {
                case 0:
                    this.__btnRename.setEnabled(false);
                    this.__btnDel.setEnabled(false);
                    this.__btnSend.setEnabled(false);
                    break;
                case 1:
                    this.__btnRename.setEnabled(true);
                    this.__btnDel.setEnabled(true);
                    this.__btnSend.setEnabled(true);
                    break;
                default: // >1
                    this.__btnRename.setEnabled(false);
                    this.__btnDel.setEnabled(true);
                    this.__btnSend.setEnabled(true);
                    break;
            }
        },

        setFilter: function(filter) {
            this.__filterHash = filter;
            this.updateView();
        },

        getFilter: function() {
            return this.__filterHash;
        },

        updateView: function() {
            // no table yet, nothing to do
            if (!this.__table) return;

            let tm = this.__table.getTableModel();
            let data = this.__datasetStore.getDatasets();
            if (data == null) return;

            let filter = this.getFilter();
            let searchFilter = this.__searchFilter.toLowerCase();

            let that = this;
            tm.setData(data.filter(function(row) {
                let name = row[0];
                if (!name) return false;
                let all = filter['*all*'] != undefined;
                return ( // that.__showAlways[name] ||//            availableTagsTm.setView(1);
                        (name.toLowerCase().indexOf(that.__searchFilter) != -1)
                        && ( all || (filter[name]) )
                );
            }));
        },

        clearFilter: function() {
            this.__filterHash = {'*all*': true};
            this.__searchFilter = '';
            this.updateView();
        },

        getToolBar: function() {
            return this.__toolBar;
        },

        getSelectionModel: function() {
            return this.__table.getSelectionModel();
        },

        getTableModel: function() {
            return this.__table.getTableModel();
        },

        resetSelection: function() {
            return this.__table.resetSelection();
        },

        addListener: function(a1, a2, a3) {
            var id = this.__table.addListener(a1, a2, a3);
//            this.debug('DatasetTable.addListener(): id='+id);
            return id;
        },

        removeListenerById: function(id) {
            return this.__table.removeListenerById(id);
        },

        addTag: function(datasets, tag) {
            var i, tm=this.__table.getTableModel();
            var ds, len = tm.getRowCount();
            var found, ii, len2=datasets.length;
            var tags;
            for (i=0; i<len; i++) {
                found = false;
                ds = tm.getValue(0, i,1);
                for (ii=0; ii<len2; ii++) {
                    if (ds == datasets[ii]) {
                        found = true;
                    }
                }
                if (found) {
                    tags = tm.getValue(5,i,1);
                    tags.push(tag);
                    tm.setValue(5,i, tags,1);
                }
            }
        },

        removeTag: function(datasets, tag) {
            var i, tm=this.__table.getTableModel();
            var ds, len = tm.getRowCount();
            var found, ii, len2=datasets.length;
            var tags, t, tlen;
            for (i=0; i<len; i++) {
                found = false;
                ds = tm.getValue(0, i,1);
                for (ii=0; ii<len2; ii++) {
                    if (ds == datasets[ii]) {
                        found = true;
                    }
                }
                if (found) {
                    tags = tm.getValue(5,i,1);
                    tlen = tags.length;
                    for (t=tlen-1; t>=0; t--) {
                        if (tags[t] == tag) {
                            tags.splice(t,1);
                        }
                    }
                    tm.setValue(5,i, tags,1);
                }
            }
        },

        renameTag: function(tag_old, tag_new) {
            var i, tm=this.__table.getTableModel();
            var len = tm.getRowCount();
            var tags, t, tlen;
            for (i=0; i<len; i++) {
                tags = tm.getValue(5,i,1);
                tlen = tags.length;
                for (t=0; t<tlen; t++) {
                    if (tags[t] == tag_old) {
                        tags[t] = tag_new;
                    }
                }
                tm.setValue(5,i, tags,1);
            }
        },

        getCommentColumn: function() {
            return this.__commentColumn;
        },

        delTag: function(tag) {
            var i, tm=this.__table.getTableModel();
            var len = tm.getRowCount();
            var tags, t, tlen;
            for (i=0; i<len; i++) {
                tags = tm.getValue(5,i,1);
                tlen = tags.length;
                for (t=0; t<tlen; t++) {
                    if (tags[t] == tag) {
                      tags.splice(t,1);
                    }
                }
                tm.setValue(5,i, tags,1);
            }
        },

        __createTable: function() {
            var tableModel = new qx.ui.table.model.Simple;
            tableModel.sortByColumn(1, false);
            tableModel.setColumns([
                this.tr("Dataset name"),
                this.tr("Last change"),
                this.tr("Parameters"),
                this.tr("Read-only"),
                this.tr("Model Version"),
                this.tr("Tags"),
                this.tr("Comment"),
                this.tr("Model Variant")
            ]);
            this.__commentColumn = 6;

            var resizeBehaviour = { tableColumnModel:
                                    function(obj) {
                                        return new qx.ui.table.columnmodel.Resize(obj);
                                    }
                                  };

            var table = new qx.ui.table.Table(tableModel, resizeBehaviour);
            table.set({
                columnVisibilityButtonVisible: true, //false,
                keepFirstVisibleRowComplete:   true,
                padding: 0,
                showCellFocusIndicator: false
            });
            table.getDataRowRenderer().setHighlightFocusRow(false);

            table.getSelectionModel().setSelectionMode(qx.ui.table.selection.Model.MULTIPLE_INTERVAL_SELECTION);
            var tcm = table.getTableColumnModel();
            var tcmb = tcm.getBehavior();
            tcmb.setWidth(0,'1*');
            tcmb.setWidth(1,130);
            tcmb.setWidth(2,90);
            tcmb.setWidth(3,110);
            tcmb.setWidth(4,100);
            tcmb.setWidth(7,90);
            tcmb.setWidth(this.__commentColumn,70);

            tcm.setColumnVisible(3,true);
            tcm.setColumnVisible(4,false);
            tcm.setColumnVisible(4,false);
            // FIX ME: Column 5 must not be made visible, because it
            // has an array as value. Needs a specific cell renderer!
            tcm.setColumnVisible(5,false);

            tcm.setDataCellRenderer(3, new qx.ui.table.cellrenderer.Boolean());
            tcm.setHeaderCellRenderer(0, new qx.ui.table.headerrenderer.Icon("icon/16/apps/office-database.png",
                                                                             this.tr("Dataset name")));
            tcm.setHeaderCellRenderer(1, new qx.ui.table.headerrenderer.Icon("icon/16/apps/office-calendar.png",
                                                                             this.tr("Last change")));
            tcm.setHeaderCellRenderer(3, new qx.ui.table.headerrenderer.Icon("agrammon/read-only_ts.png",
                                                                             this.tr("Read-only")));

            tcm.setDataCellRenderer(this.__commentColumn, new agrammon.ui.table.cellrenderer.Comment());

            this.clearFilter();

            return table;
        },

        __createUploader : function() {
            var popup = new qx.ui.window.Window(this.tr('Upload dataset')).set({
                layout : new qx.ui.layout.VBox(10),
                centerOnAppear: true,
                modal : true
            });
            var datasetName = new qx.ui.form.TextField();
            var comment = new qx.ui.form.TextArea();
            var form = new qx.ui.form.Form();
            form.add(datasetName, this.tr('Dataset name'));
            form.add(comment, this.tr('Comment'));
            popup.add(new qx.ui.form.renderer.Single(form));

            var uploadBtn = new com.zenesis.qx.upload.UploadButton("Upload dataset").set({
                allowGrowX: false,
                alignX: 'right',
                alignY: 'middle',
                enabled: true,
                allowGrowY: false,
                icon : "icon/16/actions/insert-text.png"
            });

            var uploader = new com.zenesis.qx.upload.UploadMgr(uploadBtn, "/upload");
            var cancelBtn = new qx.ui.form.Button(this.tr('Cancel'));
             var okBtn = new qx.ui.form.Button(this.tr('OK'));
            okBtn.addListener('execute', function() {
                popup.close();
            }, this);

            var btnRow = new qx.ui.container.Composite(new qx.ui.layout.HBox(10), 'right');
            popup.add(btnRow);
            btnRow.add(cancelBtn);
            btnRow.add(uploadBtn);

            var progressRow = new qx.ui.container.Composite(new qx.ui.layout.HBox(10), 'right');
            popup.add(progressRow);
            var uploadProgress = new qx.ui.basic.Label();
            progressRow.add(uploadProgress);
            progressRow.add(new qx.ui.core.Spacer(1), {flex : 1})
            progressRow.add(okBtn);

            var uploadResponse = new qx.ui.basic.Label();
            popup.add(uploadResponse);

            popup.addListener('appear', function() {
                cancelBtn.setEnabled(false);
                okBtn.setEnabled(false);
                uploadBtn.setEnabled(true);
                uploadProgress.resetValue();
                uploadResponse.resetValue();
            }, this);

            uploader.addListener("addFile", function(evt) {
                var file = evt.getData();
                uploader.setParam('comment', comment.getValue());
                uploader.setParam('datasetName', datasetName.getValue());
                cancelBtn.setEnabled(true);
                uploadBtn.setEnabled(false);
                var filename = file.getFilename();
                var username = this.__info.getUserName()

                var cancelListenerId = cancelBtn.addListener('execute', function(e) {
                    if (file.getState() == "uploading" || file.getState() == "not-started") {
                        uploader.cancel(file);
                    }
                }, this);

                var responseListenerId = file.addListener("changeResponse", function(e) {
                    var response = qx.lang.Json.parse(e.getData());
                    uploadResponse.setValue(this.tr('Uploaded %1 lines', response.lines));
                    if (progressListenerId) {
                        file.removeListenerById(progressListenerId);
                    }
                    if (stateListenerId) {
                        file.removeListenerById(stateListenerId);
                    }
                    if (cancelListenerId) {
                        cancelBtn.removeListenerById(cancelListenerId);
                    }
                    okBtn.setEnabled(true);
                    uploadBtn.setEnabled(true);
                    cancelBtn.setEnabled(false);
                }, this);

                var stateListenerId = file.addListener("changeState", function(evt) {
                    var state = evt.getData();
                    if (state == "uploading") {
                        this.debug(file.getFilename() + " (Uploading...)");
                    }
                    else if (state == "uploaded" || state == "cancelled") {
                        if (state == "uploaded") {
                            this.debug(file.getFilename() + " (Complete)");
                            uploadProgress.resetValue();
                            // TODO: this needs a delay
                            qx.event.message.Bus.dispatchByName('agrammon.DatasetCache.refresh', username);
                        }
                        if (state == "cancelled") {
                           this.debug(file.getFilename() + " (Cancelled)");
                        }
                    }
                }, this);

                var progressListenerId = file.addListener("changeProgress", function(evt) {
                    uploadProgress.setValue(
                          "Upload " + file.getFilename() + ": "
                        + evt.getData() + " / " + file.getSize() + " - "
                        + Math.round(evt.getData() / file.getSize() * 100) + "%"
                    );
                }, this);

            }, this);
            return popup;
        }

    }
});

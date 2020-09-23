/* ************************************************************************

************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/document-save-as.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/document-new.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/document-send.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/window-close.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/office-calendar.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/office-database.png)
 * @asset(Agrammon/read-only_ts.png)
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
//            this.debug('timer fired, searchFilter='+ this.__searchFilter);
            this.__searchTimer.stop();
            this.__table.getTableModel().updateView(1);
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
                    this.__rpc.callAsync( send_datasets_func,
                                         'send_datasets',
                                         { recipient: recipient,
                                           datasets:  datasets });
                }
                self.close();
            }, this);
            dialog =
                new agrammon.ui.dialog.Dialog(this.tr("Sending datasets"),
                                              this.tr("Recipient of selected datasets"),
                                              okFunction, this);
           this.resetSelection();
        }, this);

        var send_datasets_func = function(data,exc,id) {
            if (exc == null) {
                var msg;
                if (data == 1) {
                    msg = that.tr("dataset");
                }
                else {
                    msg = that.tr("datasets");
                }
                qx.event.message.Bus.dispatchByName('error',
                                                    [ that.tr("Info"), data + ' ' + msg + ' ' + that.tr("sent"),
                                                      'info' ]);
            }
            else {
                alert(exc);
            }
        }; // send_datasets_func()

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

            this.__btnRename =
                new qx.ui.toolbar.Button(this.tr("Rename"),
                                         "icon/16/actions/document-save-as.png");
            this.__btnRename.setToolTip(new qx.ui.tooltip.ToolTip(this.tr("Rename selected dataset")));
            this.__btnSend =
                new qx.ui.toolbar.Button(this.tr("Send"),
                                         "icon/16/actions/document-send.png");
            this.__btnSend.setToolTip(new qx.ui.tooltip.ToolTip(this.tr("Send selected dataset(s) to other Agrammon user")));

            this.__btnNew =
                new qx.ui.toolbar.Button(this.tr("New"),
                                         "icon/16/actions/document-new.png");
            this.__btnNew.setToolTip(new qx.ui.tooltip.ToolTip(this.tr("Create new dataset")));
            this.__btnDel = new qx.ui.toolbar.Button(this.tr("Delete"),
                                         'icon/16/actions/window-close.png');
            this.__btnDel.setToolTip(new qx.ui.tooltip.ToolTip(this.tr("Delete selected dataset(s)")));
            this.__toolBar.add(this.__btnRename);
            this.__toolBar.add(this.__btnNew);
            this.__toolBar.add(this.__btnDel);
            this.__toolBar.add(this.__btnSend);

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
                                that.__table.getTableModel().updateView(1);

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
            this.__table.getTableModel().updateView(1);
        },

        getFilter: function() {
            return this.__filterHash;
        },

        clearFilter: function() {
            this.__filterHash = {'*all*': true};
            this.__searchFilter = '';
            if (this.__table) {
                this.__table.getTableModel().updateView(1);
            }
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
            var tableModel = new agrammon.ui.table.model.Smart; // qx.ui.table.model.Simple();
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
            table.set({ columnVisibilityButtonVisible: true, //false,
                        keepFirstVisibleRowComplete:   true,
                        padding: 0,
                        showCellFocusIndicator: false });
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
            tcm.setHeaderCellRenderer(3, new qx.ui.table.headerrenderer.Icon("Agrammon/read-only_ts.png",
                                                                             this.tr("Read-only")));

            tcm.setDataCellRenderer(this.__commentColumn, new agrammon.ui.table.cellrenderer.Comment());

            // setup Smart filtering

            // The following view has two filters.
            // Filter 1 passes
            //     - all datasets if filterHash['*all*']
            //     - or otherwise only those datasets for which
            //       __filterHash[datasetName] is defined and are not demo datasets
            //
            // Filter 2 (incremental search) then passes
            //     - all remaining datasets if __searchFilter is the empty string
            //     - or otherwise only those datasets whose contain the
            //       the __searchFilter string
            tableModel.addView(  // show lines matching filter only
                function (rowdata) {
                    var name = rowdata[this.__searchColumn];
//                    var readOnly = rowdata[3];
                    var demo     = rowdata[8];
                    var all = this.__filterHash['*all*'];
                    return ( !demo
                          && (all ||  (this.__filterHash[name] ) )
                          && (name.toLowerCase().indexOf(this.__searchFilter) != -1));
                },
                this, null);

            // init smart filtering
            this.clearFilter();
            tableModel.setView(1);
            tableModel.updateView(1);

            return table;
        }

    }
});

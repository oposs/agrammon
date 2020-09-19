/* ************************************************************************

************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/apps/office-database.png)
 * @asset(Agrammon/*)
 */

qx.Class.define('agrammon.module.dataset.DatasetTableSimple', {
    extend:  qx.ui.container.Composite,

  construct: function (title, rpc, info) {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox(5));
        this.set({allowShrinkY: true});
        this.info = info;
        this.rpc  = rpc;

        this.__table = this.__createTable();
        this.__table.setAllowShrinkY(true);
        var datasetFilter =
            new Agrammon.ui.form.VarInput(null, null,null,
                                     this.tr("Incremental filter on dataset name"),
                                     this.tr("Filter on dataset name"), false);
        datasetFilter.addListener('input', function(e) {
              this.__searchFilter = e.getData().toLowerCase();
              this.__searchTimer.restart();
          }, this);

        this.__searchTimer = new qx.event.Timer(this.__searchTimeout);
        this.__searchTimer.addListener('interval', function(e) {
            this.debug('timer fired, searchFilter='+ this.__searchFilter);
            this.__searchTimer.stop();
            this.__table.getTableModel().updateView(1);
            this.__table.resetCellFocus();
        }, this);

        this.add(datasetFilter);
//        datasetFilter.setPadding(0,5,0,5);
        datasetFilter.setMargin(10,10,0,10);
        this.__table.setMargin(0,10,0,10);
        this.add(this.__table, {flex: 1});
//        this.add(this.__table, {flex: 0});




    }, // construct

    members :
    {
        __btnCopy: null,
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

        __searchTimeout: 250, // timeout after which SearchAsYouType view is updated
        __searchColumn:    0, // Dataset name
        __buttonRow: null,


        enableButtons: function(n, readOnly) {
            switch (n) {
                case 0:
                    this.__btnRename.setEnabled(false);
                    this.__btnDel.setEnabled(false);
                    break;
                case 1:
                    if (readOnly) {
                        this.__btnRename.setEnabled(false);
                        this.__btnDel.setEnabled(false);
                    }
                    else {
                        this.__btnRename.setEnabled(true);
                        this.__btnDel.setEnabled(true);
                    }
                    break;
                default: // >1
                    this.__btnRename.setEnabled(false);
                    if (readOnly) {
                        this.__btnDel.setEnabled(false);
                    }
                    else {
                        this.__btnDel.setEnabled(true);
                    }
                    break;
            }
        },

        getSelectionModel: function() {
            return this.__table.getSelectionModel();
        },

        getTableModel: function() {
            return this.__table.getTableModel();
        },

        resetCellFocus: function() {
            return this.__table.resetCellFocus();
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


        __createTable: function() {

//            var tableModel = new smart.Smart; // qx.ui.table.model.Simple();
            var tableModel = new Agrammon.ui.table.model.Smart; // qx.ui.table.model.Simple();
            tableModel.setColumns([
                                    this.tr("Dataset name"),
		 		                    this.tr("Last change"),
				                    this.tr("Parameters"),
                                    this.tr("Read-only"),
                                    this.tr("Model Version"),
                                    this.tr("Tags")
                                  ]);

            var resizeBehaviour = { tableColumnModel:
                                    function(obj) {
                                        return new qx.ui.table.columnmodel.Resize(obj);
                                    }
                                  };

            var table = new qx.ui.table.Table(tableModel, resizeBehaviour);
            table.set({ columnVisibilityButtonVisible: true,
                        keepFirstVisibleRowComplete:   true,
                        padding: 0,
                        showCellFocusIndicator: false
                        });
            table.getSelectionModel().setSelectionMode(qx.ui.table.selection.Model.MULTIPLE_INTERVAL_SELECTION);
            var tcm = table.getTableColumnModel();
            var tcmb = tcm.getBehavior();
            tcmb.setWidth(0,'1*');
            tcmb.setWidth(1,120);
            tcmb.setWidth(2,75);
            tcmb.setWidth(3,110);
            tcmb.setWidth(4,100);

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

            // setup Smart filtering

            // The following view has two filters.
            // Filter 1 passes
            //     - all datasets if filterHash['*all*']
            //     - or otherwise only those datasets for which
            //       __filterHash[datasetName] is defined and are not readOnly
            //
            // Filter 2 (incremental search) then passes
            //     - all remaining datasets if __searchFilter is the empty string
            //     - or otherwise only those datasets whose contain the
            //       the __searchFilter string
            tableModel.addView(  // show lines matching filter only
                function (rowdata) {
                    var name = rowdata[this.__searchColumn];
                    return ( name.toLowerCase().indexOf(this.__searchFilter) != -1);
                },
                this, null);

            // init smart filtering
            tableModel.setView(1);
            tableModel.updateView(1);

            return table;
        }

    }
});

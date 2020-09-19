/* ************************************************************************

************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/window-close.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/office-calendar.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/utilities-archiver.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/office-database.png)
 * @asset(Agrammon/read-only_ts.png)
 */

qx.Class.define('agrammon.module.dataset.DatasetCreate', {
    extend :  qx.ui.window.Window,
    include : qx.ui.core.MPlacement,

    construct: function (title, prompt, callBack) {
        this.base(arguments);
        var maxHeight = qx.bom.Document.getHeight() - 20;
        this.set({layout: new qx.ui.layout.VBox(5),
                  maxHeight: maxHeight,
                  allowShrinkY: true,
                  showClose: true, showMinimize: false, showMaximize: false,
                  caption: title,
                  modal: true,
                  contentPadding: [0, 0, 10, 0], padding: 0,
                  minWidth: 500,
                  icon: 'icon/16/apps/utilities-archiver.png'
                 });
        this.getChildControl("pane").setBackgroundColor("white");
        var that = this;


        qx.event.message.Bus.subscribe('Agrammon.datasetsLoaded', function(msg) {
                                           this.__setDatasets();
                                       }, this);


        this.setPlaceMethod('mouse');
        this.setPosition('top-left');
        this.__table = this.__createTable();
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
            this.debug('timer fired, searchFilter='+ this.__searchFilter);
            this.__searchTimer.stop();
            this.__table.getTableModel().updateView(1);
            this.__table.resetCellFocus();
        }, this);

        this.add(datasetFilter);
        datasetFilter.setMargin(10,10,0,10);
        this.__table.setMargin(0,10,0,10);
        this.add(this.__table, {flex: 1});

        var nameBox = new qx.ui.container.Composite(new qx.ui.layout.HBox().set({alignY: 'middle'}));

        var nameLabel =
            new qx.ui.basic.Label(prompt).set({paddingRight: 5});
        nameBox.add(nameLabel);

        var nameField = new qx.ui.form.TextField();
        this.nameField = nameField;
        nameBox.add(nameField);
        this.addListener('appear', function() {
            nameField.focus();
        }, this);


        var btnCancel = new qx.ui.form.Button(this.tr("Close"),
                                              "icon/16/actions/window-close.png");
        btnCancel.addListener("execute", function(e) {
            this.close();
        }, this);
        this.__buttonRow =
            new qx.ui.container.Composite(new qx.ui.layout.HBox(10,'right'));
        this.__buttonRow.setPadding(5,10,0,10);

        this.__btnNew = new qx.ui.form.Button(this.tr("Create"), "");
        this.__btnNew.addListener("execute", function(e) {
            callBack(this);
        }, this);

        this.__buttonRow.add(nameBox);
        this.__buttonRow.add(new qx.ui.core.Spacer(1,0), {flex:1});
        this.__buttonRow.add(btnCancel);
        this.__buttonRow.add(this.__btnNew);

        this.add(this.__buttonRow);

        this.__datasetCache = agrammon.module.dataset.DatasetCache.getInstance();
        this.__setDatasets = function() {
            // used for datasetFilter
            that.__datasets = this.__datasetCache.getDatasets();
		    var len = that.__datasets.length;
            that.debug('__setDatasets(): len='+len);
		    if (len<1) {
                //		        alert('No existing datasets in database yet.');
			    return;
		    }
            var datasetTable = that.__table;
            var datasetTm = datasetTable.getTableModel();
            datasetTm.setData(null);
            datasetTm.addRows(that.__datasets);
            datasetTable.getSelectionModel().resetSelection();
            datasetTable.resetCellFocus();
            datasetTm.updateView(1);
            datasetTm.setView(1);
        }; // this.__setDatasets()
        this.__btnNew.setEnabled(false);
        this.__table.getSelectionModel().addListener("changeSelection",
                                                     function(e) {
            var selections =
                this.__table.getSelectionModel().getSelectedRanges().length;
                if (selections > 0 ||  this.nameField.getValue() ) {
                    this.__btnNew.setEnabled(true);
                }
                else {
                    this.__btnNew.setEnabled(false);
                    this.__table.resetCellFocus();
                }
        }, this);

        this.nameField.addListener("input",
                                   function(e) {
            var selections =
                this.__table.getSelectionModel().getSelectedRanges().length;
                if (selections > 0 ||  this.nameField.getValue() ) {
                    this.__btnNew.setEnabled(true);
                }
                else {
                    this.__btnNew.setEnabled(false);
                    this.__table.resetCellFocus();
                }
        }, this);

        this.__setDatasets();
        this.addListener("resize", this.center, this);

        // resize window if browser window size changes
        qx.core.Init.getApplication().getRoot().addListener("resize",
                                                            function () {
            var height = qx.bom.Document.getHeight() - 20;
            this.setMaxHeight(height);
        }, this);
    }, // construct

    members :
    {
        __setDatasets: null,
        __btnNew: null,
        __buttonRow: null,
        __table: null,
        __datasetCache: null,
        __datasets: null,
        __searchTimer: null,
        __searchFilter: null,
        __searchTimeout: 250, // timeout after which SearchAsYouType view is updated
        __searchColumn:    0, // Dataset name

        getSelectionModel: function() {
            return this.__table.getSelectionModel();
        },

        getTableModel: function() {
            return this.__table.getTableModel();
        },

        getDatasetCache: function() {
            return this.__datasetCache;
        },

        resetCellFocus: function() {
            return this.__table.resetCellFocus();
        },

        resetSelection: function() {
            return this.__table.resetSelection();
        },

        __clearFilter: function() {
            this.__searchFilter = '';
            if (this.__table) {
                this.__table.getTableModel().updateView(1); // why are they numbered from 1-n?
            }
        },

        __createTable: function() {

//            var tableModel = new smart.Smart; // qx.ui.table.model.Simple();
            var tableModel = new agrammon.ui.table.model.Smart; // qx.ui.table.model.Simple();
            tableModel.setColumns([
                                    this.tr("Sample datasets"),
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
            table.getSelectionModel().setSelectionMode(qx.ui.table.selection.Model.SINGLE_SELECTION);
            var tcm = table.getTableColumnModel();
            var tcmb = tcm.getBehavior();
            tcmb.setWidth(0,'1*');
            tcmb.setWidth(1,130);
            tcmb.setWidth(2,90);
            tcmb.setWidth(3,110);
            tcmb.setWidth(4,100);

            tcm.setColumnVisible(3,false);
            tcm.setColumnVisible(4,false);

            table.getDataRowRenderer().setHighlightFocusRow(false);

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

            // read-only datasets matching search filter
            tableModel.addView(  // show lines matching filter only
                function (rowdata) {
                    var name = rowdata[this.__searchColumn];
                    var demo = rowdata[8];
                    return ( demo && (name.toLowerCase().indexOf(this.__searchFilter) != -1) );
                },
                this, null);

            // init smart filtering
            this.__clearFilter();
            tableModel.setView(1);
//            tableModel.updateView(1);

            return table;
        }

    }
});

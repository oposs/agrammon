/* ************************************************************************

************************************************************************ */

/**
 * @asset(agrammon/tags_ts.png)
 */

qx.Class.define('agrammon.module.dataset.TagTable', {
    extend:  qx.ui.container.Composite,

    construct: function(title) {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox(5));

        this.__table = this.__createTable(title);
        this.__showAlways = {};

        var datasetFilter =
            new agrammon.ui.form.VarInput(
                null, null,null,
                this.tr("Incremental filter on tag name"),
                this.tr("Filter on tag name"), false
            );
        datasetFilter.addListener('input', function(e) {
            this.__searchFilter = e.getData().toLowerCase();
            this.__searchTimer.restart();
        }, this);

        datasetFilter.setMargin(0,10,0,10);
        this.__searchTimer = new qx.event.Timer(this.__searchTimeout);
        this.__searchTimer.addListener('interval', function(e) {
            this.__searchTimer.stop();
            this.updateView();
        }, this);

        this.add(datasetFilter);

        this.addListener('appear', () => {
            // make sure we have the value when reopening this widget
            this.__searchFilter = datasetFilter.getValue() || '';
            if (this.__searchFilter != '') {
                this.updateView();
            }
        }, this);

      this.__table.setMinWidth(150);
        this.__table.setAllowGrowX(true);
        this.setPadding(0);
        this.add(this.__table, {flex: 1});

    }, // construct

    members :
    {
        __table: null,
        __searchTimer: null,
        __searchTimeout: 250, // timeout after which SearchAsYouType view is updated
        __searchColumn:    0, // for all three tables
        __searchFilter: null,
        __filterHash: null,
        __showAlways: null,

        getSelectionModel: function() {
            return this.__table.getSelectionModel();
        },

        getTableModel: function() {
            return this.__table.getTableModel();
        },

        getTableColumnModel: function() {
            return this.__table.getTableColumnModel();
        },

        addListener: function(a1, a2, a3) {
            return this.__table.addListener(a1, a2, a3);
        },

        setFilter: function(filter) {
            if (filter == {}) {
                this.__filterHash = {'*all*': true};
            }
            else {
                this.__filterHash = filter;
            }
            this.updateView();
        },

        setShowAlways: function(filter) {
            this.__showAlways = filter;
            this.updateView();
        },

        addToFilter: function(name, value) {
            this.__filterHash[name] = value;
            this.updateView();
        },

        removeFromFilter: function(name) {
            delete this.__filterHash[name];
            this.updateView();
        },

        getFilter: function() {
            return this.__filterHash;
        },

        updateView: function() {
            let tm = this.__table.getTableModel();
            let data = agrammon.module.dataset.DatasetCache.getInstance().getTags();
            if (!data) return;

            let searchFilter = this.__searchFilter.toLowerCase();
            let that = this;
            let filteredData = data.filter(function(name) {
                return (name.toLowerCase().indexOf(searchFilter) != -1);
            });
            let tableData = [];
            for (let tag of filteredData) {
                tableData.push([tag])   ;
            }
            tm.setData(tableData);
        },

        clearFilter: function() {
            this.__searchFilter = '';
        },

        renameTag: function(tag_old, tag_new) {

            var i, tm=this.__table.getTableModel();
            var tag, len = tm.getRowCount(0);
            for (i=0; i<len; i++) {
                tag = tm.getValue(0,i,0);
                if (tag == tag_old) {
                    tm.setValue(0, i, tag_new, 0);
                }
            }
            if (this.__filterHash[tag_old]) {
                this.addToFilter(tag_new, true);
                this.removeFromFilter(tag_old);
            }
        },

        delTag: function(dTag) {
            var i, tm=this.__table.getTableModel();
            var tag, len = tm.getRowCount(0);
            for (i=0; i<len; i++) {
                tag = tm.getValue(0,i,0);
                if (tag == dTag) {
                    tm.removeRows(i,1);
                }
            }
            if (this.__filterHash[dTag]) {
                this.removeFromFilter(dTag);
            }
        },

      __createTable: function(title) {
            var tableModel = new qx.ui.table.model.Simple();
            tableModel.setColumns([ title ]);

            var resizeBehaviour = { tableColumnModel : function(obj) {
                    return new qx.ui.table.columnmodel.Resize(obj);
                }
            };

            var table = new qx.ui.table.Table(tableModel, resizeBehaviour).set({
                columnVisibilityButtonVisible: false,
                keepFirstVisibleRowComplete: true,
                padding: 0,
                showCellFocusIndicator: false
            });
            table.setMargin(0,10,0,10);

            table.getSelectionModel().setSelectionMode(qx.ui.table.selection.Model.MULTIPLE_INTERVAL_SELECTION_TOGGLE);
//            table.getSelectionModel().setSelectionMode(qx.ui.table.selection.Model.MULTIPLE_INTERVAL_SELECTION);

            table.getTableColumnModel().setHeaderCellRenderer(
                0,
                new qx.ui.table.headerrenderer.Icon("agrammon/tags_ts.png", title)
            );
            table.getDataRowRenderer().setHighlightFocusRow(false);

            return table;
        }

    }
});

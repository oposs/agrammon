/* ************************************************************************

************************************************************************ */

/**
 * @asset(Agrammon/tags_ts.png)
 */

qx.Class.define('agrammon.module.dataset.TagTable', {
    extend:  qx.ui.container.Composite,

  construct: function (title, indexed) {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox(5));

        this.__table = this.__createTable(title, indexed);
        this.__showAlways = {};

        var datasetFilter =
            new agrammon.ui.form.VarInput(null, null,null,
                                     this.tr("Incremental filter on tag name"),
                                     this.tr("Filter on tag name"), false);
        datasetFilter.addListener('input', function(e) {
              this.__searchFilter = e.getData().toLowerCase();
              this.__searchTimer.restart();
          }, this);

        datasetFilter.setMargin(0,10,0,10);
        this.__table.setMargin(0,10,0,10);
        this.__searchTimer = new qx.event.Timer(this.__searchTimeout);
        this.__searchTimer.addListener('interval', function(e) {
            this.__searchTimer.stop();
            this.__table.getTableModel().updateView(1); // why are they numbered from 1-n?
            this.__table.getTableModel().setView(1);
        }, this);

        this.add(datasetFilter);

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
            this.__table.getTableModel().updateView(1); // why are they numbered from 1-n?
        },

        setShowAlways: function(filter) {
            this.__showAlways = filter;
            this.__table.getTableModel().updateView(1); // why are they numbered from 1-n?
        },

        addToFilter: function(name, value) {
            this.__filterHash[name] = value;
            this.__table.getTableModel().updateView(1); // why are they numbered from 1-n?
        },

        removeFromFilter: function(name) {
            delete this.__filterHash[name];
            this.__table.getTableModel().updateView(1); // why are they numbered from 1-n?
        },

        clearFilter: function() {
            this.__filterHash = {'*all*': true};
            this.__searchFilter = '';
            if (this.__table) {
                this.__table.getTableModel().updateView(1); // why are they numbered from 1-n?
            }
        },

        renameTag: function(tag_old, tag_new) {

            var i, tm=this.__table.getTableModel();
            var tag, len = tm.getRowCount(0);
//            var data = tm.getData();
//            this.debug('TagTable.renameTag(): col=' + tm.getColumnName(0)
//                       +', tag_old=' +tag_old+', tag_new='+tag_new
//                       +', len='+len+', data='+data);
            for (i=0; i<len; i++) {
//                this.debug('TagTable.renameTag(): i='+i);
                tag = tm.getValue(0,i,0);
//                this.debug('TagTable.renameTag(): tag='+tag);
                if (tag == tag_old) {
                    tm.setValue(0, i, tag_new, 0);
//                    this.debug('TagTable.renameTag(): renamed '
//                               + tag_old + ' -> ' + tag_new);
                }
            }
//            for (var t in this.__filterHash) {
//                this.debug('filterHash: t='+t+', f='+this.__filterHash[t]);
//            }
            if (this.__filterHash[tag_old]) {
//              this.debug('TagTable.renameTag(): exchange filter '
//                         + tag_old + ' -> ' + tag_new);
                this.addToFilter(tag_new, true);
                this.removeFromFilter(tag_old);
            }
        },

        delTag: function(dTag) {
            var i, tm=this.__table.getTableModel();
            var tag, len = tm.getRowCount(0);
//            var data = tm.getData();
//            this.debug('TagTable.delTag(): dTag=' + dTag);
            for (i=0; i<len; i++) {
                tag = tm.getValue(0,i,0);
//                this.debug('TagTable.delTag(): tag='+tag);
                if (tag == dTag) {
                    tm.removeRows(i,1);
//                    this.debug('TagTable.delTag(): deleted '
//                               + tag);
                }
            }
//            for (var t in this.__filterHash) {
//                this.debug('filterHash: t='+t+', f='+this.__filterHash[t]);
//            }
            if (this.__filterHash[dTag]) {
//                this.debug('TagTable.delTag(): remove filter '
//                           + dTag);
                this.removeFromFilter(dTag);
            }
        },

      __createTable: function(title, indexed) {

            // table model
//            var tableModel = new smart.Smart; // qx.ui.table.model.Simple();
            var tableModel = new agrammon.ui.table.model.Smart; // qx.ui.table.model.Simple();
            tableModel.setColumns([ title ]);

            // The following view has two filters.
            // Filter 1 passes
            //     - all datasets if filterHash['*all*']
            //     - or otherwise only those datasets for which
            //       __filterHash[datasetName] is NOT defined
            //
            // Filter 2 (incremental search) then passes
            //     - all remaining datasets if __searchFilter is the empty string
            //     - or otherwise only those datasets whose contain the
            //       the __searchFilter string
            tableModel.addView(  // show lines matching filter only
                function (rowdata) {
                    var name = rowdata[this.__searchColumn];
                    var all = this.__filterHash['*all*'] != undefined;
                    return (  this.__showAlways[name] ||
                                (name.toLowerCase().indexOf(this.__searchFilter) != -1)
                             && (all || (this.__filterHash[name] == undefined)) );
                },
                this, null);

            var resizeBehaviour = { tableColumnModel:
                                    function(obj) {
                                        return new qx.ui.table.columnmodel.Resize(obj);
                                    }
                                  };

            var table = new qx.ui.table.Table(tableModel, resizeBehaviour);
            table.set({ columnVisibilityButtonVisible: false,
                        keepFirstVisibleRowComplete: true,
                        padding: 0,
                        showCellFocusIndicator: false
                      });

//            table.getSelectionModel().setSelectionMode(qx.ui.table.selection.Model.MULTIPLE_INTERVAL_SELECTION_TOGGLE);
            table.getSelectionModel().setSelectionMode(qx.ui.table.selection.Model.MULTIPLE_INTERVAL_SELECTION);

            table.getTableColumnModel().setHeaderCellRenderer(0,
                                                              new qx.ui.table.headerrenderer.Icon("Agrammon/tags_ts.png",
                                                              title));
            table.getDataRowRenderer().setHighlightFocusRow(false);
            if (indexed) {
                tableModel.addIndex(0);
                tableModel.indexedSelection(0, table.getSelectionModel());
            }

            // init smart filtering
            this.clearFilter();
            tableModel.setView(1);
            tableModel.updateView(1);


            return table;
        }

    }
});

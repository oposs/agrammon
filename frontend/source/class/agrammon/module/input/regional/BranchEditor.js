// ä
/* ************************************************************************

************************************************************************ */

/**
  * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
  * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
  */

qx.Class.define('agrammon.module.input.regional.BranchEditor', {
    extend: qx.ui.window.Window,

    construct: function (vars, labels, options, currentFolder) {
        this.base(arguments);
        var locale = qx.locale.Manager.getInstance().getLocale();
        locale = locale.replace(/_.+/,'');
        this.__currentFolder = currentFolder;

        this.__rpc  = agrammon.io.remote.Rpc.getInstance();
        this.__info = agrammon.Info.getInstance();

        this.__nCols = options[1].length;
        this.__nRows = options[0].length;
        this.__vars = vars;
        this.__options  = options;
        var xLabel = new qx.ui.basic.Label(labels[1]+': ');
        var yLabel = new qx.ui.basic.Label(labels[0]+': ');
        this.__xValue = new qx.ui.basic.Label('').set({font: 'bold'});
        this.__yValue = new qx.ui.basic.Label('').set({font: 'bold'});
        var total = new qx.ui.basic.Label(this.tr("Total")+': ');
        this.__totalValue = new qx.ui.basic.Label('').set({font: 'bold'});

        var height = qx.bom.Document.getHeight() - 20;
        this.set({
            caption: this.tr("Branch configuration"),
            layout: new qx.ui.layout.VBox(5),
            maxHeight: height, modal: true,
            showClose: true, showMinimize: false, showMaximize: false,
            allowShrinkX:  true,
            allowShrinkY:  true,
            allowStretchX: true,
            allowStretchY: true,
            allowGrowX:    true
        });

        // center and resize window if browser window size changes
        this.addListener("resize", this.center, this);
        qx.core.Init.getApplication().getRoot().addListener("resize", function () {
            var height = qx.bom.Document.getHeight() - 20;
            this.setMaxHeight(height);
        }, this);

        var branchEditor = this.__createTable(this.__nCols, this.__nRows, locale, labels);
        this.__loadBranchData();

        var btnCancel = new qx.ui.form.Button(this.tr("Cancel"), "icon/16/actions/dialog-cancel.png");
        btnCancel.addListener("execute", function(e) {
            this.close();
        }, this);

        var btnClear = new qx.ui.form.Button(this.tr("Clear"), null);
        btnClear.addListener("execute", function(e) {
            this.__clearBranchData();
        }, this);

        var btnOK = new qx.ui.form.Button(this.tr("Save"), "icon/16/actions/dialog-ok.png");
        btnOK.addListener("execute", function(e) {
            this.__storeBranchData();
        }, this);

        this.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                btnOK.execute();
            }
        });

        var buttonRow = new qx.ui.container.Composite(new qx.ui.layout.HBox(10, 'right'));
        buttonRow.add(btnCancel);
        buttonRow.add(btnClear);
        buttonRow.add(btnOK);
        buttonRow.setPaddingTop(20);

        var grid = new qx.ui.layout.Grid(5);
        grid.setColumnAlign(0, 'right', 'middle');
        grid.setColumnAlign(1, 'left',  'middle');
        grid.setColumnFlex(0, 1);
        var inputGrid = new qx.ui.container.Composite(grid);
        inputGrid.setPaddingTop(20);
        inputGrid.add(xLabel,            { column: 0, row: 0 });
        inputGrid.add(yLabel,            { column: 0, row: 1 });
        inputGrid.add(this.__xValue,     { column: 1, row: 0 });
        inputGrid.add(this.__yValue,     { column: 1, row: 1 });
        inputGrid.add(total,             { column: 0, row: 3 });
        inputGrid.add(this.__totalValue, { column: 1, row: 3 });

        this.add(branchEditor, { flex : 1 });
        this.add(inputGrid);
        this.add(buttonRow);
    }, // construct

    members :
    {
        __table: null,
        __info: null,
        __rpc: null,
        __xValue: null,
        __yValue: null,
        __totalValue: null,
        __nRows: null,
        __nCols: null,
        __vars: null,
        __options: null,
        __currentFolder: null,

        __createTable: function(nCols, nRows, locale, labels) {
            var lBox = new qx.ui.container.Composite(new qx.ui.layout.HBox(10,'right'));
            var tableBox = new qx.ui.container.Composite(new qx.ui.layout.VBox(10));
            lBox.add(new qx.ui.core.Spacer(1,1), {flex:1});
            var lgrid = new qx.ui.layout.Grid(0);
            lgrid.setColumnAlign(0, 'right', 'middle');
            lgrid.setColumnAlign(1, 'left',  'middle');
            lgrid.setColumnFlex(1, 1);
            var legendGrid = new qx.ui.container.Composite(lgrid);
            lBox.add(legendGrid);
            tableBox.add(lBox);

            var i;
            var cols = [labels[0]];
            var data = [];
            legendGrid.add(
                new qx.ui.basic.Label(labels[1]+':').set({alignX:'left'}),
                {column: 0, row: 0, colSpan: 2}
            );
            for (i=0; i<nCols; i++) {
                cols.push(String(i));
                legendGrid.add(new qx.ui.basic.Label(i+' ... '), {column: 0, row: i+1});
                legendGrid.add(new qx.ui.basic.Label(this.__options[1][i][locale]), {column: 1, row: i+1});
            }
            for (i=0; i<nRows; i++) {
                data.push([ this.__options[0][i][locale] ]);
            }

            var tableModel = new qx.ui.table.model.Simple();
            tableModel.setColumns(cols);

            var resizeBehaviour = {
                tableColumnModel: function(obj) {
                    return new qx.ui.table.columnmodel.Resize(obj);
                }
            };
            var table = this.__table = new qx.ui.table.Table(tableModel, resizeBehaviour);
            var rowHeight = table.getRowHeight();
            table.set({
                //columnVisibilityButtonVisible: true,
                columnVisibilityButtonVisible: false,
                keepFirstVisibleRowComplete: true,
                statusBarVisible: false,
                maxHeight: rowHeight*(nRows+3),
                allowShrinkX:  true,
                allowShrinkY:  true,
                allowGrowX:    true,
                allowStretchX: true,
                allowStretchY: true,
                padding: 10
            });

            table.getDataRowRenderer().setHighlightFocusRow(false);

            var tableColumnModel = table.getTableColumnModel();
            tableModel.setColumnEditable(0, false);
            for (i=1; i<nCols+1; i++) {
                tableModel.setColumnEditable(i, true);
            }

            var tcmb = tableColumnModel.getBehavior();
            tcmb.setWidth(0, 400);
            for (i=1; i<nCols+1; i++) {
                tcmb.setWidth(i, 40);
            }

            table.getSelectionModel().setSelectionMode(qx.ui.table.selection.Model.NO_SELECTION);

            tableModel.setData(data);

            var click_func = function(e) {
	            var row = e.getRow(), col= e.getColumn();
                if (!col) {
                    table.stopEditing();
		            table.getSelectionModel().resetSelection();
                    table.resetCellFocus();
		            this.__xValue.setValue('');
                    this.__yValue.setValue('');
                    return;
                }
                this.__xValue.setValue(this.__options[1][col-1][locale]);
                this.__yValue.setValue(this.__options[0][row][locale]);
                table.startEditing();
            };

            var keypress_func = function(e) {
                var row = table.getFocusedRow();
                var col = table.getFocusedColumn();
                if (col == 0) {
                    table.resetCellFocus();
                    return;
                }
                this.__xValue.setValue(this.__options[1][col-1][locale]);
                this.__yValue.setValue(this.__options[0][row][locale]);
            };

            table.addListener("cellDbltap", click_func, this);
            table.addListener("cellTap",    click_func, this);
            table.addListener("keypress",   keypress_func, this);
            tableModel.addListener("dataChanged", this.__dataChanged_func, this);
            tableBox.add(table);
            return tableBox;
        },

        // TODO: is this needed?
        setData: function(folder, data) {
            console.log('BranchEditor.setData(): folder=', folder, ', data=', data);
        },

        getTableModel: function() {
            return this.__table.getTableModel();
        },

        __dataChanged_func: function(e) {
            var tm = this.__table.getTableModel();
            var data = tm.getData();
            var nCols = tm.getColumnCount(), nRows = tm.getRowCount();
            var rowData, row, col, total = 0;
            for (row=0; row<nRows; row++) { // row=0 is first data row
                rowData = data[row];
                for (col=1; col<nCols; col++) { // col=0 is label column
                    if (rowData[col]) {
                        total += Number(rowData[col]);
                    }
                }
            }
            this.__totalValue.setValue(String(total)+'%');
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
	      * @lint ignoreDeprecated(alert)
          */
        __store_branch_func: function(data, exc, id) {
            if (exc) {
                alert(exc);
            }
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
	      * @lint ignoreDeprecated(alert)
          */
        __storeBranchData: function() {
            this.__table.stopEditing();
            var datasetName = this.__info.getDatasetName() + '';
            var data = [], cData, tData = this.__table.getTableModel().getData();
            var data1 = [];
            var row, col, vars = [], options = {}, total=0;
            var allNull = true;
            for (col=0; col<this.__nCols; col++) {
                cData = [];
                for (row=0; row<this.__nRows; row++) { // row=0 is first data row
                    if (!tData[row][col+1]) {
                        tData[row][col+1] = 0;
                    }
                    else {
                        allNull = false;
                    }
                    total += Number(tData[row][col+1]);
                    cData.push(tData[row][col+1]);
                    data1.push(tData[row][col+1]); // need 1-dimensional array below
                }
                data.push(cData);
            }
            if ( ((total < 99.99) || (total>100.01)) && ! (allNull || (total==0))) {
                qx.event.message.Bus.dispatchByName(
                    'error',
                    [ this.tr("Error"), this.tr("Total must be 100%. Now: ") + total]
                );
                return;
            }

            var regex = /\[(.+)\]/;
            var instance1 = regex.exec(this.__vars[0])[1];
            var instance2 = regex.exec(this.__vars[1])[1];
            vars[0] = this.__vars[0].replace(regex,'[]');
            vars[1] = this.__vars[1].replace(regex,'[]');

            if (instance1 != instance2 || instance1=='' || instance1===null) {
                alert('BranchEditor.__storeBranchData(): this must not happen: instance1/instance2='
                      +instance1+'/'+instance2);
            }
            var i, oLen;
            var voptions = [];
//            var o;
            for (i=0; i<=1; i++) {
                oLen = this.__options[i].length;
//                this.debug('oLen='+oLen);
//                var option, rOptions = [];
//                this.debug('options['+i+'][key]='+this.__options[i]['key']);
//                 for (o=0; o<oLen; o++) {
//                     rOptions.push(this.__options[i][o]);
//                 }
//                 options[vars[i]] = rOptions;
                options[vars[i]] = this.__options[i]['key'];
                voptions.push(this.__options[i]['key']);
                this.__currentFolder.setData(this.__vars[i], 'branched', null, true, data1);
            }
            this.__table.getTableModel().setData(tData);

            var params = {
                datasetName : datasetName,
                data : {
                    instance : instance1,
                    vars :     vars,
                    options :  options,
//                    tdata:     tData,
//                    voptions:  voptions
                    data :     data
                }
            }
            this.__rpc.callAsync(this.__store_branch_func, 'store_branch_data', params);

            // invalidate output on changes and check completeness of data
            qx.event.message.Bus.dispatchByName('agrammon.Output.invalidate');
            qx.event.message.Bus.dispatchByName('agrammon.NavBar.isComplete');
            qx.event.message.Bus.dispatchByName('agrammon.PropTable.update');
            this.close();
        },

        __clearBranchData: function() {
            this.__table.stopEditing();
            var tableModel =  this.__table.getTableModel();
            var row, col;
            for (row=0; row<this.__nRows; row++) {
                for (col=0; col<this.__nCols; col++) {
                    tableModel.setValue(col+1, row, null);
                }
            }
            return;
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
	      * @lint ignoreDeprecated(alert)
          */
        __load_branch_func: function(data, exc, id) {
            if (exc == null) {
                var fractions = data.fractions;
                // no data defined yet
                if (!fractions) {
                    return;
                }
                var row, col, n=0;
                var tm = this.__table.getTableModel();
                for (col=0; col<this.__nCols; col++) {
                    for (row=0; row<this.__nRows; row++) {
                        tm.setValue(col+1, row, Number(fractions[n]));
                        n++;
                    }
                }
            }
            else {
                alert(exc);
            }

        },

        /**
          * TODOC
          *
          * @return {var} TODOC
	      * @lint ignoreDeprecated(alert)
          */
        __loadBranchData: function() {
            var datasetName = this.__info.getDatasetName() + '';
            var vars = [];
            var regex = /\[(.+)\]/;
            var instance1 = regex.exec(this.__vars[0])[1];
            var instance2 = regex.exec(this.__vars[1])[1];
            vars[0] = this.__vars[0].replace(regex,'[]');
            vars[1] = this.__vars[1].replace(regex,'[]');
            if (instance1 != instance2 || instance1=='' || instance1===null) {
                alert('BranchEditor.__loadBranchData(): this must not happen: instance1/instance2='
                      +instance1+'/'+instance2);
            }

            this.__rpc.callAsync(
                qx.lang.Function.bind(this.__load_branch_func, this),
                'load_branch_data',
                {
                   datasetName: datasetName,
                   data : { instance: instance1, vars: vars }
                }
            );
            this.close();
        },

        stopEditing: function() {
            this.__table.stopEditing();
            return;
  	    }

    }

});


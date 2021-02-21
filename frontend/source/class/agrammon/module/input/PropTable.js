/*************************************************************************

************************************************************************ */

qx.Class.define('agrammon.module.input.PropTable', {
    extend: qx.ui.container.Composite,

/**
  * TODOC
  *
  * @return {var} TODOC
  * @lint ignoreDeprecated(alert)
*/
    construct: function () {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox());

        this.__rpc  = agrammon.io.remote.Rpc.getInstance();
        this.__info = agrammon.Info.getInstance();

        qx.locale.Manager.getInstance().addListener("changeLocale",
                                                    this.changeLanguage, this);
        qx.event.message.Bus.subscribe('agrammon.PropTable.storeData',
                                       this.__storeData, this);
        qx.event.message.Bus.subscribe('agrammon.PropTable.update',
                                       this.__update, this);
        qx.event.message.Bus.subscribe('agrammon.PropTable.stop',
                                       this.stopEditing, this);
        qx.event.message.Bus.subscribe('agrammon.PropTable.clear',
                                       this.clear, this);

        this.__langHash = { en: 1, de: 2, fr: 3 };
        // cell renderer factory function
        // returns a cell renderer instance
        var propertyCellRendererFactoryFunc = function (cellInfo) {
            var metaData = cellInfo.table.getTableModel().getRowData(cellInfo.row)[7];
            for ( var cmd in metaData ) {
                   switch ( cmd ) {
                   case "type":
                      switch ( metaData.type) {
                      case "float":
                      case "integer":
                      case "percent":
                          return new agrammon.ui.table.cellrenderer.input.Number;
                      case "checkbox":
                          return new agrammon.ui.table.cellrenderer.input.Boolean;
                      case "text":
                          var defaultRenderer = new agrammon.ui.table.cellrenderer.input.Default;
                          return defaultRenderer;
                      default:
                          alert('Unknown metaData.type='+metaData.type);
                      }
                      break;
                  case "options":
                      var renderer = new agrammon.ui.table.cellrenderer.input.Replace;
                      var replaceMap = {};
                      var i=0;
                      metaData['options'].forEach(function(row) {
                          if (row instanceof Array) {
                              var locale = qx.locale.Manager.getInstance().getLocale();
                              locale = locale.replace(/_.+/,'');
                              replaceMap[metaData.optionsLang[i][locale]]=row[2];
                              i++;
                          }
                        });
                      renderer.setReplaceMap(replaceMap);
                      renderer.addReversedReplaceMap();
                      return renderer;
                  }
              }
              alert('PropTable: Does this ever happen?');
        };

        // create the  "meta" cell renderer object
        var propertyCellRendererFactory =
            new qx.ui.table.cellrenderer.Dynamic(propertyCellRendererFactoryFunc);

        // cell editor factory function
        // returns a cellEditorFactory instance based on data in the row itself
        var propertyCellEditorFactoryFunc = function (cellInfo) {
            let metaData   = cellInfo.table.getTableModel().getRowData(cellInfo.row)[7];
            let cellEditor = new agrammon.ui.table.celleditor.FancyTextField;
//            console.log('metaData=', metaData);
            let validators;
            for ( let cmd in metaData ) {
                switch ( cmd ) {
                case "options":
                    let options = metaData.options;
                    let len = options.length;
                    let map = [];
                    for (let i=0; i<len; i++) {
                        var locale = qx.locale.Manager.getInstance().getLocale();
                        locale = locale.replace(/_.+/,'');
                        map.push([
                            metaData.optionsLang[i][locale],
                            options[i][1],
                            options[i][2]
                        ]);
                    }
                    cellEditor = new qx.ui.table.celleditor.SelectBox();
                    cellEditor.setListData( map );
                    break;
                case "optionsLang":
                    break;
                case "type":
                    switch ( metaData.type ) {
                    case "checkbox":
                        cellEditor = new qx.ui.table.celleditor.CheckBox;
                        break;
                    }
                    break;
                case "editable":
                    cellEditor.setEditable( metaData.editable == true );
                    break;
                case "validator":   // handled in validation generator below
                    if ( Object.keys(metaData.validator).length > 0) {
                        validators = [metaData.validator];
                    }
                    break;
                case "branch":
                case "branches":
                    break;
                default:
                    alert("This should not happen: unknown metaData value: "+cmd);
                    break;
                }
            }
            cellEditor.setValidationFunction(
                (agrammon.util.Validators.getFunction(validators, metaData.type))
            );
            return cellEditor;
        };

        // create a "meta" cell editor object
        var propertyCellEditorFactory =
            new qx.ui.table.celleditor.Dynamic(propertyCellEditorFactoryFunc);

        this.__commentEditor = agrammon.module.input.VariableComment.getInstance();

        // create table
        var propertyEditor_tableModel = new qx.ui.table.model.Simple();
        propertyEditor_tableModel.setColumns(
            [
             this.tr("Variable"),                //  0, variable name
             this.tr("Input Parameter"),         //  1, en
             this.tr("Eingabe-Parameter"),       //  2, de
             this.tr("Paramètre d'entrée"),      //  3, fr
             this.tr("Input Parameter"),         //  4, (current locale)
             this.tr("Click to edit"),           //  5, value
             this.tr("Unit"),                    //  6, unit
             "Meta",                             //  7, meta data
             "Variable type",                    //  8, data type
             this.tr("Help"),                    //  9, help icon
             this.tr("Help func"),               // 10, help function
             this.tr("Unit English"),            // 11, english unit
             this.tr("Unit German"),             // 12, german unit
             this.tr("Unit French"),             // 13, french unit
             this.tr("Comment"),                 // 14, comment
             this.tr("Order"),                   // 15, order
             this.tr("Default")                  // 16, defaultValue
            ]);
        this.__valueColumn   =  5;
        this.__helpColumn    =  9;
        this.__commentColumn = 14;
        this.__orderColumn   = 15;
        this.__defaultColumn = 16;

        var resizeBehaviour = { tableColumnModel:
            function(obj) {
               return new qx.ui.table.columnmodel.Resize(obj);
            }
        };
        var propertyEditor =
            new qx.ui.table.Table(propertyEditor_tableModel,
                                  resizeBehaviour);

        this.__propertyEditor = propertyEditor;
        propertyEditor_tableModel.addListener("dataChanged",
                                              this.__dataChanged_func, this);
        propertyEditor.addListener("keypress", this.__keypressed, this);

        propertyEditor.setDataRowRenderer(new agrammon.ui.table.rowrenderer.Fancy());

        propertyEditor_tableModel.setColumnEditable(this.__valueColumn, true);
        // layout
        propertyEditor.set({
            columnVisibilityButtonVisible: true,
            keepFirstVisibleRowComplete: true,
            statusBarVisible: true,
            showCellFocusIndicator: true,
            focusable: true,
            padding: 0
        });
        // make debugging easier
        if ((qx.core.Environment.get("qx.debug"))) {
            propertyEditor.setColumnVisibilityButtonVisible(true);
        }

        propertyEditor.getDataRowRenderer().setHighlightFocusRow(true);

        // selection mode
        propertyEditor.getSelectionModel().setSelectionMode(qx.ui.table.selection.Model.SINGLE_SELECTION);

        var tcm = propertyEditor.getTableColumnModel();

        // 0th column is invisible, has variable name
        tcm.setColumnVisible(0,false); // initially invisible
        tcm.getBehavior().setWidth(0, 100);

        // 1st column has the english label
        tcm.getBehavior().setWidth(1,'1*');
        tcm.setColumnVisible(1,false); // initially visible

        // 2nd column has the german label
        tcm.getBehavior().setWidth(2,'1*');
        tcm.setColumnVisible(2,false); // initially invisible

        // 3rd column has the french label
        tcm.getBehavior().setWidth(3,'1*');
        tcm.setColumnVisible(3,false); // initially invisible

        // 4th column has current locale
        tcm.getBehavior().setWidth(4,'1*');
        tcm.setColumnVisible(4,true); // initially invisible
        tcm.setDataCellRenderer(4, new agrammon.ui.table.cellrenderer.input.Label);

        // 5th column for editing the value
        // has special cell renderers and cell editors
        tcm.getBehavior().setWidth(this.__valueColumn, 250);
        tcm.setDataCellRenderer(this.__valueColumn,  propertyCellRendererFactory);
        tcm.setCellEditorFactory(this.__valueColumn, propertyCellEditorFactory);

        // 6th column has the unit
        tcm.setColumnVisible(6,true); // initially visible
        tcm.getBehavior().setWidth(6, 100);

        // 7th column has the metadata
        tcm.setColumnVisible(7,false); // initially invisible

        // 8th column has the variable type
        tcm.setColumnVisible(8,false); // initially invisible

        // 9th column is visible, has help icon
        tcm.setColumnVisible(this.__helpColumn,true); // initially visible
        var imageRenderer = new qx.ui.table.cellrenderer.Image(12,12);

        tcm.setDataCellRenderer(this.__helpColumn, imageRenderer);
        tcm.getBehavior().setWidth(this.__helpColumn,40);

        // 10th column has the help function
        tcm.getBehavior().setWidth(10, 100);
        tcm.setColumnVisible(10,false); // initially invisible

        // 11th column has the english unit
        tcm.setColumnVisible(11,false); // initially invisible

        // 12th column has the german unit
        tcm.setColumnVisible(12,false); // initially invisible

        // 13th column has the french unit
        tcm.setColumnVisible(13,false); // initially invisible

        // 14th column has user comment
        tcm.getBehavior().setWidth(this.__commentColumn,70);
        tcm.setDataCellRenderer(this.__commentColumn,
                                new agrammon.ui.table.cellrenderer.Comment(25,16));

        // 15th column has the sort order
        tcm.setColumnVisible(15,true); // initially invisible
        tcm.getBehavior().setWidth(this.__orderColumn, 100);

        // 16th column has the default value
        tcm.setColumnVisible(16,false); // initially invisible
        tcm.getBehavior().setWidth(this.__defaultColumn, 100);

        var tm = propertyEditor.getTableModel();
        for (var col=0; col<this.__orderColumn; col++) {
            tm.setColumnSortable(col, false);
        }

        propertyEditor.addListener("cellDbltap", this.__click_func, this);
        propertyEditor.addListener("cellTap",    this.__click_func, this);

        this.add(propertyEditor, { flex : 1 });
        this.__commentEditor.init(propertyEditor, this.__commentColumn);

    }, // construct

    members :
    {
        __currentFolder:  null,
        __langHash:       null,
        __rpc:            null,
        __info:           null,
        __valueColumn:    null,
        __helpColumn:     null,
        __commentColumn:  null,
        __commentEditor:  null,
        __orderColumn:    null,
        __defaultColumn:  null,
        __propertyEditor: null,

        setData: function(folder, data) {

            // FIX: filter ignore parameters
            var newData = new Array;
            var i, rec;
            var len;
            len = data.length;
            for (i=0; i<len; i++) {
                rec = new Array;
                if (! data[i].getName().match(/::ignore$/)) {
                    if (data[i].getShow()) {
                        rec = data[i].getRow();
                        newData.push(rec);
                    }
                }
            }

            this.__currentFolder = folder;
            this.__propertyEditor.stopEditing();
            var tableModel = this.__propertyEditor.getTableModel();
            // FIX ME: this is called very often on language change
            // remove event listener before bulk table update
//            this.debug('Removing dataChanged listener');
            tableModel.removeListener("dataChanged", this.__dataChanged_func, this);
            tableModel.setData(newData);
            this.sort();

            // enable event handler for user changes to table data
            tableModel.addListener("dataChanged", this.__dataChanged_func, this);
            qx.event.message.Bus.dispatchByName('agrammon.Output.invalidate');
        },

        __dataChanged_func: function(e) {
            if ( ! (e instanceof qx.event.type.Data) ) {
                return;
            }
            var data = e.getData();
            // which variable/line changed
            var fC   = data['firstColumn'];
            var fR   = data['firstRow'];
            if (fC == 0 && fR == 0) { // seems to happen when new instance is created
                return;
            }
            var tableModel = this.__propertyEditor.getTableModel();
            var varname = tableModel.getValue(0, fR);
            var value   = tableModel.getValue(this.__valueColumn, fR);
            var comment = tableModel.getValue(this.__commentColumn, fR);
            if (value != null) {
                value = '' + value;
                if (value.match(/en:(.+)/)) {
                    value = RegExp.$1;
                }
            }
            var datasetName = this.__info.getDatasetName() + '';

            // update navFolder data
            this.__currentFolder.setData(varname, value, comment);

            // FIX ME: combine value/column storage here instead of doing it in VariableComment.js
            if (fC != this.__valueColumn) {
                return;
            }
            // store data in database
            this.__rpc.callAsync(
                this.__store_data_func,
                'store_data',
                {
                    datasetName: datasetName,
                    variable:    varname,
                    value:       value,
                    row:         fR
                }
            );
            qx.event.message.Bus.dispatchByName('agrammon.Output.invalidate');

        },  // data_changed_func()

        /**
          * TODOC
          *
          * @return {var} TODOC
          * @lint ignoreDeprecated(alert)
          */
        __store_data_func: function(data, exc, id) {
            if (exc == null) {
                qx.event.message.Bus.dispatchByName('agrammon.Output.reCalc');
            }
            else {
                alert(exc + ': ' + data.error);
            }

        },

        clear: function() {
            this.setData(null, new Array);
            return;
          },

        stopEditing: function() {
            this.__propertyEditor.stopEditing();
            return;
          },

        sort: function() {
            this.__propertyEditor.getTableModel().sortByColumn(15, true);
        },

        resetCellFocus: function() {
            this.__propertyEditor.resetCellFocus();
            return;
          },

        __update: function() {
            if (this.__currentFolder != null) {
                this.setData(this.__currentFolder,
                             this.__currentFolder.getDataset());
                this.sort();
            }
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
          * @lint ignoreDeprecated(alert)
          */
        changeLanguage: function() {
            // FIX ME: deal with sub locales
            var locale = qx.locale.Manager.getInstance().getLocale();
            locale = locale.replace(/_.+/,'');
            var tableModel = this.__propertyEditor.getTableModel();
            var data = tableModel.getData();
            var lang = this.__langHash[locale];
            if (lang == undefined) {
                alert('Unknown locale='+locale);
                return;
            }
            var i, len = data.length;
            for (i=0; i<len; i++) {
                data[i][4] = data[i][lang];
                data[i][6] = data[i][10+lang];
            }
            tableModel.setData(data);
            this.sort();
            return;
        }, // __changeLanguage

        __keypressed: function(e) {
            var key   = e.getKeyIdentifier();
            var row   = this.__propertyEditor.getFocusedRow();
            var col   = this.__propertyEditor.getFocusedColumn();
            var tm    = this.__propertyEditor.getTableModel();
            var val   = tm.getValue(col,row);
            var nrows = tm.getRowCount();
            // jump over flattened and branched variables, handling table ends
            var dir;
            while (val == 'flattened' || val == 'branched') {
                this.__propertyEditor.cancelEditing();
                switch (key) {
                case 'Enter':
                case 'Down':
                    if (row == (nrows-1)) {
                        key = 'Up';
                        dir = -1;
                    }
                    else {
                        dir = 1;
                    }
                    break;
                case 'Up':
                    if (row == 0) {
                        key = 'Down';
                        dir = 1;
                    }
                    else {
                        dir = -1;
                    }
                    break;
                }
                row += dir;
                this.__propertyEditor.setFocusedCell(col,row,true);
                val   = tm.getValue(col,row);
            }
        },

        __storeData: function(msg) {
            var data = msg.getData();
            var varName  = data['var'];
            var value    = data.value;
            var branches = data.branches;
            var options  = data.options;
            if (value == '*** Select ***' || value == '***Select***') {
                return;
            }
            var datasetName = this.__info.getDatasetName();

            this.__rpc.callAsync(
                this.__store_data_func,
                'store_data',
                {
                    datasetName: datasetName,
                    variable:    varName,
                    value:       value,
                    branches:    branches,
                    options:     options
                }
            );
        },

        __click_func: function(e) {
            var row = e.getRow();
            var col = e.getColumn();

            var tm = this.__propertyEditor.getTableModel();
            if (col == this.__commentColumn ) {
                var varName = tm.getValue(4, row);
                this.__commentEditor.open(varName);
                return;
            }

            if (col == this.__helpColumn ) {
                var data = {
                    caption:  tm.getValue(0,row),
                    helpText: (tm.getValue(this.__helpColumn+1,row))()
                };
                qx.event.message.Bus.dispatchByName('help', data);
                return;
            }

            var value = tm.getValue(this.__valueColumn, row);

            // BEGIN Regional Model
            if (value == 'flattened') {
                // FIX ME: this shouldn't even start editing in dblClick ...
                this.__propertyEditor.cancelEditing();
                return;
            }

            if (value == 'branched') {
                var i, j, len = tm.getRowCount();
                var metaData, opt=[], vars = [], labels = [], options = [];
                for (i=0; i<len; i++) {
                    if (tm.getValue(this.__valueColumn, i) == 'branched') {
                        metaData = tm.getValue(7, i);
                        // get the option keys and add to optionLang hash
                        opt = [];
                        for (j=0; j<metaData.options.length; j++) {
                            opt.push(metaData.options[j][0]);
                        }
                        metaData.optionsLang['key'] = opt;
                        options.push(metaData.optionsLang);
                        labels.push(tm.getValue(4, i));
                        vars.push(tm.getValue(0, i));
                    }
                }
                var branchEditor = new agrammon.module.input.regional.BranchEditor(
                    vars, labels, options,
                    this.__currentFolder
                );
                branchEditor.open();
                return;
            }
            // END Regional Model

            this.__propertyEditor.setFocusedCell(this.__valueColumn, row, true);
            this.__propertyEditor.startEditing();
        } // click_func

    }

});

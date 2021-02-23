// ä
/* ************************************************************************

************************************************************************ */

qx.Class.define('agrammon.module.input.regional.ConfigEditor', {
    extend: qx.ui.container.Composite,

    construct: function () {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox());

        this.__rpc  = agrammon.io.remote.Rpc.getInstance();
        this.__info = agrammon.Info.getInstance();

        this.currentFolder = null;

        var layout = new qx.ui.layout.Grid(20, 5);
        layout.setColumnAlign(0, 'left',   'middle');
        layout.setColumnAlign(1, 'center', 'middle');
        layout.setColumnAlign(2, 'center', 'middle');
        layout.setColumnAlign(3, 'center', 'middle');

        var inputLabel = new qx.ui.basic.Label(this.tr("Input Parameter"));

        this.__grid = new qx.ui.container.Composite(layout);
        this.__grid.add(inputLabel,                                {row: 0, column: 0});
        this.__grid.add(new qx.ui.basic.Label(this.tr("Simple")),  {row: 0, column: 1});
        this.__grid.add(new qx.ui.basic.Label(this.tr("Flatten")), {row: 0, column: 2});
        this.__grid.add(new qx.ui.basic.Label(this.tr("Branch")),  {row: 0, column: 3});

        this.add(this.__grid);

    }, // construct

    members :
    {
        __grid: null,
        __data: null,
        __rpc:  null,
        __info: null,

        setData: function(folder) {
            var data = folder.getDataset();
            // FIX: filter ignore parameters
            var newData = new Array;
            var i, rec;
            var len;
            len = data.length;
            var row=1;
            for (i=0; i<len; i++) {
                rec = data[i].getBranchRow();
                newData.push(rec);
                if (! data[i].getName().match(/::ignore$/)
                    && data[i].getMetaData()['options']
                    // Flattening/branching with only one option doesn't make sense.
                    // This eliminates dummy select boxes used for filtering like animalcategory.
                    && data[i].getMetaData()['options'].length > 1
                    // TODO: remove
                    && data[i].getShow()
                   ) {
                    this.__grid.add(new qx.ui.basic.Label(rec[4]), {column: 0, row: row});
                    var rg = new qx.ui.form.RadioGroup();
                    var srb = new qx.ui.form.RadioButton();
                    srb.setUserData('row', i);
                    var brb = new qx.ui.form.RadioButton();
                    brb.setUserData('row', i);
                    var frb = new qx.ui.form.RadioButton();
                    frb.setUserData('row', i);
                    rg.add(srb, frb, brb);
                    srb.addListener("changeValue", function(e) {
                        var index = e.getTarget().getUserData('row');
                        if (e.getData()) {
                            this.__data[index][9]  = false;
                            this.__data[index][10] = false;
                        }
                    }, this);
                    brb.addListener("changeValue", function(e) {
                        var index = e.getTarget().getUserData('row');
                        if (e.getData()) {
                            this.__data[index][9] = true;
                            this.__data[index][10]  = false;
                        }
                    }, this);
                    frb.addListener("changeValue", function(e) {
                        var index = e.getTarget().getUserData('row');
                        if (e.getData()) {
                            this.__data[index][9]  = false;
                            this.__data[index][10] = true;
                        }
                    }, this);
                    this.__grid.add(srb, {column: 1, row: row});
                    this.__grid.add(frb, {column: 2, row: row});
                    this.__grid.add(brb, {column: 3, row: row});
                    row++;
                }
            }
            this.__data = newData;
        },

        getData: function() {
            return this.__data;
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
	      * @lint ignoreDeprecated(alert)
          */
        __store_data_func: function(data, exc, id) {
            if (exc != null) {
                alert(exc + ': ' + data.error);
            }

        },

	    __storeData: function(msg) {
            var data = msg.getData();
            var varName = data['var'];
            var value   = data['value'];
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
                    row:         -1
                }
            );
	    },

        __update: function() {
            if (this.currentFolder != null) {
                this.setData(this.currentFolder, this.currentFolder.getDataset());
            }
        },

        __navbar: null,

        setNavbar : function(navbar) {
  	        this.__navbar = navbar;
        }

    }

});


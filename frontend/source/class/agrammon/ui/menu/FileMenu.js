/* ************************************************************************

************************************************************************ */

qx.Class.define('agrammon.ui.menu.FileMenu', {
    extend: qx.ui.menu.Menu,

    construct: function () {
        this.base(arguments);

        this.__info = agrammon.Info.getInstance();
        this.__rpc  = agrammon.io.remote.Rpc.getInstance();
        var that=this;

        qx.event.message.Bus.subscribe('agrammon.FileMenu.cloneDataset',
                                        this.__cloneDataset, this);
        qx.event.message.Bus.subscribe('agrammon.FileMenu.copyDataset',
                                        this.__copyDataset, this);
        qx.event.message.Bus.subscribe('agrammon.FileMenu.createDataset',
                                        this.__createDataset, this);
        qx.event.message.Bus.subscribe('agrammon.FileMenu.openConnect',
                                        this.__openConnect, this);
        qx.event.message.Bus.subscribe('agrammon.FileMenu.openNew',
                                        this.__openNew, this);
        qx.event.message.Bus.subscribe('agrammon.FileMenu.enableClone',
                                        this.__enableClone, this);
        var setUser = function () {
            that.username = that.__info.getUserName();
        };
        qx.event.message.Bus.subscribe('agrammon.info.setUser', setUser);

        var datasetTool =
            new agrammon.module.dataset.DatasetTool(this.tr("Datasets of")
                                          + ' ' + username);
        // new
        var newCommand = new qx.ui.command.Command();
        newCommand.addListener("execute", function(e) {
//            this.debug('newcommand: this='+this+', that='+ that +', self='+self+', e='+e.getData());
            var datasetTable = e.getData();
            var dialog;
            var okFunction = qx.lang.Function.bind(function(self) {
                var newDatasetName = ''+self.nameField.getValue();
//                this.debug('newcommand/okFunction: this='+this+', self='+self);
                if (self.getDatasetCache().datasetExists(newDatasetName)) {
                    qx.event.message.Bus.dispatchByName('error',
                            [ this.tr("Error"),
                              this.tr("Dataset") + ' ' + newDatasetName
                            + ' ' +this.tr("already exists")]);
                        self.close();
                        return;
                }
                datasetTable=self;
                var selections = datasetTable.getSelectionModel().getSelectedRanges();
                var len = 0;
                if (selections.length) {
                    var row = selections[0]['minIndex'];
                    var oldDatasetName =
                        datasetTable.getTableModel().getValue(0,row,1);
                    len =
                        datasetTable.getTableModel().getValue(2,row,1);
                }
//    alert('old='+oldDatasetName+', new='+newDatasetName+'len='+len);
                if (len>0) {
                    qx.event.message.Bus.dispatchByName('agrammon.FileMenu.copyDataset',
                                                  {'newDataset': newDatasetName,
                                                   'oldDataset': oldDatasetName
                                                  });
                }
                else {
                    // FIX ME: this is a hack to find out if called from file menu button
                    //         or via msg bus from datasettool(s)
                    var connect = this.getCommand != undefined;
                    this.debug('connect='+connect);
                    qx.event.message.Bus.dispatchByName('agrammon.FileMenu.createDataset',
                                                  { dataset: newDatasetName,
                                                    connect: connect});
                }
                self.close();
                return;
            }, datasetTable);

            dialog =
                new agrammon.module.dataset.DatasetCreate(this.tr("Creating new dataset"),
                                                          this.tr("New dataset name"),
                                                          okFunction);
            dialog.open();
            return;
        }, this);
        this.__newCommand = newCommand;

        var newButton =
            new qx.ui.menu.Button(this.tr("Create new dataset"),
                                  null, newCommand);

        // connect
        var connectCommand = new qx.ui.command.Command();
        var username = this.__info.getUserName();
        this.username = username;
        connectCommand.addListener("execute",
            function(e) {
                datasetTool.setMode('connect');
                datasetTool.open();
        }, this);
        var connectButton =
            new qx.ui.menu.Button(this.tr("Connect to dataset"),
                                  null, connectCommand);
        this.connectButton = connectButton;

        // clone
        var cloneCommand = new qx.ui.command.Command();
        cloneCommand.addListener("execute", function(e) {
            var dialog;
            var okFunction = qx.lang.Function.bind(function(self) {
                var oldDatasetName = '';
                var newDatasetName = self.nameField.getValue();
                this.debug('cloneCommand: dataset=' + newDatasetName);
                 qx.event.message.Bus.dispatchByName('agrammon.FileMenu.cloneDataset',
                                                     { 'oldDataset':  oldDatasetName,
                                               		   'newDataset':  newDatasetName});
                 self.close();
                 return;
            }, this);
            dialog = new agrammon.ui.dialog.Dialog(this.tr("Cloning dataset"),
                                            this.tr("New dataset name"),
                                            okFunction, this);
            return;
        }, this);
        var cloneButton =
            new qx.ui.menu.Button(this.tr("Clone dataset"),
                                  null, cloneCommand);
        this.cloneButton = cloneButton;
        cloneButton.setEnabled(false); // initally off

        // set reference dataset
        var setReferenceCommand = new qx.ui.command.Command();
        setReferenceCommand.addListener("execute",
            function(e) {
                datasetTool.setMode('setReference');
                datasetTool.open();
        }, this);
        var setReferenceButton =
            new qx.ui.menu.Button(this.tr("Set reference dataset"),
                                  null, setReferenceCommand);
        this.setReferenceButton = setReferenceButton;

        // clear reference dataset
        var clearReferenceCommand = new qx.ui.command.Command();
        clearReferenceCommand.addListener("execute", function(e) {
            qx.event.message.Bus.dispatchByName('agrammon.info.setReferenceDataset', '-');
            qx.event.message.Bus.dispatchByName('agrammon.Reference.invalidate');
            qx.event.message.Bus.dispatchByName('agrammon.Reports.clear');
            qx.event.message.Bus.dispatchByName('agrammon.Reports.showReference', false);
        }, this);
        var clearReferenceButton =
            new qx.ui.menu.Button(this.tr("Clear reference dataset"),
                                  null, clearReferenceCommand);
        this.clearReferenceButton = clearReferenceButton;

        // dataset tool
        var manageCommand = new qx.ui.command.Command();
        manageCommand.addListener("execute",
            function(e) {
                datasetTool.setMode('all');
                datasetTool.open();
        }, this);
        var manageButton =
            new qx.ui.menu.Button(this.tr("Manage datasets"),
                                  null, manageCommand);

        // logout
        var logoutCommand = new qx.ui.command.Command();
        logoutCommand.addListener("execute",
            function(e) {
                qx.event.message.Bus.dispatchByName('agrammon.main.logout');
         }, this);
        var logoutButton =
            new qx.ui.menu.Button(this.tr("Logout"),
                                  null, logoutCommand);

        this.add(newButton);
        this.add(connectButton);
        this.add(cloneButton);
        this.add(new qx.ui.menu.Separator());
        this.add(setReferenceButton);
        this.add(clearReferenceButton);
        this.add(new qx.ui.menu.Separator());
        this.add(manageButton);
        this.add(new qx.ui.menu.Separator());
        this.add(logoutButton);

        return;

    }, // construct

    members :
    {
        __connectTool: null,
        __info:        null,
        __rpc:         null,
        __newCommand:  null,

        __openConnect: function(msg) {
            this.connectButton.execute();
        },

        __openNew: function(msg) {
//            this.debug('__openNew(): msg='+msg.getData());
            this.__newCommand.execute(msg.getData());
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
	  * @lint ignoreDeprecated(alert)
          */
         __get_input_variables_func: function(data,exc,id) {
            if (exc == null) {
                // alert('Created dataset ' + data);
            }
            else {
                alert('__get_input_variables_funct(): exc='+exc);
            }

        },

        /**
          * TODOC
          *
          * @return {var} TODOC
	  * @lint ignoreDeprecated(alert)
          */
         __createDatasetFunc: function(dataset,exc,id) {
            if (exc == null) {
                // load the newly created dataset
                qx.event.message.Bus.dispatchByName('agrammon.NavBar.loadDataset',   dataset);
                qx.event.message.Bus.dispatchByName('agrammon.DatasetCache.refresh', this.__info.getUserName());
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
         __createDatasetOnlyFunc: function(dataset,exc,id) {
            if (exc == null) {
                // don't load the newly created dataset
                qx.event.message.Bus.dispatchByName('agrammon.DatasetCache.refresh', this.__info.getUserName());
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
         __createDataset: function(msg) {
            var newDataset = msg.getData().dataset;
            var connect    = msg.getData().connect;

            this.debug('__createDataset(): dataset=' + newDataset
                     + ', connect=' + connect
                      );
            if (connect) {
                this.__rpc.callAsync(
                    qx.lang.Function.bind(this.__createDatasetFunc, this),
                    'create_dataset', { name : newDataset }
                );
                this.__rpc.callAsync(
                    qx.lang.Function.bind(this.__get_input_variables_func, this),
                    'get_input_variables');
            }
            else {
                this.__rpc.callAsync(
                    qx.lang.Function.bind(this.__createDatasetOnlyFunc, this),
                    'create_dataset', { name : newDataset }
                );
            }
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
	  * @lint ignoreDeprecated(alert)
          */
         __cloneDatasetFunc: function(data,exc,id) {
//            this.debug('__cloneDatasetFunc() this='+this);

            if (exc == null) {
                var datasetName = data;
                var dataset = new Object;
                dataset['name'] = datasetName;

                qx.event.message.Bus.dispatchByName('agrammon.input.select');
                this.__info.setDatasetName(datasetName);
                qx.event.message.Bus.dispatchByName('agrammon.NavBar.loadDataset',
                                              dataset);
                qx.event.message.Bus.dispatchByName('agrammon.DatasetCache.refresh', this.__info.getUserName());
            }
            else {
                alert(exc);
            }
        },

        __cloneDataset: function(msg) {
            var oldUsername;
            oldUsername = this.__info.getUserName();

            var newUsername = this.__info.getUserName();
            var dataset  = msg.getData();
            var oldDataset = dataset['oldDataset'];
            if (oldDataset == '') {
                oldDataset  = this.__info.getDatasetName();
            }
            var newDataset = dataset['newDataset'];
            this.debug('__cloneDataset(): ' + oldUsername + '/' + oldDataset
                       + ' -> ' + newUsername + '/' + newDataset);
            qx.event.message.Bus.dispatchByName('agrammon.Output.invalidate');
            this.__rpc.callAsync(
                qx.lang.Function.bind(this.__cloneDatasetFunc, this),
                           'clone_dataset',
			               {'oldUsername': oldUsername,
			                'oldDataset':  oldDataset,
                            'newUsername': newUsername,
			                'newDataset':  newDataset}
            );
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
	  * @lint ignoreDeprecated(alert)
          */
         __copyDatasetFunc: function(data,exc,id) {
//            this.debug('__copyDatasetFunc() this='+this);

            if (exc == null) {
                var datasetName = data;
                var dataset = new Object;
                dataset['name'] = datasetName;

                qx.event.message.Bus.dispatchByName('agrammon.DatasetCache.refresh', this.__info.getUserName());
                qx.event.message.Bus.dispatchByName('agrammon.NavBar.loadDataset', dataset);
            }
            else {
                alert(exc);
            }
        },

        __copyDataset: function(msg) {
            var oldUsername = 'default';
            var newUsername = this.__info.getUserName();
            var data  = msg.getData();
            var oldDataset = data['oldDataset'];
            var newDataset = data['newDataset'];
            this.debug('__copyDataset(): ' + oldUsername + '/' + oldDataset
                       + ' -> ' + newUsername + '/' + newDataset);
            qx.event.message.Bus.dispatchByName('agrammon.Output.invalidate');
            this.__rpc.callAsync(
                qx.lang.Function.bind(this.__copyDatasetFunc, this),
                                      'clone_dataset',
			                          { 'oldUsername': oldUsername,
                                        'oldDataset':  oldDataset,
                                        'newUsername': newUsername,
			                            'newDataset':  newDataset }
            );
        },

        __enableClone: function(msg) {
            this.cloneButton.setEnabled(msg.getData());
        }

    }
});

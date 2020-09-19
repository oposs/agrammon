/* ************************************************************************

************************************************************************ */

/**
  * @asset(Agrammon/*)
  */

qx.Class.define('agrammon.module.input.NavBar', {
//    type : "abstract",
    extend: qx.ui.container.Composite,

/**
  * TODOC
  *
  * @return {var} TODOC
  * @lint ignoreDeprecated(alert)
  */
    construct: function (propEditor) {
        qx.Class.include(qx.ui.core.Widget, qx.ui.core.MPlacement);
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox());
        this.setWidth(250);

        this.__rpc  = agrammon.io.remote.Rpc.getInstance();
        this.__info = agrammon.Info.getInstance();

        qx.event.message.Bus.subscribe('agrammon.NavBar.loadDataset',
                                       this.__loadDataset, this);
        qx.event.message.Bus.subscribe('agrammon.NavBar.getInput',
                                       this.__getInput, this);
        qx.event.message.Bus.subscribe('agrammon.NavBar.addFolder',
                                       this.__addFolderHandler, this);
        qx.event.message.Bus.subscribe('agrammon.NavBar.renameInstanceData',
                                        this.__renameInstanceData,this);
        qx.event.message.Bus.subscribe('agrammon.NavBar.deleteInstanceData',
                                        this.__deleteInstanceData,this);
        qx.event.message.Bus.subscribe('agrammon.NavBar.deleteInstance',
                                        this.__deleteInstance,this);
        qx.event.message.Bus.subscribe('agrammon.NavBar.destroyFolder',
                                        this.__destroyFolder, this);
        qx.event.message.Bus.subscribe('agrammon.NavBar.clearTree',
                                        this.__clearTree,this);
        qx.event.message.Bus.subscribe('agrammon.NavBar.isComplete',
                                       this.__isComplete,this);

        this.__rootFolder = new Object; // set in _getInputVariables()
        this.__propEditor = propEditor;
        this.__navHash    = new Object;
        this.__navTree    = new qx.ui.tree.Tree('Agrammon','Agrammon/nh3.png');
        this.__navTree.set({backgroundColor:'white',
                          padding:0,
                          width:200,
                          hideRoot:false //true
                          });
        this.add(this.__navTree, {flex : 1});

        this.__navTree.setDraggable(true);
        this.__navTree.setDroppable(true);

        // Create drag indicator
        var indicator = new qx.ui.core.Widget;
        indicator.setDecorator(new qx.ui.decoration.Decorator().set({
              top : [ 2, "solid", "red" ]
        }));
        indicator.setHeight(0);
        indicator.setOpacity(0.5);
        indicator.setZIndex(100);
        indicator.setLayoutProperties({left: -1000, top: -1000});
        indicator.setDroppable(true);
        this.getApplicationRoot().add(indicator);

        this.__navTree.addListener("dragstart", function(e) {
            e.addAction("move");
            e.addType("qx/tree-items");
            dragSource=null;
            lastTarget=null;
        });

        this.__navTree.addListener("dragend", function(e) {
            // Move indicator away
            this.setDomPosition(-1000, -1000);
        }, indicator);

        this.__navTree.addListener("dragover", function(e) {
            // Stop when the dragging comes from outside
            if (e.getRelatedTarget()) {
              e.preventDefault();
            }
        });

        this.__navTree.addListener("droprequest", function(e) {
            var type = e.getCurrentType();
            var treeFolder = this.getSelection();
            e.addData(type, treeFolder);
        });

        this.__sibblings = [];
        var orderInstances = function() {
            var dataset  = this.__info.getDatasetName();
            this.__rpc.callAsync(this.order_instances_func,
                                 'order_instances',
                                 {
                                   instances:      this.__sibblings,
                                   dataset_name:   dataset
                                 }
                                );
        };

        this.order_instances_func = function(data, exc, id) {
            if (exc == null) {
            }
            else {
                alert(exc);
            }
        };

        var lastTarget;
        var dragSource;
        this.__navTree.addListener("drag", function(e) {
            // FIX ME: can drag/drop be disabled on folder level instead?
            if (! e.getTarget().getSelection()[0].isInstance()) {
                return;
            }

            // event occurred on this folder
            var target = e.getOriginalTarget();

            // remember which folder we started with
            if (dragSource==null) {
                dragSource = target;
            }

            // we are not dealing with a folder
            if (target.classname != dragSource.classname) {
                return;
            }
            // we are getting outside the allowed drag area
            if (target.getParentNavFolder() != dragSource.getParentNavFolder()) {
                return;
            }
            // the target didn't changed
            if (target == lastTarget) {
                return;
            }
//            this.debug('source='+dragSource.getLabels().en);
//            this.debug('target='+target.getLabels().en);

            lastTarget = target;

            // get relative position of source and target
            var children = target.getParent().getChildren();
            var iSource = children.indexOf(dragSource);
            var iTarget = children.indexOf(target);

            // switch indicator off
            if (iTarget==iSource) {
                indicator.setWidth(0);
                return;
            }

            // position and switch indicator on
            var targetCoords = target.getContainerLocation();
            if (iTarget>iSource) {
                indicator.setDomPosition(targetCoords.left, targetCoords.bottom);
            }
            else {
                indicator.setDomPosition(targetCoords.left, targetCoords.top);
            }
            indicator.setWidth(this.__navTree.getLayoutParent().getWidth()-4); // fit to tree

        }, this);

        this.__navTree.addListener("drop", function(e) {
            // FIX ME: can drag/drop be disabled on folder level instead?
            if (! e.getTarget().getSelection()[0].isInstance()) {
                return;
            }

            // nothing was moved
            if (lastTarget == dragSource) {
                return;
            }

            // get source and target folder
            var target = lastTarget;
            var source = dragSource;

            // insert source relativ to target
            var children = target.getParent().getChildren();
            var iSource = children.indexOf(source);
            var iTarget = children.indexOf(target);
            var parentFolder = target.getParentNavFolder();
            if (iSource<iTarget) {
                parentFolder.addAfter(source, target);
            }
            if (iSource>iTarget) {
                parentFolder.addBefore(source, target);
            }

            // save order to database
            var i, len=children.length;
            this.__sibblings = [];
            for (i=0; i<len; i++) {
                this.__sibblings.push(children[i].getName());
            }
            qx.event.message.Bus.dispatchByName('agrammon.NavBar.orderInstances');

        }, this);

        qx.event.message.Bus.subscribe('agrammon.NavBar.orderInstances',
                                       orderInstances, this);


        // make root folder
        var _rootFolder = this.__createNavFolder({en: 'Agrammon',
                                                    de: 'Agrammon',
                                                    fr: 'Agrammon',
                                                    it: 'Agrammon'
                                                    },
                                                    'isRoot', // type
                                                    null,     // data
                                                    'root',   // name
                                                    null      // instanceOrder
                                                   );
        _rootFolder.setIcon('Agrammon/nh3.png');
        this.__rootFolder = _rootFolder;
        this.__navTree.setRoot(_rootFolder);

        this.__clearTree(); // init navHash

        var cmenu = new agrammon.ui.menu.NavMenu(this, this.__info);
        this.__navTree.setContextMenu(cmenu);
        this.__navTree.addListener("contextmenu",
            function(e) {
                var contextMenu = this.getContextMenu();
                // set the image as the opening widget
                contextMenu.setOpener(this);
                contextMenu.show();
            },
            this.__navTree
        );

        var changeSelectionHandler = function(e) {
            var folder = e.getData()[0];
            this.__propEditor.stopEditing();
            this.__propEditor.resetCellFocus();
            if (folder == null) { // can happen while dragging
//                this.debug('changeSelection: folder is null');
                return;
            }
            if (folder.getLabel() == 'Agrammon') { // root
                return;
            }
//            this.debug('changeSelection: '+folder.getLabel() +
//                       ' - ' + folder.getName());
            if (!folder.isInstance() && !folder.isSingleton()) {
                this.__propEditor.clear();
                return;
            }
            this.__propEditor.setData(folder, folder.getDataset());
            // FIX ME: why doesn't that help? Why would it be necessary?
//            this.debug('changeSelection: calling propEditor.changeLanguage()');
//            this.__propEditor.changeLanguage();
        };
        this.changeSelectionHandler = changeSelectionHandler;
        // this.debug('NavBar: cmenu = ' + cmenu);
        this.__navTree.addListener("changeSelection",
                                 changeSelectionHandler, this);
        this.add(this.__navTree);

        var getInputVariablesHandler =
             qx.lang.Function.bind(function(data,exc,id) {
             if (exc == null) {
                 var dataset = data['dataset'];
                 this.debug('getInputVariablesHandler(): dataset='+dataset);
                 // create select menus for results
                 if (data['reports'] != null) {
                     qx.event.message.Bus.dispatchByName('agrammon.Reports.createMenu',
                                                         data['reports']);
                 }
                 if (data['graphs'] != null) {
                     qx.event.message.Bus.dispatchByName('agrammon.Graphs.createMenu',
                                                         data['graphs']);
                 }
                 this.__getInputVariables(data['inputs']); // build NavTree structur

                 if (dataset != null ) {
                     this.debug('getInputVariablesHandler(): loading ' + dataset);
                     this.__rpc.callAsyncSmart(this.loadDatasetHandler,
                                          'load_dataset',
                                               {name : dataset}
                                         );
                 }
            }
            else {
                alert('getInputVariablesHandler:'+exc);
            }
            return;
        }, this);
        this.getInputVariablesHandler = getInputVariablesHandler;

        var loadDatasetHandler =  qx.lang.Function.bind(function(data,exc,id) {
            if (exc == null) {
                this.__loadDatasetFunction(data);
            }
            else {
                alert('loadDatasetHandler:'+exc);
            }
        }, this);
        this.loadDatasetHandler = loadDatasetHandler;

        return this;
    }, // construct

    /**
      * TODOC
      *
      * @return {var} TODOC
      * @ignore(SIBBLING)
      */
    statics :
    {
        validInstanceName: function(child, parent) {
            if (child == undefined || child == '' || child == null) {
                qx.event.message.Bus.dispatchByName('error',
                    [ qx.locale.Manager.tr("Error"),
                      qx.locale.Manager.tr("Instance name must not be empty.")]);
                    return false;
            }

            var sibblings = parent.getChildren();
            var len = sibblings.length;
            var i, sname;
            SIBBLING:
            for (i=0; i<len; i++) {
                sname = sibblings[i].getName();
                if (sname == null) { // FIX ME: why does this happen
                    this.debug('validInstanceName(): sname==null');
                    break SIBBLING;
                }
                else {
                    sname.match(/\[(.+)\]/);
                    sname = RegExp.$1;
                }
                if (child == sname) {
                    qx.event.message.Bus.dispatchByName('error',
                            [ qx.locale.Manager.tr("Error"),
                              qx.locale.Manager.tr("Duplicate instances not allowed")]);
                    return false;
                }
            }
            return true;
        }
    },

    properties :
    {
        variant: { init: null,
                   check: "String"
                 }
    },

    members :
    {
         __rpc:        null,
         __info:       null,
         __navTree:    null,
         __navHash:    null,
         __propEditor: null,
         __rootFolder: null,
         __sibblings:  null,

     /**
       * TODOC
       * @lint ignoreDeprecated(alert)
       */
        __loadDatasetFunction:  function(data) {
            var i, len = data.length;
            var varName, value, branch_values;
            var nset = 0;  // found
            var no   = 0;  // not found
            var folderName, folder, parentName, parentFolder;

            // loop over all variables read in from dataset
            // and create new navHash/propData entries for new instances
            for (i=0; i<len; i++) {
                varName = String(data[i][0]);

                // check if instance is there already, otherwise create it
                if ( varName.match(/(.+\[(.+)\])/) ) { // is instance variable
                    folderName = RegExp.$1;
//                    this.debug('varName=' + varName + ', folderName =' + folderName);

                    // this check is also done in __addEntry()
                    if (! this.__navHash[folderName]) {// not yet defined
                        var newLabel = '[' + RegExp.$2 + ']';

                        folderName.match(/(.+)(\[.+\])/);
                        parentName = RegExp.$1 + '[]';
                        var instanceName = RegExp.$2;
                        if (this.__navHash[parentName] == undefined) {
                            this.debug('_loadDatasetFunction(): folderName='
                                    + folderName + ', parentName=' + parentName
                                    + ', instanceName=' + instanceName);
                        }

                        parentFolder = this.__navHash[parentName]['folder'];
                        var parentLabels = parentFolder.getLabels();
                        var newLabels    = new Object;
                        var key;
                        for (key in parentLabels) {
                            newLabels[key] = parentLabels[key] + instanceName;
                        }

                        var instanceOrder = data[i][2];
                        folder = this.__addEntry(folderName, newLabels, instanceOrder);

                        var newData = parentFolder.cloneDataset(newLabel);
                        folder.setDataset(newData, false, false);
                        qx.event.message.Bus.dispatchByName('agrammon.PropTable.update');
                    }

                }
            }
            // rebuild the navTree from updated navHash
            this.buildTree();

            // loop over all variables read in from dataset again
            // and set propData values;
            // complain about variables in dataset not present in propData
            // (incompatible model/dataset)
            var msg = '';
            var isInstance, instanceName, comment;
            for (i=0; i<len; i++) {
                varName = data[i][0];
                value   = data[i][1];
                comment = data[i][4];
                if (value == 'branched') {
                    branch_values = [];
                    branch_values = data[i][3];
//                    this.debug('_loadDataset(): ' + varName + '=' + value);
//                    this.debug('              branches: ' + branch_values);
                }
                else {
                    branch_values = undefined;
                }

                isInstance = varName.match(/(.+\[(.+)\])/);  // instance variable ?
                if (isInstance != null) {
                    folderName = RegExp.$1; // module name up to instance level
                    instanceName = RegExp.$2;
                }
                else {
                    varName.match(/(.+)::.+/); // full module name without variable name
                    folderName = RegExp.$1;
                    instanceName = '';
                }
                var found = true;
                while ( this.__navHash[folderName] == null ) { // try parent
//                    if (varName.match(/Storage/)) {
//                        this.debug('navHash['+folderName+'] is null');
//                    }
                    found = false;
                    if (folderName.match(/(.+)::.+/)) {
                        folderName = RegExp.$1;
                        found = true;
                        break;
                    }
                }

                if ( this.__navHash[folderName] != null ) {
                    folder = this.__navHash[folderName]['folder'];
                    // FIX ME
                    var noCheck = true;
//                    this.debug('Calling setData('+varName + ',' + value+')');
                    var regex = /(.+)(_flattened\d?\d?_.+)$/;
                    var match = regex.exec(varName);
//                  this.debug('match='+match+' for '+varName);
                    if ( match !== null ) {
                        // this.debug('match.length='+match.length+' for '+varName);
                        // for (m=0; m<match.length; m++) {
                        //     this.debug('Match['+m+'] = '+match[m]);
                        // }
                        var vname = match[1];
                        var fname = match[2];
			if (vname.match(/test/)) {
                            this.debug('flattened variable: '+vname + ' - ' + fname, ', value=', value);
			}
                        var ds = folder.getDataset();
                        var v, vlen=ds.length;
                        for (v=0; v<vlen; v++) {
                            if (vname == ds[v].getName()) {
//                                this.debug('Found master variable: ' + vname);
//                                this.debug('Calling insertData('+varName + ',' + value + ','+v+1+')');
                                folder.insertData(varName, value, noCheck, v+1, fname);
                                break;
                            }
                            // else {
                            //     this.debug('Skipping variable: ' + ds[v].getName());
                            // }
                        }
                    }
                    else if (folder.setData(varName, value, comment, noCheck, branch_values)) {
                        nset++;
                    }
                    else {          // not found
                        this.debug('_loadDatasetFunction(): couldn\'t set '
                                   + varName + '  /  ' + folderName);
//FIX ME: better ask before deleting ...
                        // qx.event.message.Bus.dispatchByName(
                        //    'agrammon.NavBar.deleteInstanceData',
                        //    { pattern: varName,
                        //      instance: instanceName
                        //    }) ;
                        msg = '\t' + msg + varName + '\n';
                        no++;
                    }
                }
                else {
                    this.debug('_loadDatasetFunction(): couldn\'t find folder for '
                               + varName);
                    msg = '\t' + msg + varName + '\n';
                    no++;
               }
            }
//            var all = nset+no;
//            this.debug('_loadDatasetFunction(): set '
//                       + nset + ' variables (' + all + ')');
            if (no != 0) {
                msg = 'No match for ' + no + ' variables:\n'
                      + msg
                    + '\nVariables should be deleted from dataset.';
//                alert(msg);
                this.debug('ERROR: '+msg);
                qx.event.message.Bus.dispatchByName('error', [this.tr("Error"), msg]);
            }
            this.__rootFolder.isComplete(nset);
            // FIX ME: where should this really be
            qx.event.message.Bus.dispatchByName('agrammon.PropTable.clear');
            qx.event.message.Bus.dispatchByName('agrammon.Output.reCalc');
            return;
        },

        __loadDataset: function(msg) { // FIX ME: merge with next function
            var dataset = msg.getData();
            // set datasetLabel
            this.__info.setDatasetName(dataset.name);

            this.debug('__loadDataset(): dataset.name='+dataset.name);
            this.__clearTree();
            qx.event.message.Bus.dispatchByName('agrammon.input.select');
            qx.event.message.Bus.dispatchByName('agrammon.Output.invalidate');
            qx.event.message.Bus.dispatchByName('agrammon.NavBar.getInput', dataset);
            // this.__getInput(dataset);

            return;
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
          * @lint ignoreDeprecated(alert)
          */
        __getInputVariables: function(data) {
            var navFolder;
            var rec, i, len, m, mlen,
                defaultValue, helpFunction,
                metaData;
//            var date = new Date(), runTime, startTime = date.getTime();

            var modelVariant = this.getVariant();
            if (modelVariant == null) {
                alert('This should not happen: modelVariant=null');
                return;
            }
            this.debug('modelVariant='+modelVariant);
            len = data.length;
            for (i=0; i<len; i++) {
                rec = data[i];
                rec.show = true;
                metaData = {};
                if (rec.variable.match(/dilution_parts_water/) ) {
                    console.log('rec=', rec);
                }

                // deal with model variants
                mlen = rec.models.length;
                for (m=0; m<mlen; m++) {
                    var variant = rec.models[m];
                    if (variant && variant != 'all' && variant != modelVariant) {
                        rec.show = false;
                        rec.value = rec.defaults.calc;
                        break; // no need to search further
                    }
                }

                // deal with GUI defaults
                if (rec.defaults.gui) {
                    defaultValue = rec.defaults.gui;
                }
                else {
                    if ( rec.type.match(/enum/) && rec.units.de != '%') { // combobox
//			console.log('rec.units=', rec.units);
                        defaultValue = '*** Select ***';                    }
                    else {
                        defaultValue = null;
                    }
                }

                // make navbar entry
                navFolder = this.__addEntry(String(rec.gui.en), rec.gui);

                // data type detection
                switch (rec.type) {
                case 'float':
                case 'integer':
                case 'percent':
                case 'text':
                    if (rec.variable.match(/dilution_parts_water/) ) {
                        console.log('  scalar reached for rec.type'=rec.type);
                    }
                    metaData.type      = rec.type;
                    metaData.validator = rec.validator;
                    if (rec.branch) {
                        metaData.branch = true;
                        // this.debug('NavBar: Branch variable:' + rec.variable
                        //           + 'branch='+rec.branch);
                    }
		    if (rec.type == 'percent') {
			defaultValue = null;
		    }
                    break;
                case 'boolean':
                    metaData.type = 'checkbox';
                    break;
                case 'comment':
                    break;
                default:
                    if (rec.variable.match(/dilution_parts_water/) ) {
                        console.log('  default reached for rec.type'=rec.type);
                    }
                    if ( rec.type.match(/enum/) ) { // combobox
                        var olen = rec.options.length;
                        for (var o=0; o<olen; o++) {
                            if (rec.options[o] != undefined && rec.options[o][0] == 'ignore') {
                                rec.options.splice(o,1);
                                rec.optionsLang.splice(o,1);
                                this.debug('Removed ignore options');
                            }
                        }
                        metaData.options     = rec.options;
                        metaData.optionsLang = rec.optionsLang;
                    }
                    else {
                        var err = 'This should not happen: unknown variable type=' + rec.type + ' for variable ' + rec.variable;
                        console.log(err);
                        alert(err);
                    }
                    break;
                }
//                if (rec.validator) {
                   helpFunction =
                      agrammon.util.Validators.getHelpFunction(rec.validator, rec.type, rec.help);
//                }
                if (rec.value == undefined) {
                    rec.value = defaultValue;
                }
                // fill propData array
                var variable = new agrammon.module.input.Variable().set({
                    name:         rec.variable,
                    labels:       rec.labels,
                    value:        rec.value,
                    defaultValue: defaultValue,
                    metaData:     metaData,
                    type:         rec.type,
                    units:        rec.units,
                    helpFunction: helpFunction,
                    show:         rec.show,
                    order:        rec.order*100 // FIXME: used?
                });
                navFolder.addData(variable);

                if (!rec.show) { // must create a database record
                    var datasetName = this.__info.getDatasetName();
                    // FIX ME: this is a copy from PropTable
                    if (! rec.variable.match(/\[\]/)) {
                        // this.debug('Adding variable '+rec.variable+' = '+rec.value);
                        this.__rpc.callAsync(this.__store_data_func,
                                             'store_data',
                                             {
                                               dataset_name: datasetName,
                                               data_var:     rec.variable,
                                               data_val:     rec.value
                                             }
                        );
                    }
                }

            }

            this.buildTree();
            this.__rootFolder.setIcon('Agrammon/nh3.png');
            this.__rootFolder.isComplete(0); // set icons
//            runTime = new Date().getTime() - startTime;
//            this.debug('_getInputVariables(): runTime = ' + runTime);
            return;
        }, // __getInputVariables()


        // FIX ME: is is a copy from PropTable
        /**
          * TODOC
          *
          * @return {var} TODOC
          * @lint ignoreDeprecated(alert)
          */
        __store_data_func: function(data, exc, id) {
            if (exc == null) {
//                var text = data;
                //alert('_store_data_func():' + text);
            }
            else {
                alert(exc);
            }

         },

        __getInput: function(msg) {
            var dataset;
            if (msg != '-') {
                dataset = msg.getData();
            }
            else {
                dataset = '';
            }
            this.debug('__getInput(): dataset.name='+dataset.name);
            // next line must be here
            this.__rootFolder.setIcon('Agrammon/nh3-rotate.gif');
            // FIX ME: where should this really be
            qx.event.message.Bus.dispatchByName('agrammon.PropTable.clear');
            this.__rpc.callAsyncSmart( this.getInputVariablesHandler,
                                       'get_input_variables', {name: dataset.name});
            return;
        },

        // create individual tree folders
        __addEntry: function(guiNode, guiLabels, instanceOrder) {
            if (this.__navHash[guiNode]) {// already defined
                return this.__navHash[guiNode]['folder'];
            }

            var isToplevel = ! guiNode.match('::') ;
            var navFolder, parent;
            var instance, folderName, parentName, type;
            var filter;

            // FIX: this assumes no instances on top level!
            if (isToplevel) { // create top level entry
//                this.debug('_addEntry(): topLevel');
                folderName  = guiNode;
                navFolder = this.__createNavFolder(guiLabels, 'isPlain', null,
                                                  folderName, instanceOrder);
                parentName = 'root';
                parent = this.__navHash['root']['folder'];
                this.__addFolder(folderName, navFolder, parent, instanceOrder);
            }
            else { // create sub level entry
                filter = /(.+)\[(.*)\]/;
                var res = filter.exec(guiNode);
                if (res == null) {
                    instance = '';
                }
                else {
                    instance = res[2];
                }
                folderName  = guiNode;
                var instanceMarker = '';
                if (instance == '') { // not an instance
                    filter = /(.+)::(.+)/;
//                    this.debug('_addEntry(): not an instance');
                }
                else {
                    filter = /(.+)\[(.+)\]/;
                    instanceMarker = '[]';
//                    this.debug('_addEntry(): instance='+instance+', res='+res);
                }

                filter.exec(folderName);
                parentName = RegExp.$1 + instanceMarker;

                var fKey;
                var parentLabels = new Object;;
                for (fKey in guiLabels) {
                    filter.exec(guiLabels[fKey]);
                    parentLabels[fKey] = RegExp.$1 + instanceMarker;
                }

                if (! folderName.match(/\[\]/)) { // is instance or singleton
                    if (parentName.match(/\[\]/)) {
                        type = 'isInstance';
                    }
                    else {
                        type = 'isSingleton';
                    }
                }
                else {
                    type = 'canInstance';
                }

                // find parent folder
                if (! this.__navHash[parentName]) {
//                     this.debug('_addEntry(): calling __addEntry again,'
//                                + ' parentName='+parentName
//                                +', parentLabels[de]='+parentLabels['de']);
                    this.__addEntry(parentName, parentLabels, instanceOrder);
                }

                // this.debug('guiLabels[de]='+guiLabels['de']);
                for (fKey in guiLabels) {
                    filter.exec(guiLabels[fKey]);
                    guiLabels[fKey] = RegExp.$2;
                }
                // this.debug('guiLabels[de]='+guiLabels['de']);

                if (this.__navHash[parentName]) {
                    parent = this.__navHash[parentName]['folder'];
                }
                else {
                    parent = 'root';
                }
                navFolder = this.__createNavFolder(guiLabels, type, null,
                                                  folderName, instanceOrder);
                this.__addFolder(folderName, navFolder, parent, instanceOrder);
            } // create sub level entry

            return navFolder;
        }, // __addEntry


        __addFolder: function(entry, navFolder, parentFolder, instanceOrder) {
            // FIX ME: next lines needed???
            var parentFolderName;
            if (parentFolder == null) {
                parentFolderName = 'NULL';
                this.debug('_addFolder(): parentFolder == null');
            }
            else {
                parentFolderName = parentFolder.getName();
            }

            var newEntry = new Object;
            newEntry['folder'] = navFolder;
            newEntry['parent'] = parentFolder;
            newEntry['order'] = instanceOrder;
            this.__navHash[entry] = newEntry;
            navFolder.setParentNavFolder(parentFolder);
            if (parentFolder != null) {
                parentFolder.addChild(navFolder);
            }
            return;
        },

        __addFolderHandler: function(msg) {
            var data = msg.getData();
            var entry = data['entry'];
            var navFolder = data['folder'];
            var parentFolder = data['parent'];
            this.__addFolder(entry, navFolder, parentFolder);
            return;
        },

        getTree: function() {
            return this.__navTree;
        },

        __clearTree: function() {
            this.__propEditor.clear();
            this.__rootFolder.removeAll();

            this.__navHash = new Object;
            var rootEntry = new Object;
            rootEntry['folder'] = this.__rootFolder;
            rootEntry['parent'] = null;
            this.__navHash['root'] = rootEntry;
        },

        buildTree: function() { // create tree from individual folders
            var key, entry, parent, folder;

            for (key in this.__navHash) {
                entry = this.__navHash[key];
                parent = entry['parent'];
                folder = entry['folder'];
//                this.debug('buildTree(): key=' + key +', parent=' + parent);
                if (key != 'root') {
                    parent.add(folder);
                    parent.addChild(folder);
                }
                folder.setOpen(true);
            }
        },

        __deleteInstance: function(msg) {
            var folder = msg.getData();
            this.delInstance(folder);
        },

        __destroyFolder: function(msg) {
            var folder = msg.getData();
            folder.destroy();
        },

        delInstance: function(folder) {
//            this.debug('delInstance(): folder=' + folder);
            var parentFolder = folder.getParentNavFolder();
            var parentName  = parentFolder.getName();
            var folderLabel = folder.getLabel();

            qx.event.message.Bus.dispatchByName(
                'agrammon.NavBar.deleteInstanceData',
                {
                    pattern:  parentName,
                    instance: folderLabel,
                    folder:   folder
                }
            );
            parentFolder.delChild(folder);

            // remove folder from navTree as well
            this.__navTree.removeListener("changeSelection",
                                          this.changeSelectionHandler, this);
            folder.getParent().remove(folder);
            this.__navTree.addListener("changeSelection",
                                     this.changeSelectionHandler, this);
            this.__navTree.setSelection([parentFolder]);
            this.__rootFolder.isComplete();
            return;
        }, // delInstance

        /**
          * TODOC
          *
          * @return {var} TODOC
          * @lint ignoreDeprecated(alert)
          */
        __deleteDataFunc: function(data, exc, id) {
            var folder = this;
            if (exc == null) {
                qx.event.message.Bus.dispatchByName('error',
                    [ qx.locale.Manager.tr("Info"),
                      folder.getName() + ' ' + qx.locale.Manager.tr("deleted.")]);
                qx.event.message.Bus.dispatchByName('agrammon.Output.reCalc');
            }
            else {
                alert(exc);
            }
        },

        __deleteInstanceData: function(msg) {
            var data        = msg.getData();
            var pattern     = data.pattern;
            var instance    = data.instance;
            var folder      = data.folder;
            var datasetName = this.__info.getDatasetName();

            pattern = pattern.replace(/\[.+\]/, '[]');
            // this.debug('_deleteInstanceData(): delete ' + pattern
            //            + ' / ' + instance
            //            + ' from ' + datasetName);

            // delete from database
            this.__rpc.callAsync(
                qx.lang.Function.bind(this.__deleteDataFunc, folder),
                'delete_data', {
                dataset_name: datasetName,
                instance:     instance,
                pattern:      pattern}
            );

            return;
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
          * @lint ignoreDeprecated(alert)
          */
        __renameInstanceFunc: function(data, exc, id) {
            if (exc == null) {
                var msg = data;
                var oldFolder = this;
                // this.debug('_renameInstanceFunc(): oldName=' + oldFolder.getName()
                //          + ', newName=' + msg.getName()
                //          + ', status='+msg.status);
                oldFolder.setName(msg.newName);
            }
            else {
                alert(exc);
            }
        },

        __renameInstanceData: function(msg) {
            var data        = msg.getData();
            var pattern     = data.pattern;
            var newInstance = data.newInstance;
            var oldInstance = data.oldInstance;
            var folder      = data.folder;
            var datasetName = this.__info.getDatasetName();
            // this.debug('_renameInstanceData(): rename ' + pattern
            //             + ' / ' + oldInstance + ' -> ' + newInstance
            //             + ':' + datasetName);

            // rename instance variables in database
            this.__rpc.callAsync(
                qx.lang.Function.bind(this.__renameInstanceFunc, folder),
                'rename_instance', {
                dataset_name: datasetName,
                oldInstance:  oldInstance,
                newInstance:  newInstance,
                pattern:      pattern}
            );

            return;
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
          */
        renInstance: function(oldFolder) {
            var parentFolder = oldFolder.getParentNavFolder();
            var oldLabel     = oldFolder.getLabel();
            var parentName   = parentFolder.getName();
            // this.debug('renInstance('+oldFolder +'): oldLabel = ' + oldLabel);
            // this.debug('renInstance('+oldFolder +'): parentFolder = ' + parentFolder);
            var dialog;

            var okFunction =  qx.lang.Function.bind(function(self) {
                var newLabel = self.nameField.getValue();
                if (!agrammon.module.input.NavBar.validInstanceName(newLabel,
                                                                  parentFolder)) {
                    return;
                }

                qx.event.message.Bus.dispatchByName('agrammon.NavBar.renameInstanceData',
                                              { pattern: parentName,
                                                oldInstance: oldLabel,
                                                newInstance: newLabel,
                                                folder: oldFolder
                                              }
                );
                self.close();
            }, this);

            dialog = new agrammon.ui.dialog.Dialog(this.tr('Rename instance ')
                                                + oldLabel,
                                                this.tr('New name'),
                                                okFunction, this);
            return;
        }, // renInstance

        /**
          * TODOC
          *
          * @return {var} TODOC
          */
        copyInstance: function(treeFolder) {
            var selectedFolder = treeFolder;
            var parentFolder   = selectedFolder.getParentNavFolder();
            var oldLabel       = treeFolder.getLabel();
            var parentName     = parentFolder.getName();
//            this.debug('copyInstance(): treeFolder = ' + oldLabel);
            var dialog;

            var okFunction =  qx.lang.Function.bind(function(self) {
                var newLabel = self.nameField.getValue();
                if (!agrammon.module.input.NavBar.validInstanceName(newLabel,
                                                                    parentFolder)) {
                    return;
                }

                var newLabels = {
                    'en': newLabel,
                    'de': newLabel,
                    'fr': newLabel,
                    'it': newLabel
                };
                var folderName =
                    parentName.replace(/\[\]/, '[' + newLabel + ']');
                var newFolder = this.__createNavFolder(newLabels, 'isInstance',
                                                      null, folderName);
                this.__addFolder(folderName, newFolder, parentFolder);
                newLabel =  '['+newLabel+']';
                var newData = treeFolder.cloneDataset(newLabel);
                newFolder.setDataset(newData, this.__handleIgnore(), true);

                parentFolder.add(newFolder);
                this.__navTree.setSelection([newFolder]);

                self.close();
            }, this);

            dialog = new agrammon.ui.dialog.Dialog(this.tr('Duplicate instance ')
                                                + oldLabel,
                                                this.tr('New name'),
                                                okFunction, this);
            return;
        }, // copyInstance

        getTreeFolder : function (instance) {
            if (instance == null) {
                return null;
            }
//            this.debug('getTreeFolder: instance='+instance)  ;

            if (instance.classname === this.classname) {
                return instance;
            }
            else {
                return this.getTreeFolder(instance.getLayoutParent());
            }
        },

        __isComplete: function() {
            this.__rootFolder.isComplete();
        },

        __createNavFolder: function(labels, type, data, name, instanceOrder) {
            return new agrammon.module.input.NavFolder(labels, type, data, name, instanceOrder);
        },

        __addSingleInstance: function(tree) {
            var parentFolder = tree.getSelection()[0];
            var parentName   = parentFolder.getName();
            var dialog;

            var okFunction =  qx.lang.Function.bind(function(self) {
                var newLabel = self.nameField.getValue();
                if (!agrammon.module.input.NavBar.validInstanceName(newLabel,
                                                                    parentFolder)) {
                    return;
                }

                var newLabels = {
                    'en': newLabel,
                    'de': newLabel,
                    'fr': newLabel,
                    'it': newLabel
                };
                var folderName =
                    parentName.replace(/\[\]/, '[' + newLabel + ']');
//                this.debug('addInstance(): folderName='+folderName);

                var newFolder = this.__createNavFolder(newLabels, 'isInstance', null, folderName);

                // doesn't work because called from FileMenu context
                // this.navBar._addFolder(folderName, newFolder, parentFolder);

                qx.event.message.Bus.dispatchByName('agrammon.NavBar.addFolder',
                                              {'entry' : folderName,
                                               'folder': newFolder,
                                               'parent': parentFolder}
                                              );
                // doesn't work either because called from FileMenu context
                // var newData = this.__copyInstanceData(sourceData, newLabel);

                newLabel =  '['+newLabel+']';
                var newData = parentFolder.cloneDataset(newLabel);
//                newFolder.setDataset(newData, true, false);
                newFolder.setDataset(newData, true, true);
                parentFolder.add(newFolder);
                parentFolder.setOpen(true);
                this.__navTree.setSelection([newFolder]);
                this.__rootFolder.isComplete();

                dialog.close();
            }, this); // okFunction

//            this.debug('addInstance(): this = ' + this);
            dialog = new agrammon.ui.dialog.Dialog(this.tr('Add instance'),
                                             'Name',
                                             okFunction, this);
            return;
        }, // addSingleInstance()

        __addRegionalInstance: function(tree) {
            var parentFolder = tree.getSelection()[0];
            var parentName   = parentFolder.getName();

            var configEditor = new agrammon.module.input.regional.ConfigEditor();
            var branchWindow =
                new agrammon.module.input.regional.ConfigInstance(configEditor, tree,
                                                       parentName, parentFolder,
                                                       this.__rootFolder);
            branchWindow.open();
            configEditor.setData(parentFolder);

            return;
        }, // addRegionalInstance()

        /**
          * TODOC
          *
          * @return {var} TODOC
          * @lint ignoreDeprecated(alert)
          */
        addInstance: function(tree) {
            var variant = agrammon.Info.getInstance().getGuiVariant();
//            var variant = this.getVariant();
            this.debug('addInstance(): variant='+variant);
            switch (variant) {
            case 'Single':
                this.__addSingleInstance(tree);
                break;
            case 'Regional':
                this.__addRegionalInstance(tree);
                break;
            default:
                alert('Unknown variant ' + variant);
                break;
            }
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
          * @lint ignoreDeprecated(alert)
          */
        __handleIgnore: function() {
            var variant = agrammon.Info.getInstance().getGuiVariant();
//            var variant = this.getVariant();
            this.debug('_handleIgnore(): variant='+variant);
            switch (variant) {
            case 'Single':
                return false;
                break;
            case 'Regional':
                return true;
                break;
            default:
                alert('Unknown variant ' + variant);
                return null;
                break;
            }

        }

    }
});
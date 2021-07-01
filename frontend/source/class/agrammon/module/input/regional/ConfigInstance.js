/* ************************************************************************

************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
 */

qx.Class.define('agrammon.module.input.regional.ConfigInstance', {
    extend: qx.ui.window.Window,

    /**
      * TODOC
      *
      * @return {var} TODOC
      * @ignore(Agrammon)
      * @lint ignoreDeprecated(alert)
      */
    construct: function (configEditor, tree, parentName, parentFolder, rootFolder) {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox());
        this.__navTree = tree;

        var height = qx.bom.Document.getHeight() - 20;
        this.set({ maxHeight: height, modal: true,
                  showClose: true, showMinimize: false, showMaximize: false,
		          caption: this.tr("Configure instance")
                 });
//        this.getChildControl("pane").setBackgroundColor("white");

        var btnCancel =
            new qx.ui.form.Button(this.tr("Cancel"),
                                  "icon/16/actions/dialog-cancel.png");
        btnCancel.addListener("execute", function(e) {
            this.close();
        }, this);

        var instanceName =
             new agrammon.ui.form.VarInput(this.tr("Name"),
                                       null, null,
                                       this.tr("Name of new instance"),
                                       this.tr("Instance name"),
                                       true );

        var okFunction =  qx.lang.Function.bind(function(self) {
            var data = [];
            data = configEditor.getData();
            var i, len=data.length;
//            this.debug('branchInstances(): len='+len);
            var nBranch  = 0;
            var nFlatten = 0;
            for (i=0; i<len; i++) {
                if ( data[i][9] ) {
                    nBranch++;
                }
                if ( data[i][10] ) {
                    nFlatten++;
                }
            }
//            this.debug('Flattening '+nFlatten+' variables');
            var singleBranch = false;
            switch (nBranch) {
            case 1:
                alert('Branching on 1 variable is identical to flattening');
                singleBranch = true;
                break;
            case 0:
            case 2:
//                this.debug('Branching on ' + nBranch + ' variables');
                break;
            default:
                alert('Branching on ' + nBranch
                      + ' (>2) variables not yet supported');
                return;
                break;
            }
            var newLabel = instanceName.getValue();
            if (newLabel == undefined) {
                qx.event.message.Bus.dispatchByName('error',
                    [ this.tr("Error"),
                      this.tr("Instance name must not be empty.")]);
                return;
            }
            if (!agrammon.module.input.NavBar.validInstanceName(newLabel,
                                                              parentFolder)) {
                return;
            }
            var newLabels = { 'en': newLabel,
                              'de': newLabel,
                              'fr': newLabel,
                              'it': newLabel };
            newLabel =  '['+newLabel+']';
//            this.debug('Creating folder ' + newLabel+', len='+len);
            var newData = parentFolder.cloneDataset(newLabel);

            var nData = newData.length;
            for (i=0; i<nData; i++) {
                if (newData[i].getMetaData()['branch']) {
                    this.debug('ConfigInstance: Branch variable:'
                               + newData[i].getName());
                }
            }

            for (i=len-1; i>=0; i--) {
                if ( data[i][9] ) {
                    if (singleBranch) {
                        newData[i].setValue('flattened');
//                        newData[i].setMetaData({type: 'integer'});
//                        data[i][9] = false;
//                        data[i][10] = true;
//                        this.debug('Flattening '+data[i][4]);
                    }
                    else {
//                        this.debug('Branching '+data[i][4]);
                        newData[i].setValue('branched');
                    }
                }
                else if ( data[i][10] ) {
//                    this.debug('Flattening '+data[i][4]);
                    // these are the option keys
                    var options = newData[i].getMetaOptions();
                    // these are the multilingual option labels
                    var optionsLang = newData[i].getMetaOptionsLang();
                    var newVar, o, oo, olen=options.length;
                    oo = -1;
                    for (o=0; o<olen; o++) {
                        // get order of flattened variables right
//                        oo = olen-1-o;
                          oo++;
                        if (oo<10) {
                            oo = '0' + oo;
                        }
                        newVar =
                            newData[i].clone(newData[i].getName()
                                             +'_flattened'+oo+'_'+options[o]);
                        newVar.setLabels({  en: optionsLang[o]['en'],
                                            de: optionsLang[o]['de'],
                                            fr: optionsLang[o]['fr']
                                         });
//                        newVar.setMetaData({type: 'integer'});
                        newVar.setMetaData({type: 'percent'});
                        newVar.setValue(null);
                        newVar.setHelpIcon(null);
                        newVar.setHelpFunction(null);
                        newVar.setUnits({en:'%', de:'%', fr:'%', it:'%'});
                        newData.splice(i+1+o,0,newVar);
                    }
                    newData[i].setValue('flattened');
                    newData[i].setMetaData({type: 'integer'});
                }
            }
            var folderName =
                parentName.replace(/\[\]/, '[' + newLabel + ']');
            var newFolder =
                new agrammon.module.input.NavFolder(newLabels, 'isInstance',
                                                    null, folderName);
            qx.event.message.Bus.dispatchByName('agrammon.NavBar.addFolder',
                                          {'entry' : folderName,
                                           'folder': newFolder,
                                           'parent': parentFolder}
                                         );
            newFolder.setDataset(newData, true, true);
            parentFolder.add(newFolder);
            newFolder.setOpen(true);
            this.__navTree.setSelection([newFolder]);
            rootFolder.isComplete();
            this.close();
        }, this); // okFunction

        var btnOK = new qx.ui.form.Button(this.tr("Ok"),
                                          "icon/16/actions/dialog-ok.png");

        btnOK.addListener("execute", function(e) {
            okFunction(this);
        }, this);

        this.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                btnOK.execute();
            }
        });

        var buttonRow =
            new qx.ui.container.Composite(new qx.ui.layout.HBox(10, 'right'));
        buttonRow.add(instanceName);

        buttonRow.add(btnCancel);
        buttonRow.add(btnOK);
        buttonRow.setPaddingTop(20);

        this.add(configEditor, {flex: 1});
        this.add(buttonRow);

        this.addListener("resize", this.center, this);
        // resize window if browser window size changes
        qx.core.Init.getApplication().getRoot().addListener("resize",
                                                            function () {
            var height = qx.bom.Document.getHeight() - 20;
            this.setMaxHeight(height);
        }, this);

//        this.open();
    }, // construct

    members :
    {
        __navTree: null

// FIXME: is this used anywhere???
//         setData: function(folder, data) {
//             // FIX: filter ignore parameters
//             var newData = new Array;
//             var i, rec;
//             var len;
//             len = data.length;
//             for (i=0; i<len; i++) {
//                 rec = new Array;
//                 if (! data[i].getName().match(/::ignore$/)) {
//                     rec = data[i].getBranchRow();
//                     newData.push(rec);
//                 }
//             }

//             this.currentFolder = folder;
//             this.propertyEditor.stopEditing();
//             var tableModel = this.propertyEditor.getTableModel();
//             // FIX ME: this is called very often on language change
//             // remove event listener before bulk table update
// //            this.debug('Removing dataChanged listener');

//             // FIX ME: this.__dataChanged_func isn't known in this source file !!!
//             tableModel.removeListener("dataChanged",
//                                       this.__dataChanged_func, this);
//             tableModel.setData(newData);
//             len=tableModel.getRowCount();
// //            this.debug('ConfigEditor.setData: len='+len);
//             var meta;
//             for (i=0; i<len; i++) {
//                 meta = tableModel.getValue(7,i);
// //                this.debug(i+': meta='+meta['options']);
//                     tableModel.setValue(9,i,false); // allow branches for none-selects
//                 if (meta['options'] != undefined) {
// //                    tableModel.setValue(14,i,false);
//                     tableModel.setValue(10,i,false);
//                 }
//                 else {
// //                    tableModel.setValue(14,i,undefined);
//                     tableModel.setValue(10,i,undefined);
//                 }
//             }
// //            this.__changeLanguage();
//             // enable event handler for user changes to table data
// //            this.debug('Adding dataChanged listener');
//             tableModel.addListener("dataChanged",
//                                         this.__dataChanged_func,
//                                         this);
//             qx.event.message.Bus.dispatchByName('agrammon.Output.invalidate');
//         }

//         // setSource: function(src) {
//         //     this.docuText.setSource(src);
//         // }

    }
});

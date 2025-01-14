/* ************************************************************************

************************************************************************ */

/**
 @asset(qx/icon/${qx.icontheme}/16/actions/document-save-as.png)
 @asset(qx/icon/${qx.icontheme}/16/actions/document-new.png)
 @asset(qx/icon/${qx.icontheme}/16/actions/window-close.png)
 @asset(qx/icon/${qx.icontheme}/16/actions/go-next.png)
 @asset(qx/icon/${qx.icontheme}/16/actions/go-previous.png)
 @asset(qx/icon/${qx.icontheme}/16/apps/office-database.png)
 @asset(agrammon/tags_ts.png)
 */

qx.Class.define('agrammon.module.dataset.DatasetTool', {
    extend: qx.ui.window.Window,

    /**
      * @ignore(SELECTIONS)
      * @lint ignoreDeprecated(alert)
      */
    construct: function (title) {
        this.base(arguments);
        qx.core.Id.getInstance().register(this, "Datasets");
        this.setQxObjectId("Datasets");
        this.__info = agrammon.Info.getInstance();
        this.__rpc  = agrammon.io.remote.Rpc.getInstance();

        qx.locale.Manager.getInstance().addListener("changeLocale",
                                                    this.__changeLanguage,
                                                    this);

        var maxHeight = qx.bom.Document.getHeight() - 20;
        this.set({
            layout: new qx.ui.layout.VBox(10),
            maxHeight: maxHeight, //allowShrinkY: true,
            modal: true,
            showClose: true, showMinimize: false, showMaximize: false,
            caption: title,
            contentPadding: [0, 0, 10, 0], padding: 0,
            icon: 'icon/16/apps/office-database.png',
            centerOnAppear : true
        });
        this.getChildControl("pane").setBackgroundColor("white");
        var that = this;
        this.__datasetCache = agrammon.module.dataset.DatasetCache.getInstance();

        var datasetTable = this.__datasetTable = agrammon.module.dataset.DatasetTable.getInstance();
        this.addOwnedQxObject(datasetTable, "DatasetTable");

        // might not work in manage dataset mode because updateView
        // is called on datasetTable from availableTagsSelected handler
        datasetTable.addListener("cellDbltap", this.__dblClick_func, this);

        var datasetTm = datasetTable.getTableModel();
        var activeTagsTable = this.__activeTagsTable =
            new agrammon.module.dataset.TagTable(this.tr("Active tags"));
        this.addOwnedQxObject(datasetTable, "ActiveTagsTable");
        var activeTagsTm  = activeTagsTable.getTableModel();
        this.__activeTags = [];
        activeTagsTm.setData(this.__activeTags);

        var availableTagsTable = this.__availableTagsTable =
            new agrammon.module.dataset.TagTable(this.tr("Available tags"));
        this.addOwnedQxObject(datasetTable, "AvailableTagsTable");
        var availableTagsTm  = availableTagsTable.getTableModel();
        this.__availableTags = [];
        availableTagsTm.setData(this.__availableTags);

        // make sure all toolbars are the same height
        this.addListener("appear",  function(e) {
            var userName = this.__info.getUserName();
            qx.event.message.Bus.dispatchByName('agrammon.DatasetCache.refresh', userName);
            var tbHeight = datasetTable.getToolBar().getInnerSize().height;
            this.__tagToolBar.setHeight(tbHeight);
        }, this);

        // This function figures out how many datasets are currently selected.
        //
        // It then calls the function to enable/disable the action buttons.
        //
        // In "manage mode" it also
        //     * updates the activeTagsTable to show all tags that
        //       are assigned to all selected datasets.
        //     * updates the availableTagsTable to only show those tags
        //       that are NOT in the active table.
        //
        var datasetSelected_func = function(e) {
            // for button activation in manage dataset mode
            if (this.__mode == 'all') {
                activeTagsTable.getSelectionModel().fireEvent("changeSelection");
                availableTagsTable.getSelectionModel().fireEvent("changeSelection");
            }
            var datasetSelections = datasetTable.getSelectionModel().getSelectedRanges();
            var nDatasets = 0, nReadonlyDatasets = 0;
            var r, s, min, max;
            var ranges = datasetSelections.length;
            var t, datasetTags, nDatasetTags;
            var tags =  new Object;

            for (r=0; r<ranges; r++) {              // loop over selection ranges
                min = datasetSelections[r]['minIndex'];
                max = datasetSelections[r]['maxIndex'];
                nDatasets += (max - min + 1);           // total number of selections
                for (s = min; s<=max; s++) { // loop over selections
                    if (datasetTm.getValue(3,s,1)) {
                        nReadonlyDatasets++;
                    }

                    datasetTags=datasetTm.getValue(5, s, 1);  // array of tags set for this dataset
                    if (datasetTags) {
                        nDatasetTags=datasetTags.length;

                        // collect all tags of the selected datasets into the tag hash and count them
                        for (t=0; t<nDatasetTags; t++) {
                            if (tags[datasetTags[t]]) {
                                tags[datasetTags[t]]++;
                            }
                            else {
                                tags[datasetTags[t]]=1;
                            }
                        } // t loop
                    } // if (datasetTags)
                }     // s loop
            }         // r loop
            that.__activeTags = [];
            // tags hash now holds the number of occurrences of each tag
            var filter = {};
            var nActiveTags = 0;
                for (t in tags) {
                    if (tags[t] == nDatasets) { // tag is assigned to each selected dataset
                        that.__activeTags.push([ t ]);
                        filter[t] = true;
                        nActiveTags++;
                        delete tags[t]; // remove this element from hash
                    }
                }

            this.enableButtons(nDatasets, nReadonlyDatasets);

            if (this.__mode != 'all') {
                return;
            }
            activeTagsTm.setData([]);
            availableTagsTable.setFilter(filter);
            if (nActiveTags > 0) {
                activeTagsTm.addRows(that.__activeTags);
            }
        };

        // This function figures out which of the available tags are currently selected.
        //
        // In manage datasets it only handles button en/disabling
        //
        // In all other modes it also filters the dataset table and shows only those
        // datasets that are associated with one of the selected tags.
        var availableTagsSelected_func = function(e) {
            availableTagsTable.getSelectionModel().removeListener(
                "changeSelection", availableTagsSelected_func, this
            );
            var tagSelections = availableTagsTable.getSelectionModel().getSelectedRanges();
            var tslen = tagSelections.length;
            var tslen1 = this.__totalTagsSelected(availableTagsTable);
            var tslen2 = this.__totalTagsSelected(activeTagsTable);
            var dsSelections = datasetTable.getSelectionModel().getSelectedRanges();
            var dslen = dsSelections.length;
            if ((tslen1+tslen2)>0) {
                this.__btnDel.setEnabled(true);
            }
            else {
                this.__btnDel.setEnabled(false);
            }
            if (tslen>0 && dslen>0) {
                this.__btnAdd.setEnabled(true);
            }
            else {
                this.__btnAdd.setEnabled(false);
            }
            if ((tslen1+tslen2)==1) {
                this.__btnRename.setEnabled(true);
            }
            else {
                this.__btnRename.setEnabled(false);
            }

                if (this.__mode == 'all') { // no dataset filtering in manage mode
                availableTagsTable.getSelectionModel().addListener(
                    "changeSelection", availableTagsSelected_func, this
                );
                    return;
                }

            var n = 0;
            var i, ii, min, max;
            var tag, tags = [];
            var dsHash = {};
            var alwaysHash = {}; // selected tags must always be shown even if not matching search filter
            var allDS = true;
            if (tslen>0) {
                allDS = false;
              SELECTIONS:
                for (i=0; i<tslen; i++) {  // loop of selection ranges
                    min = tagSelections[i]['minIndex'];
                    max = tagSelections[i]['maxIndex'];
                    n += (max - min + 1);
                    for (ii = min; ii<=max; ii++) { // loop over individual selections
                        tag = availableTagsTm.getValue(0,ii, 1) ;
                        if (tag == '*all*') {
                            allDS = true;
                            break SELECTIONS;
                        }
                        tags.push(tag);
                        alwaysHash[tag] = true;
                    }
                }
            }

            if (allDS) {
                datasetTable.clearFilter();
                availableTagsTable.setShowAlways(alwaysHash);
                availableTagsTable.getSelectionModel().addListener(
                    "changeSelection", availableTagsSelected_func, this
                );
                return;
            }
            if (tags) {
                var tagName, tagHash, allSet, dataset, dsName,
                    dsTags, d, t, tlen=tags.length, dt, dtlen,
                    dlen=that.__datasets.length;
                for (d=0; d<dlen; d++) {
                    dataset = that.__datasets[d];
                    // skip broken records TODO: why?
                    if (!dataset[5]) {
                        continue;
                    }
                    dsName = dataset[0];
                    dsTags = dataset[5];
                    dtlen = dsTags.length;
                    tagHash = {};
                    for (dt=0; dt<dtlen; dt++) {
                        tagName = dsTags[dt];
                        tagHash[tagName] = true;
                    }
                    allSet = true;
                    for (t=0; t<tlen; t++) {
                        tagName = tags[t];
                        allSet = allSet && tagHash[tagName];
                    }
                    if (allSet) {
                        dsHash[dsName] = dataset;
                    }
                }

                datasetTable.setFilter(dsHash);
            }
            else {
                datasetTable.clearFilter();
            }
            availableTagsTable.setShowAlways(alwaysHash);
            availableTagsTable.getSelectionModel().addListener("changeSelection",
                                                               availableTagsSelected_func, this);
        };
        this.__availableTagsSelected_func = availableTagsSelected_func;

        // This only enables/disables the __btnRemove and btnDel buttons.
        var activeTagsSelected_func = function(e) {
            var tagSelections = activeTagsTable.getSelectionModel().getSelectedRanges();
            var tslen = tagSelections.length;
            var tslen1 = this.__totalTagsSelected(availableTagsTable);
            var tslen2 = this.__totalTagsSelected(activeTagsTable);
            var dsSelections = activeTagsTable.getSelectionModel().getSelectedRanges();
            var dslen = dsSelections.length;
            if ((tslen1+tslen2)>0) {
                this.__btnDel.setEnabled(true);
            }
            else {
                this.__btnDel.setEnabled(false);
            }
            if (tslen>0 && dslen>0) {
                this.__btnRemove.setEnabled(true);
            }
            else {
                this.__btnRemove.setEnabled(false);
            }
            if ((tslen1+tslen2)==1) {
                this.__btnRename.setEnabled(true);
            }
            else {
                this.__btnRename.setEnabled(false);
            }
        };

        datasetTable.getSelectionModel().addListener("changeSelection",
                                                     datasetSelected_func, this);
        availableTagsTable.getSelectionModel().addListener("changeSelection",
                                                           availableTagsSelected_func, this);
        activeTagsTable.getSelectionModel().addListener("changeSelection",
                                                        activeTagsSelected_func, this);


        var set_tag_func = function(data,exc,id) {
            if (exc != null) {
                alert(exc + ': ' + data.error);
            }
        }; // set_tags_func()

        var remove_tag_func = function(data,exc,id) {
            if (exc != null) {
                alert(exc + ': ' + data.error);
            }
        }; // remove_tags_func()
        this.__remove_tag_func = remove_tag_func;

        var tagAdd_func = function() {
                var datasetSelections = datasetTable.getSelectionModel().getSelectedRanges();
                var slen = datasetSelections.length;
                if (slen<1) { // no datasets selected
                    return;
                }
                var i, ii, min, max, ds;

            // find datasets selected
            var datasets = [];
            for (i=0; i<slen; i++) {
                min = datasetSelections[i]['minIndex'];
                max = datasetSelections[i]['maxIndex'];
                for (ii = min; ii<=max; ii++) {
                    ds = datasetTm.getValue(0,ii, 1) ;
                    datasets.push(ds);
                }
            }
            if (datasets.length < 1) { // nothing to do
                return;
            }

            var tag;
            var tagSelections = availableTagsTable.getSelectionModel().getSelectedRanges();
            var tlen = tagSelections.length;

            for (i=tlen-1; i>=0; i--) {
                min = tagSelections[i]['minIndex'];
                max = tagSelections[i]['maxIndex'];
                for (ii = max; ii>=min; ii--) {
                    tag = availableTagsTm.getValue(0,ii, 1) ;
                    this.__rpc.callAsync(
                        set_tag_func,
                        'set_tag',
                        { datasets: datasets, tagName: tag }
                    );
                    availableTagsTable.addToFilter(tag, true);
                        activeTagsTm.addRows([[ tag ]]);
                    datasetTable.addTag(datasets, tag);
                }
            }
            activeTagsTm.sortByColumn(0, true);
            availableTagsTable.updateView();
        };


        var tagRemove_func = function() {
            var datasetSelections = datasetTable.getSelectionModel().getSelectedRanges();
            var slen = datasetSelections.length;
            if (slen<1) { // no datasets selected
                return;
            }
            var i, ii, min, max, ds;

            // find datasets selected
            var datasets = [];
            for (i=0; i<slen; i++) {
                min = datasetSelections[i]['minIndex'];
                max = datasetSelections[i]['maxIndex'];
                for (ii = min; ii<=max; ii++) {
                    ds = datasetTm.getValue(0,ii, 1) ;
                            datasets.push(ds);
                }
            }
            if (datasets.length < 1) { // nothing to do
                return;
            }

            var tag;
            var tagSelections = activeTagsTable.getSelectionModel().getSelectedRanges();
            var tlen = tagSelections.length;

            // move backwards through selection to remove correct rows
            for (i=tlen-1; i>=0; i--) {
                min = tagSelections[i]['minIndex'];
                max = tagSelections[i]['maxIndex'];
                for (ii = max; ii>=min; ii--) {
                    tag = activeTagsTm.getValue(0,ii,1) ;
                    this.__rpc.callAsync(
                        this.__remove_tag_func,
                        'remove_tag',
                        { datasets: datasets, tagName: tag }
                    );
                    availableTagsTable.removeFromFilter(tag);
                        activeTagsTm.removeRows(ii,1);
                    datasetTable.removeTag(datasets, tag);
                }
            }
            activeTagsTable.getSelectionModel().resetSelection();
            activeTagsTable.updateView();
            availableTagsTable.updateView();
        };


        availableTagsTable.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                var col = availableTagsTable.getFocusedColumn();
                if (col == 1) {
                    return;
                }
            }
        });

        activeTagsTable.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                var col = activeTagsTable.getFocusedColumn();
                if (col == 1) {
                    return;
                }
            }
        });

        var btnCancel = new qx.ui.form.Button(this.tr("Close"),
                                              "icon/16/actions/window-close.png");
        this.addOwnedQxObject(btnCancel, "CloseButton");
        btnCancel.addListener("execute", function(e) {
            this.__lastDatasetFilter = {'*all*' : true};
            this.close();
        }, this);
        this.__buttonRow =
            new qx.ui.container.Composite(new qx.ui.layout.HBox(10,'right'));
        this.__buttonRow.add(new qx.ui.basic.Label(this.tr("Ctrl-Click on selected table rows removes selection")));
        this.__buttonRow.add(new qx.ui.core.Spacer(1,0), {flex:1});
        this.__buttonRow.setPadding(0,10,0,10);
        this.__buttonRow.add(btnCancel);

        this.__createButtons();


        var splitpane = new qx.ui.splitpane.Pane("horizontal");
        splitpane.set({backgroundColor: 'white', padding:0});
        splitpane.setDecorator(null);

        var datasetColumn = new qx.ui.container.Composite(new qx.ui.layout.VBox(10));
        datasetColumn.setPadding(0); // top right bottom left

        var tagColumn = new qx.ui.container.Composite(new qx.ui.layout.VBox(10));
        tagColumn.setPadding(0); // top right bottom left
        this.__tagColumn = tagColumn;

        this.__tagToolBar = new qx.ui.toolbar.ToolBar();
        this.__tagToolBar.setAllowShrinkY(false);
        this.__tagToolBar.setAllowGrowY(true);
        this.__tagToolBar.setPadding(0, 5, 0, 5);

        tagColumn.add(this.__tagToolBar);
        this.__createTagButtons();
        this.enableButtons(0,0);

        var tagBox = new qx.ui.container.Composite(new qx.ui.layout.HBox(0));

        var btnBox = new qx.ui.container.Composite(new qx.ui.layout.VBox(5));
        this.__btnBox = btnBox;
        btnBox.setPadding(0);
        datasetColumn.add(datasetTable, {flex: 1});
        tagBox.add(availableTagsTable, {flex: 1});
        tagBox.add(btnBox);
        tagBox.add(activeTagsTable, {flex: 1});
        tagColumn.add(tagBox, {flex:1});
        this.__btnAdd = new qx.ui.form.Button(null, 'icon/16/actions/go-next.png');
        this.__btnAdd.addListener("execute", tagAdd_func, this);
        this.__btnAdd.setEnabled(false);
        this.__btnRemove = new qx.ui.form.Button(null, 'icon/16/actions/go-previous.png');
        this.__btnRemove.addListener("execute", tagRemove_func, this);
        this.__btnRemove.setEnabled(false);

        this.addOwnedQxObject(this.__btnAdd, "NewButton");
        this.addOwnedQxObject(this.__btnRemove, "DeleteButton");
        this.addOwnedQxObject(this.__btnCopy, "CopyButton");
        this.addOwnedQxObject(this.__btnOpen, "OpenButton");
        this.addOwnedQxObject(this.__btnSetReference, "SetReferenceButton");
        this.addOwnedQxObject(this.__btnClearReference, "ClearReferenceButton");

        btnBox.add(new qx.ui.core.Spacer(1,60));
        btnBox.add(this.__btnAdd, {flex:1});
        btnBox.add(this.__btnRemove, {flex:1});
        btnBox.add(new qx.ui.core.Spacer(1,10));
        btnBox.exclude();

        splitpane.add(tagColumn, 1);
        if (this.__advancedMode) {
            if (this.__mode == 'all') {
                this.setWidth(this.__ALLWITHTAGS); // larger
            }
            else {
                this.setWidth(this.__WITHTAGS); // smaller
            }
            tagColumn.show();
        }
        else {
            if (this.__mode == 'all') {
                this.setWidth(this.__ALLWITHOUTTAGS); // larger
            }
            else {
                this.setWidth(this.__WITHOUTTAGS); // smaller
            }
            tagColumn.exclude();
        }

        splitpane.add(datasetColumn, 3);
        this.add(splitpane, {flex: 1});
        this.add(this.__buttonRow);

        this.__setDatasets = function() {
            // used for datasetFilter
            that.__datasets = this.__datasetCache.getDatasets();
            if (! that.__datasets) return;
            var len = that.__datasets.length;
            if (len<1) return;

            datasetTm.setData(that.__datasets);
            datasetTable.getSelectionModel().resetSelection();
            datasetTable.updateView();
        };

        this.__clearDatasets = function() {
            datasetTm.setData([]);
        };

        this.addListener("resize", this.center, this);

        this.__setTags = function() {
            var data = this.__datasetCache.getTags();
            if (!data) return;
            var len = data.length;
            if (len<1) {
                return;
            }
            var i, rec;
            that.__availableTags = [];
            for (i=0; i<len; i++) {
                rec = [ data[i] ];
                that.__availableTags.push(rec);
            }
            availableTagsTm.setData(that.__availableTags);
            availableTagsTable.updateView();
        }; // this.__setTags()

        // This updates the table after changes to the datasets (new/delete/rename)
        qx.event.message.Bus.subscribe('Agrammon.datasetsLoaded', function(msg) {
                                           this.__setDatasets();
                                           this.setEnabled(true);
                                       }, this);

        qx.event.message.Bus.subscribe('Agrammon.datasetsLoading', function(msg) {
                                           this.__clearDatasets();
                                           this.setEnabled(false);
                                       }, this);

        qx.event.message.Bus.subscribe('Agrammon.tagsLoaded', function(msg) {
                                           this.__setTags();
                                       }, this);

        this.__setUser = function () {
            that.setCaption(that.tr("Datasets of %1", that.__info.getUserName()));
        };
        qx.event.message.Bus.subscribe('agrammon.info.setUser', this.__setUser);
        this.__setDatasets();

        this.__commentColumn = datasetTable.getCommentColumn();
        this.__commentEditor = agrammon.module.dataset.DatasetComment.getInstance();
        this.__commentEditor.init(datasetTable, this.__commentColumn);

        // resize window if browser window size changes
        qx.core.Init.getApplication().getRoot().addListener(
            "resize",
            function () {
                var height = qx.bom.Document.getHeight() - 20;
                this.setMaxHeight(height);
        }, this);

        this.addListenerOnce('appear', () => {
            this.debug('datasetToolWindowID=', qx.core.Id.getAbsoluteIdOf(this));
            this.debug('datasetTableID=', qx.core.Id.getAbsoluteIdOf(datasetTable));
        }, this);

    }, // construct

    members :
    {
        __ALLWITHTAGS:    1150,
        __ALLWITHOUTTAGS:  950,
        __WITHTAGS:        950,
        __WITHOUTTAGS:     750,
        __commentEditor: null,
        __commentColumn: null,
        __datasetCache: null,
        __datasets: null,
        __activeTags: null,
        __activeTagsTable: null,
        __availableTags: null,
        __availableTagsTable: null,
        __mode: null,
        __advancedMode: false,
        __tagColumn: null,
        __btnAdvanced: null,
        __lastDatasetFilter: {'*all*' : true},
        __btnSetReference: null,
        __btnClearReference: null,
        __btnCopy: null,
        __btnOpen: null,
        __btnNew: null,
        __btnDel: null,
        __btnBox: null,
        __buttonRow: null,
        __datasetTable: null,
        __tagToolBar: null,
        __setDatasets: null,
        __clearDatasets: null,
        __info: null,
        __setUser: null,
        __setTags: null,
        __btnAdd: null,
        __btnRemove: null,
        __rpc: null,
        __btnRename: null,
        __availableTagsSelected_func: null,
        __remove_tag_func: null,

        __totalTagsSelected:  function(table) {
            var tagSelections = table.getSelectionModel().getSelectedRanges();
            var tslen = tagSelections.length;
            var i, min, max, n=0;
            for (i=0; i<tslen; i++) {  // loop of selection ranges
                min = tagSelections[i]['minIndex'];
                max = tagSelections[i]['maxIndex'];
                n += (max - min + 1);
            }
            return n;
        },


        __createButtons: function() {
            this.__btnSetReference   = new qx.ui.form.Button(this.tr("Set reference"), "");
            this.__btnClearReference = new qx.ui.form.Button(this.tr("Clear reference"), "");
            this.__btnCopy = new qx.ui.form.Button(this.tr("Copy+Connect"), "");
            this.__btnOpen = new qx.ui.form.Button(this.tr("Connect"), "");
            this.__buttonRow.add(this.__btnSetReference);
            this.__buttonRow.add(this.__btnClearReference);
            this.__buttonRow.add(this.__btnCopy);
            this.__buttonRow.add(this.__btnOpen);

            this.__btnCopy.addListener("execute", function(e) {
                var data = this.__datasetTable.getSelectionModel().getSelectedRanges();
                var row = data[0]['minIndex'];
                var oldDatasetName = this.__datasetTable.getTableModel().getValue(0,row,1);
                var readOnly       = this.__datasetTable.getTableModel().getValue(3,row,1);
                var dialog;
                var okFunction = qx.lang.Function.bind(function(self) {
                    var newDatasetName = self.nameField.getValue();
                    if (readOnly) {
                        qx.event.message.Bus.dispatchByName(
                            'agrammon.FileMenu.copyDataset',
                            { newDataset : newDatasetName, oldDataset : oldDatasetName }
                        );
                    }
                    else {
                        qx.event.message.Bus.dispatchByName(
                            'agrammon.FileMenu.cloneDataset',
                            { newDataset : newDatasetName, oldDataset : oldDatasetName }
                        );
                    }
                    self.close();
                    this.close();
                }, this);
                dialog = new agrammon.ui.dialog.Dialog(
                    this.tr("Cloning dataset"),
                    this.tr("New dataset name"),
                    oldDatasetName,
                    okFunction,
                    this
                );
                return;
            }, this);

            this.__btnClearReference.addListener("execute", function(e) {
                qx.event.message.Bus.dispatchByName('agrammon.Reports.clear');
                qx.event.message.Bus.dispatchByName('agrammon.info.setReferenceDataset', '-');
                qx.event.message.Bus.dispatchByName('agrammon.Reference.invalidate');
                qx.event.message.Bus.dispatchByName('agrammon.Reports.showReference', false);
            }, this);

            this.__btnSetReference.addListener("execute", function(e) {
                var data =
                    this.__datasetTable.getSelectionModel().getSelectedRanges();
                var row = data[0]['minIndex'];
                var datasetName =
                    this.__datasetTable.getTableModel().getValue(0,row,1);

                qx.event.message.Bus.dispatchByName('agrammon.Reports.clear');
                qx.event.message.Bus.dispatchByName('agrammon.info.setReferenceDataset',
                                                    datasetName);
                qx.event.message.Bus.dispatchByName('agrammon.Reference.invalidate');
                qx.event.message.Bus.dispatchByName('agrammon.Reports.showReference', true);
                this.close();
            }, this);

            this.__btnOpen.addListener("execute", function(e) {
                var sm   = this.__datasetTable.getSelectionModel();
                var data = sm.getSelectedRanges();
                var datasetTm = this.__datasetTable.getTableModel();
                sm.resetSelection();
                var row = data[0]['minIndex'];

                var dataset = {};
                dataset['name']     = datasetTm.getValue(0,row,1);

                qx.event.message.Bus.dispatchByName('agrammon.Reports.clear');
                qx.event.message.Bus.dispatchByName('agrammon.PropTable.clear');
                qx.event.message.Bus.dispatchByName('agrammon.input.select');
                qx.event.message.Bus.dispatchByName('agrammon.NavBar.loadDataset', dataset);
                this.close();
            }, this);

            this.__btnAdvanced = new qx.ui.toolbar.CheckBox();
            this.__btnAdvanced.setIcon('agrammon/tags_ts.png');
            if (this.__advancedMode) {
                 this.__btnAdvanced.setLabel(this.tr("Hide tags"));
            }
            else {
                 this.__btnAdvanced.setLabel(this.tr("Show tags"));
            }
            this.__btnAdvanced.setMarginRight(5);
            this.__btnAdvanced.setPadding(0,5,0,5);
            this.__btnAdvanced.setValue(this.__advancedMode);
            this.__datasetTable.getToolBar().add(new qx.ui.core.Spacer(1,0), {flex:1});
            this.__datasetTable.getToolBar().add(this.__btnAdvanced);

            this.__btnAdvanced.addListener("changeValue", function(e) {
                this.__advancedMode = this.__btnAdvanced.getValue();
                if (this.__advancedMode) {
                    this.__btnAdvanced.setLabel(this.tr("Hide tags"));
                    if (this.__mode == 'all') {
                        this.setWidth(this.__ALLWITHTAGS); // larger
                    }
                    else {
                        this.setWidth(this.__WITHTAGS); // larger
                    }
                    this.__tagColumn.show();
                    this.__datasetTable.setFilter(this.__lastDatasetFilter);
                }
                else {
                    this.__btnAdvanced.setLabel(this.tr("Show tags"));
                    if (this.__mode == 'all') {
                        this.setWidth(this.__ALLWITHOUTTAGS); // smaller
                    }
                    else {
                        this.setWidth(this.__WITHOUTTAGS); // smaller
                    }
                    this.__tagColumn.exclude();
                    this.__lastDatasetFilter = this.__datasetTable.getFilter();
                    this.__datasetTable.clearFilter();
                }
            }, this);
        },

        enableButtons: function(n, nReadonly) {
            switch (n) {
                case 0:
                    this.__btnOpen.setEnabled(false);
                    this.__btnSetReference.setEnabled(false);
                    this.__btnCopy.setEnabled(false);
                    break;
                case 1:
                    if (nReadonly==1) {
                        this.__btnCopy.setEnabled(true);
                        this.__btnSetReference.setEnabled(true);
                        this.__btnOpen.setEnabled(false);
                    }
                    else {
                        this.__btnSetReference.setEnabled(true);
                        this.__btnOpen.setEnabled(true);
                        this.__btnCopy.setEnabled(true);
                    }
                    break;
                default: // >1
                    this.__btnOpen.setEnabled(false);
                    this.__btnSetReference.setEnabled(false);
                    this.__btnCopy.setEnabled(false);
                    break;
            }
            this.__datasetTable.enableButtons(n);
        },

        __dblClick_func: function(e) {
            var row = e.getRow();
            var col = e.getColumn();
            var datasetTm      = this.__datasetTable.getTableModel();
            var datasetName    = datasetTm.getValue(0,row,1);
            var readOnly       = datasetTm.getValue(3,row,1);
            if (col == this.__commentColumn) {
                this.__commentEditor.open(datasetName);
                return;
            }

            if (this.__mode == 'setReference') {
                this.__btnSetReference.execute();
            }
            var sm = this.__datasetTable.getSelectionModel();
            sm.resetSelection();

            if (readOnly) {
                return;
            }
            if (this.__mode == 'connect' || this.__mode == 'all') {
                qx.event.message.Bus.dispatchByName('agrammon.PropTable.clear');
                qx.event.message.Bus.dispatchByName('agrammon.input.select');
                qx.event.message.Bus.dispatchByName('agrammon.NavBar.loadDataset',
                                              {name: datasetName});
            }
            this.close();
        },

        setMode: function(cmd) {
            this.__mode = cmd;
            this.__datasetTable.resetSelection();

            this.__availableTagsTable.getSelectionModel().resetSelection();
            this.__availableTagsTable.clearFilter();
            this.__activeTagsTable.getSelectionModel().resetSelection();
            this.__activeTagsTable.clearFilter();
            this.__datasetTable.clearFilter();

            if (cmd == 'all') {
                this.__availableTagsTable.getSelectionModel().resetSelection();
                this.__availableTagsTable.clearFilter();
                this.__datasetTable.clearFilter();
                if (this.__advancedMode) {
                    this.setWidth(this.__ALLWITHTAGS);
                }
                else {
                    this.setWidth(this.__ALLWITHOUTTAGS);
                }
                this.__btnBox.show();
                var i, len;
                var children = this.__tagToolBar.getChildren();
                len = children.length;
                for (i=0; i<len; i++) {
                    children[i].show();
                }
            }
            else {
                if (this.__advancedMode) {
                    this.setWidth(this.__WITHTAGS);
                }
                else {
                    this.setWidth(this.__WITHOUTTAGS);
                }
                this.__btnBox.exclude();
                var i, len;
                var children = this.__tagToolBar.getChildren();
                len = children.length;
                for (i=0; i<len; i++) {
                    children[i].hide();
                }
            }

            switch (cmd) {
            case 'setReference':
                this.__btnSetReference.show();
                this.__btnClearReference.show();
                this.__btnCopy.exclude();
                this.__btnOpen.exclude();
                this.__activeTagsTable.exclude();
                break;
            case 'connect':
                this.__btnCopy.show();
                this.__btnOpen.show();
                this.__btnSetReference.exclude();
                this.__btnClearReference.exclude();
                this.__activeTagsTable.exclude();
                break;
            case 'clone':
                this.__btnCopy.show();
                this.__btnOpen.exclude();
                this.__activeTagsTable.exclude();
                break;
            case 'create':
                this.__btnCopy.exclude();
                this.__btnOpen.exclude();
                break;
            case 'rename':
                this.__btnCopy.exclude();
                this.__btnOpen.exclude();
                break;
            default:
                this.__btnCopy.show();
                this.__btnOpen.show();
                this.__btnSetReference.exclude();
                this.__btnClearReference.exclude();
                this.__activeTagsTable.show();
                break;
            }
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
          * @lint ignoreDeprecated(alert)
          */
         __delete_tag_func: function(data,exc,id) {
            if (exc) {
                alert(exc + ': ' + data.error);
            }
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
              * @lint ignoreDeprecated(alert)
          */
         __rename_tag_func: function(data,exc,id) {
            console.log('rename_tag_func', data, exc, id);
            if (exc) {
                alert(exc);
            }
        },

        __createTagButtons: function() {
            this.__btnRename = new qx.ui.toolbar.Button(this.tr('Rename'),
                                                                'icon/16/actions/document-save-as.png');
            this.__btnNew = new qx.ui.toolbar.Button(this.tr('New'),
                                                     'icon/16/actions/document-new.png');
            this.__btnDel = new qx.ui.toolbar.Button(this.tr('Delete'),
                                                             'icon/16/actions/window-close.png');
            this.__btnDel.setEnabled(false);
            this.__btnRename.setEnabled(false);
            this.__tagToolBar.add(this.__btnRename);
            this.__tagToolBar.add(this.__btnNew);
            this.__tagToolBar.add(this.__btnDel);
            this.__btnRename.addListener("execute", function(e) {
                var dialog;
                var table;
                // only one of the two tag tables can have a selection if rename is called
                if (this.__totalTagsSelected(this.__activeTagsTable)) {
                    table = this.__activeTagsTable;
                }
                else {
                    table = this.__availableTagsTable;
                }
                var data = table.getSelectionModel().getSelectedRanges();
                var row = data[0]['minIndex'];
                var tm = table.getTableModel();
                var tag_old = tm.getValue(0, row, 1);
                console.log('tag_old=', tag_old);
                var okFunction = qx.lang.Function.bind(function(self) {
                    var tag_new = self.nameField.getValue();
                    console.log('tag_new=', tag_new);
                    if (this.__datasetCache.tagExists(tag_new)) {
                        qx.event.message.Bus.dispatchByName('error', [
                            this.tr('Error'),
                            this.tr('Tag %1 already exists', tag_new)
                        ]);
                        self.close();
                        return;
                    }
                    console.log('tag_new=', tag_new);
                    tm.setValue(0, row, tag_new, 1);

                    console.log('calling renameTag on __availableTagsTable=', this.__availableTagsTable);
                    this.__availableTagsTable.renameTag(tag_old, tag_new);
                    console.log('calling __datasetTable.renameTag');
                    this.__datasetTable.renameTag(tag_old, tag_new);
                    console.log('calling async rename_tag');
                    this.__rpc.callAsync(
                        qx.lang.Function.bind(this.__rename_tag_func,this),
                        'rename_tag',
                        {
                            oldName: tag_old,
                            newName: tag_new
                        }
                    );
                    self.close();
                }, this);
                dialog = new agrammon.ui.dialog.Dialog(
                        this.tr("Rename tag"),
                        this.tr("New tag name"),
                        tag_old,
                        okFunction, this);
                }, this);

            this.__btnNew.addListener("execute", function(e) {
                var okFunction = qx.lang.Function.bind(function(self) {
                    var tag = self.nameField.getValue();
                    var tm  = this.__availableTagsTable.getTableModel();
                    if (this.__datasetCache.tagExists(tag)) {
                        qx.event.message.Bus.dispatchByName('error',
                            [
                                this.tr("Error"),
                                this.tr("Tag") + ' ' + tag + ' ' + this.tr("already exists")
                            ]
                        );
                        self.close();
                        return;
                    }
                    // FIX ME: should be added by async handler
                    this.__datasetCache.newTag(tag);
                    tm.addRows([[ tag ]]);
                    this.__availableTagsTable.updateView();
                            tm.sortByColumn(0, true);
                    this.__rpc.callAsync(
                        qx.lang.Function.bind(function(data, exc, id) {
                            if (exc != null) {
                                alert(exc + ': ' + data.error);
                            }
                        }, this),
                        'create_tag',
                        { name : tag }
                            );
                    self.close();
                }, this);
                var dialog = new agrammon.ui.dialog.Dialog(
                    this.tr("Creating new tag"),
                    this.tr("New tag name"),
                    null, // value
                    okFunction, this
                );
            }, this);

            // Delete tags selected in availableDatasets from datasets and database.
            // Remove tags selected in activeDatasets from datasets.
            this.__btnDel.addListener("execute", function(e) {
//                this.debug('TagTable.__btnDel()');
                var selections = this.__availableTagsTable.getSelectionModel().getSelectedRanges();
                var availableTagsTm = this.__availableTagsTable.getTableModel();
                var slen = selections.length;
                var dialog;
                var okFunction = qx.lang.Function.bind(function(self) {
                    var i, ii, min, max, tag;
                    var tags = [];
                    for (i=slen-1; i>=0; i--) {
                        min = selections[i]['minIndex'];
                        max = selections[i]['maxIndex'];
                        for (ii = max; ii>=min; ii--) {
                            tag = availableTagsTm.getValue(0,ii,1) ;
                            tags.push(tag);
                            // FIX ME: should be removed by async handler
                            this.__datasetCache.delTag(tag);
                            this.debug('Going to remove line ' + ii);
                            this.__availableTagsTable.getSelectionModel().resetSelection();
                                availableTagsTm.removeRows(ii,1,1);
                            this.debug('Line ' + ii +' removed');
                        }
                    }
                    this.__availableTagsTable.updateView();
                    for (tag in tags) {
                        this.__datasetTable.delTag(tags[tag]);
                        this.__availableTagsTable.delTag(tags[tag]);
                        this.__activeTagsTable.delTag(tags[tag]);
                        this.__rpc.callAsync( qx.lang.Function.bind(this.__delete_tag_func,this),
                                              'delete_tag', { name : tags[tag] }
                                                        );
                    }
                    self.close();
                }, this);
                if (slen>0) {
                    dialog =
                        new agrammon.ui.dialog.Confirm(this.tr("Deleting tags from database"),
                                               this.tr("Really delete selected available tags from database?"),
                                               okFunction, this);
                }
                // handle selected active tags
                this.__btnRemove.fireEvent("execute");
            }, this);

        },

        __changeLanguage: function() {
                var username = agrammon.Info.getInstance().getUserName();
                this.setCaption( this.tr("Datasets of %1", username));
        } // __changeLanguage
    }
});

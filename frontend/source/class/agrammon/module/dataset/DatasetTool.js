/* ************************************************************************

************************************************************************ */

/**
 @asset(qx/icon/${qx.icontheme}/16/actions/document-save-as.png)
 @asset(qx/icon/${qx.icontheme}/16/actions/document-new.png)
 @asset(qx/icon/${qx.icontheme}/16/actions/window-close.png)
 @asset(qx/icon/${qx.icontheme}/16/actions/go-next.png)
 @asset(qx/icon/${qx.icontheme}/16/actions/go-previous.png)
 @asset(qx/icon/${qx.icontheme}/16/apps/office-database.png)
 @asset(Agrammon/tags_ts.png)
 */

qx.Class.define('agrammon.module.dataset.DatasetTool', {
    extend: qx.ui.window.Window,

    /**
      * @ignore(SELECTIONS)
      * @lint ignoreDeprecated(alert)
      */
    construct: function (title) {
        this.base(arguments);
        this.__info = agrammon.Info.getInstance();
        this.__rpc  = agrammon.io.remote.Rpc.getInstance();

        qx.locale.Manager.getInstance().addListener("changeLocale",
                                                    this.__changeLanguage,
                                                    this);

        var maxHeight = qx.bom.Document.getHeight() - 20;
//        this.debug('maxHeight='+maxHeight);
        this.set({
                   layout: new qx.ui.layout.VBox(10),
//                   width: this.__WITHTAGS,
                   maxHeight: maxHeight, //allowShrinkY: true,
                   modal: true,
                   showClose: true, showMinimize: false, showMaximize: false,
                   caption: title,
                   contentPadding: [0, 0, 10, 0], padding: 0,
                   icon: 'icon/16/apps/office-database.png'
                 });
        this.getChildControl("pane").setBackgroundColor("white");
        var that = this;
        this.__datasetCache = agrammon.module.dataset.DatasetCache.getInstance();

        // datasetTable
//        var datasetTable = new agrammon.module.dataset.DatasetTable();
        var datasetTable = agrammon.module.dataset.DatasetTable.getInstance();
        this.__datasetTable = datasetTable;

        // might not work in manage dataset mode because updateView
        // is called on datasetTable from availableTagsSelected handler
        datasetTable.addListener("cellDbltap",
                                 this.__dblClick_func,
                                 this);

        var datasetTm = datasetTable.getTableModel();
        var activeTagsTable =
            new agrammon.module.dataset.TagTable(this.tr("Active tags"), false); // not indexed
        this.__activeTagsTable = activeTagsTable;
        var activeTagsTm  = activeTagsTable.getTableModel();
        this.__activeTags = [];
        activeTagsTm.setData(this.__activeTags);

        var availableTagsTable =
            new agrammon.module.dataset.TagTable(this.tr("Available tags"), true); // indexed
        this.__availableTagsTable = availableTagsTable;
        var availableTagsTm  = availableTagsTable.getTableModel();
        this.__availableTags = [];
        availableTagsTm.setData(this.__availableTags);


        // make sure all toolbars are the same height
        this.addListener("appear",  function(e) {
            // this.debug('DatasetTool.appear');
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
            var tags =  new Object; // set tags

            for (r=0; r<ranges; r++) {              // loop over selection ranges
                min = datasetSelections[r]['minIndex'];
                max = datasetSelections[r]['maxIndex'];
                nDatasets += (max - min + 1);           // total number of selections
                for (s = min; s<=max; s++) { // loop over selections
                    if (datasetTm.getValue(3,s,1)) {
                        nReadonlyDatasets++;
                    }
                    datasetTags=datasetTm.getValue(5, s, 1);  // array of tags set for this dataset
//                    if (this.__mode == 'all' && datasetTags) {

                    if (datasetTags) {
//                        that.debug('datasetTags='+datasetTags);
                        nDatasetTags=datasetTags.length;

                        // collect all tags of the selected datasets into the tag hash and count them
                        for (t=0; t<nDatasetTags; t++) {
			                if (tags[datasetTags[t]]) {
			                    tags[datasetTags[t]]++;
			                }
			                else {
 			                    tags[datasetTags[t]]=1;
			                }
//                            that.debug('tag='+datasetTags[t]);
                        } // t loop
                    } // if (datasetTags)
                }     // s loop
            }         // r loop
            that.__activeTags = [];
            // tags hash now holds the number of occurences of each tag
//            that.debug('nDatasets = ' + nDatasets);
            var filter = {};
            var nActiveTags = 0;
	        for (t in tags) {
//	            that.debug('tags['+t+'] = ' + tags[t]);
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
	        activeTagsTm.setData(null);       // set tags
            availableTagsTable.setFilter(filter);
            if (nActiveTags > 0) {
//                 that.debug('activeTags='+that.__activeTags);
                activeTagsTm.addRows(that.__activeTags);       // set tags
            }
        };

        // This function figures out which of the available tags are currently selected.
        //
        // In manage datasets it only handles button en/disabling
        //
        // In all other modes it also
        //    filters the dataset table and shows only those datasets
        //    that are associated with one of the selected tags.
        //
        var availableTagsSelected_func = function(e) {
//            this.debug('availableTagsSelected_func(): this='+this);
            availableTagsTable.getSelectionModel().removeListener("changeSelection",
                                                           availableTagsSelected_func, this);
            var tagSelections = availableTagsTable.getSelectionModel().getSelectedRanges();
            var tslen = tagSelections.length;
            var tslen1 = this.__totalTagsSelected(availableTagsTable);
            var tslen2 = this.__totalTagsSelected(activeTagsTable);
            var dsSelections = datasetTable.getSelectionModel().getSelectedRanges();
            var dslen = dsSelections.length;
//            this.debug('availableTagsSelected_func(): dslen/tslen1/tslen2='
//                       +dslen+'/'+tslen1+'/'+tslen2);
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
//                this.debug('availableTagsSelected_func(): tslen1+tslen2='+(tslen1+tslen2));
                this.__btnRename.setEnabled(true);
            }
            else {
                this.__btnRename.setEnabled(false);
            }
	        if (this.__mode == 'all') { // no dataset filtering in manage mode
                availableTagsTable.getSelectionModel().addListener("changeSelection",
                                                               availableTagsSelected_func, this);
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
                availableTagsTable.getSelectionModel().addListener("changeSelection",
                                                                   availableTagsSelected_func, this);
                return;
            }
            if (tags) {
                var tagName, tagHash, allSet, dataset, dsName,
                    dsTags, d, t, tlen=tags.length, dt, dtlen,
                    dlen=that.__datasets.length;
                for (d=0; d<dlen; d++) {
                    dataset = that.__datasets[d];
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
//            this.debug('activeTagsSelected_func(): this='+this);
            var tagSelections = activeTagsTable.getSelectionModel().getSelectedRanges();
            var tslen = tagSelections.length;
            var tslen1 = this.__totalTagsSelected(availableTagsTable);
            var tslen2 = this.__totalTagsSelected(activeTagsTable);
            var dsSelections = activeTagsTable.getSelectionModel().getSelectedRanges();
            var dslen = dsSelections.length;
//            this.debug('activeTagsSelected_func(): dslen/tslen1/tslen2='
//                       +dslen+'/'+tslen1+'/'+tslen2);
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
//                this.debug('activeTagsSelected_func(): tslen1+tslen2='+(tslen1+tslen2));
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
            if (exc == null) {
//	            var n = data;
//	            that.debug('Tag set on '+n+' datasets');
//                qx.event.message.Bus.dispatchByName('agrammon.DatasetCache.refresh', that.__info.getUserName());
	            return;
	        }
            else {
                alert(exc);
            }
        }; // set_tags_func()

        var remove_tag_func = function(data,exc,id) {
            if (exc == null) {
//	            var n = data;
//	            that.debug(n+' tags removed.');
//                qx.event.message.Bus.dispatchByName('agrammon.DatasetCache.refresh', that.__info.getUserName());
	            return;
	        }
            else {
                alert(exc);
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
//  	        that.debug('datasets = ' + datasets);

            var tag;
	        var tagSelections = availableTagsTable.getSelectionModel().getSelectedRanges();
	        var tlen = tagSelections.length;

            for (i=tlen-1; i>=0; i--) {
                min = tagSelections[i]['minIndex'];
                max = tagSelections[i]['maxIndex'];
                for (ii = max; ii>=min; ii--) {
                    tag = availableTagsTm.getValue(0,ii, 1) ;
//                    that.debug('tagAdd_func(): adding tag ' + tag);
                    this.__rpc.callAsync( set_tag_func, 'set_tag',
                                   { datasets: datasets,
			                         tag: tag }
		            );
                    availableTagsTable.addToFilter(tag, true);
  	                activeTagsTm.addRows([[ tag ]]);
                    datasetTable.addTag(datasets, tag);
                }
            }
            activeTagsTm.sortByColumn(0, true);
   	        availableTagsTm.updateView(1);
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
//  	        that.debug('datasets = ' + datasets);

            var tag;
	        var tagSelections = activeTagsTable.getSelectionModel().getSelectedRanges();
	        var tlen = tagSelections.length;

            // move backwards through selection to remove correct rows
            for (i=tlen-1; i>=0; i--) {
                min = tagSelections[i]['minIndex'];
                max = tagSelections[i]['maxIndex'];
                for (ii = max; ii>=min; ii--) {
                    tag = activeTagsTm.getValue(0,ii,1) ;
//                    that.debug('tagRemove_func(): removing tag ' + tag + ' from ds='+datasets);
//                    this.__rpc.callAsync( this.__delete_tag_func, 'delete_tag',
                    this.__rpc.callAsync( this.__remove_tag_func, 'remove_tag',
			                       { datasets: datasets, tag: tag }
			        );
                    availableTagsTable.removeFromFilter(tag);
 	                activeTagsTm.removeRows(ii,1);
                    datasetTable.removeTag(datasets, tag);
                }
            }
            activeTagsTable.getSelectionModel().resetSelection();
   	        activeTagsTm.updateView(1);
   	        availableTagsTm.updateView(1);
        };


        availableTagsTable.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                var col = availableTagsTable.getFocusedColumn();
                if (col == 1) {
                    return;
                }
//                var row = availableTagsTable.getFocusedRow();
//                that.debug('availableTagsTable(): enter pressed on row/col='+row+'/'+col);
            }
        });

        activeTagsTable.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                var col = activeTagsTable.getFocusedColumn();
                if (col == 1) {
                    return;
                }
//                var row = activeTagsTable.getFocusedRow();
//                that.debug('activeTagsTable(): enter pressed on row/col='+row+'/'+col);
            }
        });

        var btnCancel = new qx.ui.form.Button(this.tr("Close"),
                                              "icon/16/actions/window-close.png");
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

        var datasetColumn =
            new qx.ui.container.Composite(new qx.ui.layout.VBox(10));
        datasetColumn.setPadding(0); // top right bottom left

        var tagColumn =
            new qx.ui.container.Composite(new qx.ui.layout.VBox(10));
        tagColumn.setPadding(0); // top right bottom left
        this.__tagColumn = tagColumn;

        this.__tagToolBar = new qx.ui.toolbar.ToolBar();
        this.__tagToolBar.setAllowShrinkY(false);
        this.__tagToolBar.setAllowGrowY(true);
        this.__tagToolBar.setPadding(0, 5, 0, 5);

        tagColumn.add(this.__tagToolBar);
        this.__createTagButtons();
        this.enableButtons(0,0);

        var tagBox =
            new qx.ui.container.Composite(new qx.ui.layout.HBox(0));

        var btnBox =
            new qx.ui.container.Composite(new qx.ui.layout.VBox(5));
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
		    var len = that.__datasets.length;
            // that.debug('__setDatasets(): len='+len);
		    if (len<1) {
                //		        alert('No existing datasets in database yet.');
			    return;
		    }
            datasetTm.setData(null);
            datasetTm.addRows(that.__datasets);
            datasetTable.getSelectionModel().resetSelection();
            datasetTm.updateView(1);
            datasetTm.setView(1);
        }; // this.__setDatasets()

        this.__clearDatasets = function() {
//            that.debug('__clearDatasets()');
            datasetTm.setData(null);
        }; // this.__clearDatasets()

        this.addListener("resize", this.center, this);

        this.__setTags = function() {
            var data = this.__datasetCache.getTags();
	        var len = data.length;
    		if (len<1) {
//		        that.debug('No tags in database yet.');
		        return;
		    }
  	        var i, rec;
  	        that.__availableTags = [];
  	        for (i=0; i<len; i++) {
		        rec = [ data[i] ];
  		        that.__availableTags.push(rec);
	        }
            availableTagsTm.setData(that.__availableTags);
            availableTagsTm.updateView(1);
            availableTagsTm.setView(1);
        }; // this.__setTags()

        //        this.__rpc.callAsync( this.__setTags,
        //                       'get_tags');

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
            that.setCaption(that.tr("Datasets of")
                            + ' ' + that.__info.getUserName());
        };
        qx.event.message.Bus.subscribe('agrammon.info.setUser', this.__setUser);
        this.__setDatasets();

        this.__commentColumn = datasetTable.getCommentColumn();
        this.__commentEditor = agrammon.module.dataset.DatasetComment.getInstance();
        this.__commentEditor.init(datasetTable, this.__commentColumn);

        // resize window if browser window size changes
        qx.core.Init.getApplication().getRoot().addListener("resize",
                                                            function () {
            var height = qx.bom.Document.getHeight() - 20;
//            this.debug('maxHeight='+height);
            this.setMaxHeight(height);
//            this.setHeight(height);
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
        __dblClickHandler: null,
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
//            this.debug('__totalTagsSelected(): tslen='+tslen);
            var i, min, max, n=0;
            for (i=0; i<tslen; i++) {  // loop of selection ranges
                min = tagSelections[i]['minIndex'];
                max = tagSelections[i]['maxIndex'];
                n += (max - min + 1);
            }
//            this.debug('__totalTagsSelected(): n='+n);
            return n;
        },


        __createButtons: function() {
            this.__btnSetReference   = new qx.ui.form.Button(this.tr("Set reference"), "");
            this.__btnClearReference = new qx.ui.form.Button(this.tr("Clear reference"), "");
            this.__btnCopy = new qx.ui.form.Button(this.tr("Copy+Connect"), "");
            this.__btnOpen = new qx.ui.form.Button(this.tr("Connect"), "");
//            this.__btnNewDS = new qx.ui.form.Button(this.tr("Empty dataset"), "");
            this.__buttonRow.add(this.__btnSetReference);
            this.__buttonRow.add(this.__btnClearReference);
            this.__buttonRow.add(this.__btnCopy);
            this.__buttonRow.add(this.__btnOpen);
//            this.__buttonRow.add(this.__btnNewDS);

            this.__btnCopy.addListener("execute", function(e) {
                var data = this.__datasetTable.getSelectionModel().getSelectedRanges();
                var row = data[0]['minIndex'];
                var oldDatasetName =
                    this.__datasetTable.getTableModel().getValue(0,row,1);
                var dialog;
                var okFunction = qx.lang.Function.bind(function(self) {
                    var newDatasetName = self.nameField.getValue();
//                 this.debug('cloneCommand: dataset=' + newDatasetName);

                    qx.event.message.Bus.dispatchByName('agrammon.FileMenu.cloneDataset',
                                                  {'newDataset': newDatasetName,
                                                   'oldDataset': oldDatasetName
                                                  });
                    self.close();
                    this.close();
                }, this);
                dialog = new agrammon.ui.dialog.Dialog(this.tr("Cloning dataset"),
                                                this.tr("New dataset name"),
                                                okFunction, this);
                return;
            }, this);

            this.__btnClearReference.addListener("execute", function(e) {
                qx.event.message.Bus.dispatchByName('agrammon.Reports.clear');
                qx.event.message.Bus.dispatchByName('agrammon.info.setReferenceDataset', '-');
                qx.event.message.Bus.dispatchByName('agrammon.Reference.invalidate');
                qx.event.message.Bus.dispatchByName('agrammon.Reports.showReference', false);
                // this.close();
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
            this.__btnAdvanced.setIcon('Agrammon/tags_ts.png');
            if (this.__advancedMode) {
                 this.__btnAdvanced.setLabel(this.tr("Hide tags"));
            }
            else {
                 this.__btnAdvanced.setLabel(this.tr("Show tags"));
            }
            this.__btnAdvanced.setMarginRight(5);
            this.__btnAdvanced.setPadding(0,5,0,5);
            this.__btnAdvanced.setValue(this.__advancedMode);
//            this.__btnAdvanced.setEnabled(false);
            this.__datasetTable.getToolBar().add(new qx.ui.core.Spacer(1,0), {flex:1});
            this.__datasetTable.getToolBar().add(this.__btnAdvanced);

            this.__btnAdvanced.addListener("changeValue", function(e) {
//                this.debug('Advanced mode: value = ' + this.__btnAdvanced.getValue());
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
            // this.debug('DatasetTool.__dblClick_func(): mode='+this.__mode);
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
//                this.debug('Datasets: refSelected ' + datasetName);
                this.__btnSetReference.execute();
//                qx.event.message.Bus.dispatchByName('agrammon.info.setReferenceDataset',
//                                               datasetName);
//                qx.event.message.Bus.dispatchByName('agrammon.Reference.invalidate');
            }
            var sm = this.__datasetTable.getSelectionModel();
            sm.resetSelection();

            if (readOnly) {
                return;
            }
            if (this.__mode == 'connect' || this.__mode == 'all') {
//                this.debug('Datasets: connectSelected ' + datasetName);
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
         __new_tag_func: function(data,exc,id) {
            if (exc == null) {
//	            this.debug(data+' tags created.');
//                qx.event.message.Bus.dispatchByName('agrammon.DatasetCache.refresh', this.__info.getUserName());
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
         __delete_tag_func: function(data,exc,id) {
            if (exc == null) {
//	            this.debug(data+' tags deleted.');
//                qx.event.message.Bus.dispatchByName('agrammon.DatasetCache.refresh', this.__info.getUserName());
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
         __rename_tag_func: function(data,exc,id) {
            if (exc == null) {
//	            this.debug(data+' tags renamed.');
//                qx.event.message.Bus.dispatchByName('agrammon.DatasetCache.refresh', this.__info.getUserName());
	        }
            else {
                alert(exc);
            }
        },

        __createTagButtons: function() {
            this.__btnRename =
                new qx.ui.toolbar.Button(this.tr("Rename"),
                                         "icon/16/actions/document-save-as.png");
            this.__btnNew =
                new qx.ui.toolbar.Button(this.tr("New"),
                                         "icon/16/actions/document-new.png");
            this.__btnDel =
                new qx.ui.toolbar.Button(this.tr("Delete"),
                                         'icon/16/actions/window-close.png');
            this.__btnDel.setEnabled(false);
            this.__btnRename.setEnabled(false);
            this.__tagToolBar.add(this.__btnRename);
            this.__tagToolBar.add(this.__btnNew);
            this.__tagToolBar.add(this.__btnDel);
            this.__btnRename.addListener("execute", function(e) {
//                this.debug('TagTable.__btnRename()');
                var dialog;
                var okFunction = qx.lang.Function.bind(function(self) {
                    var tag_new = self.nameField.getValue();
                    if (this.__datasetCache.tagExists(tag_new)) {
                        qx.event.message.Bus.dispatchByName('error',
                            [ this.tr("Error"),
                              this.tr("Tag") + ' ' + tag_new + ' ' +this.tr("already exists")]);
                        self.close();
                        return;
                    }

                    var table;
                    // only one of the two tag tables can have a selection if rename is called
                    if (this.__totalTagsSelected(this.__activeTagsTable)) {
                        table = this.__activeTagsTable;
//                        this.debug('renameCommand: activeTagsTable');
                    }
                    else {
                        table = this.__availableTagsTable;
//                        this.debug('renameCommand: availableTagsTable');
                    }
                    var data = table.getSelectionModel().getSelectedRanges();
                    var row = data[0]['minIndex'];
                    var tm = table.getTableModel();
//                    var len=tm.getRowCount(1);
                    var tag_old = tm.getValue(0, row, 1);

//data = tm.getData();
//this.debug('len='+len+', data='+data);
//            this.__availableTagsTable.getSelectionModel().removeListener("changeSelection",
//                                                           this.__availableTagsSelected_func, this);

//                    this.debug('renameCommand: row='+row+', ' + tag_old + ' -> ' + tag_new);
// if (this.__totalTagsSelected(this.__activeTagsTable)) {


                    tm.setValue(0, row, tag_new, 1);
//                    tm.updateView(1);
//     data = tm.getData();len=tm.getRowCount(1);
//     this.debug('len='+len+', data='+data);
// }
     this.__availableTagsTable.renameTag(tag_old, tag_new);
//     len=tm.getRowCount(1);
//     this.debug('len='+len+', data='+data);
//            this.__availableTagsTable.getSelectionModel().addListener("changeSelection",
//                                                           this.__availableTagsSelected_func, this);
//                    alert('Renaming tag');
                    this.__datasetTable.renameTag(tag_old, tag_new);
                    this.__rpc.callAsync( qx.lang.Function.bind(this.__rename_tag_func,this),
                                        'rename_tag',
			                            { tag_old: tag_old,
                                          tag_new: tag_new
                                        }
    			    );
                    self.close();
                }, this);
                dialog =
                    new agrammon.ui.dialog.Dialog(this.tr("Rename tag"),
                                           this.tr("New tag name"),
                                           okFunction, this);
//            this.close();
            }, this);

            this.__btnNew.addListener("execute", function(e) {
//                this.debug('TagTable.__btnNew()');
                var dialog;
                var okFunction = qx.lang.Function.bind(function(self) {
                    var tag = self.nameField.getValue();
//                    this.debug('newCommand: tag=' + tag);
                    var tm =   this.__availableTagsTable.getTableModel();
                    if (this.__datasetCache.tagExists(tag)) {
                        qx.event.message.Bus.dispatchByName('error',
                            [ this.tr("Error"),
                              this.tr("Tag") + ' ' + tag + ' ' +this.tr("already exists")]);
                        self.close();
                        return;
                    }
                    // FIX ME: should be added by async handler
                    this.__datasetCache.newTag(tag);
      	            tm.addRows([[ tag ]]);
                    tm.updateView(1);
        		    tm.sortByColumn(0, true);
                    this.__rpc.callAsync( qx.lang.Function.bind(this.__new_tag_func,this),
                                          'new_tag', tag
    			    );
                    self.close();
                }, this);
                dialog =
                    new agrammon.ui.dialog.Dialog(this.tr("Creating new tag"),
                                           this.tr("New tag name"),
                                           okFunction, this);
//            this.close();
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
//                        this.debug('Deleting tag: i='+i+', min/max='+min+'/'+max);
                        for (ii = max; ii>=min; ii--) {
                            tag = availableTagsTm.getValue(0,ii,1) ;
                            tags.push(tag);
//                            this.debug('ii='+ii+': Deleting tag='+tag);
                            // FIX ME: should be removed by async handler
                            this.__datasetCache.delTag(tag);
                            this.debug('Going to remove line ' + ii);
                            this.__availableTagsTable.getSelectionModel().resetSelection();
  	                        availableTagsTm.removeRows(ii,1,1);
                            this.debug('Line ' + ii +' removed');
                        }
                    }
                    availableTagsTm.updateView(1);
                    for (tag in tags) {
                        this.__datasetTable.delTag(tags[tag]);
                        this.__availableTagsTable.delTag(tags[tag]);
                        this.__activeTagsTable.delTag(tags[tag]);
// 	                    this.debug('Deleting tag='+tags[tag]);
                        this.__rpc.callAsync( qx.lang.Function.bind(this.__delete_tag_func,this),
                                              'delete_tag', tags[tag] 
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
	    this.setCaption( this.tr("Datasets of") + ' ' + username);
        } // __changeLanguage
    }
});

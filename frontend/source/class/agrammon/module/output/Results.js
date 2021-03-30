/* ************************************************************************

************************************************************************ */

/**
 * @asset(agrammon/info.png)
 * @asset(agrammon/nh3.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/document-send.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/utilities-statistics.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/office-spreadsheet.png)
 */

qx.Class.define('agrammon.module.output.Results', {
    extend: qx.ui.container.Composite,

    construct: function (outputData) {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox(5));

        this.outputData = outputData;

        // qx.locale.Manager.getInstance().addListener("changeLocale",
        //                                             this.__changeLanguage,
        //                                             this);
        // qx.event.message.Bus.subscribe('agrammon.Reports.showReference',
        //                                this.__showReferenceColumn, this);
        // qx.event.message.Bus.subscribe('agrammon.Reports.clear',
        //                                this.__clearTable, this);
        qx.event.message.Bus.subscribe('agrammon.Output.invalidate',
                                        this.__clearTable, this);
        qx.event.message.Bus.subscribe('agrammon.Output.reCalc',
                                       this.__recalc, this);
        qx.event.message.Bus.subscribe('agrammon.Reports.createMenu',
                                       this.__updateMenu, this);
        qx.event.message.Bus.subscribe('agrammon.Output.dataReady',
                                       this.__dataReady, this);
        qx.event.message.Bus.subscribe('agrammon.outputEnabled',
                                       this.__enabled, this);
        this.resultData = new Array;

        var title = new qx.ui.basic.Label();
        this.__title=title;
        title.set({paddingTop:5, paddingLeft: 5, rich: true});
        this.add(title);
        // table model
        var tableModel = new qx.ui.table.model.Simple();
        this.tableModel = tableModel;
        tableModel.setColumns([ this.tr("Module"),    // 0
		 		                this.tr("Variable"),
				                this.tr("Reference"),
				                this.tr("Value"),
				                this.tr("Change"),
                                this.tr("Unit"),
                                this.tr("Print"),
                                this.tr("Order")      // 7
                              ]);
        // Customize the table column model.  We want one that automatically
        // resizes columns.
        var custom =  {
            tableColumnModel : function(obj) {
                return new qx.ui.table.columnmodel.Resize(obj);
            }
        };

        var info = agrammon.Info.getInstance();
        var outputTable = new qx.ui.table.Table(tableModel, custom);
        outputTable.set({ padding: 0,
                  keepFirstVisibleRowComplete: true,
                  columnVisibilityButtonVisible: info.isAdmin(),
                  statusBarVisible: false
                });
        outputTable.setMetaColumnCounts([1, -1]);
        outputTable.getSelectionModel().setSelectionMode(qx.ui.table.selection.Model.NO_SELECTION);

        // Specify the resize behavior... First, get the table column model,
        // which we specified to be a ResizeTableColumModel object.
        var tcm = outputTable.getTableColumnModel();
        this.tcm = tcm;

        // Obtain the behavior object to manipulate
        var resizeBehavior = tcm.getBehavior();

        // resizeBehavior.set(0, { width:"1*", minWidth:40, maxWidth:80 });
        // The default is { width:"1*" } so this one is not necessary:
        resizeBehavior.set(0, { width:"1*"});
        resizeBehavior.set(1, { width:"2*" });
        resizeBehavior.set(2, { width:80 });
        resizeBehavior.set(3, { width:80 });
        resizeBehavior.set(4, { width:80 });
        resizeBehavior.set(5, { width:80 });
        resizeBehavior.set(6, { width:100 });
        resizeBehavior.set(7, { width:80 });

        tcm.setDataCellRenderer(0, new agrammon.ui.table.cellrenderer.output.Text);
        tcm.setDataCellRenderer(2, new agrammon.ui.table.cellrenderer.output.Number);
        tcm.setDataCellRenderer(3, new agrammon.ui.table.cellrenderer.output.Number);
        tcm.setColumnVisible(2,false); // ref value
        tcm.setColumnVisible(4,false); // change
        tcm.setColumnVisible(6,false); // print
        tcm.setColumnVisible(7,false); // order
        tableModel.setColumnSortable(0,false);
        tableModel.setColumnSortable(1,false);
        tableModel.setColumnSortable(2,false);
        tableModel.setColumnSortable(3,false);
        tableModel.setColumnSortable(4,false);
        tableModel.setColumnSortable(5,false);
        tableModel.setColumnSortable(6,false);
        tableModel.setColumnSortable(7,false);
        this.add(outputTable, { flex : 1 });

        this.setEnabled(false);

    }, // construct

    members :
    {
        __title: null,
        __outputPending: 0,
        outputData: null,
        resultData: null,
        reportSelected: null,
        titleSelected: null,
        tableModel: null,
        tcm: null,
        __log: null,
        __tt: null,

        __showReference: function (show) {
            this.debug('__showReference(): show=' + show);
            this.tcm.setColumnVisible(2,show); // refValue
            this.tcm.setColumnVisible(4,show); // change
        },

        __showReferenceColumn: function (msg) {
            this.debug('__showReferenceColumn(): msg=' + msg.getData());
            this.__showReference(msg.getData());
        },

        __sortByVarName: function (a,b) {
            var x = a[7];
            var y = b[7];
            return ((x < y) ? -1 : ((x > y) ? 1 : 0));
        },

        __sortByOrder: function (a,b) {
            var x = a['order'];
            var y = b['order'];
            return x - y;
        },

	/**
	  * @ignore(TAGS)
	  */

        __getOutputData:  function() {

            if ( !(this.outputData.isValid()
//                   && this.referenceData.isValid())
                   )) {
                return;
            }

            // FIX ME: why is this needed ?
//            if (! this.selectMenu.getSelection()[0]) {
//                return;
//            }

//            let reportName = this.selectMenu.getSelection()[0].getModel();
            let dataSet = new Array;

            let rdlen = this.resultData.length;
            let found = false;
            let showFilterGroups;
            for (let ri=0; ri<rdlen; ri++) {
//                if (this.resultData[ri].name == reportName) {
                if (this.resultData[ri].resultView) {
                    found = true;
                    this.reportIndex = ri;
                    break;
                }
            }
            if (! found) {
                console.error('no result view report found');
                return;
            }

            showFilterGroups = this.resultData[this.reportIndex].type == 'reportDetailed' ? true : false;
            let reports = this.resultData[this.reportIndex].data;

            let data    = this.outputData.getDataset();;
//            let refData = this.referenceData.getDataset();
//            if (refData == null) {
//                this.__showReference(false);
//            }
//            else {
//                this.__showReference(true);
//            }

            let currentTitle='';
            let printTag = '';
            let repDataset, repRefDataset;
            let locale = qx.locale.Manager.getInstance().getLocale();
            locale = locale.replace(/_.+/,'');
            this.titleSelected  = '';
            this.reportSelected = '';

            for (let report of reports) { // reports selected

                let printKey   = report.print;
                let langLabels = report.langLabels;

                currentTitle='';
                let title = report.langLabels[locale] ? report.langLabels[locale]
                                                      : report.langLabels.en ? report.langLabels.en
                                                                             : printKey;
                if (this.titleSelected != '') {
                    this.titleSelected += ',';
                }
                this.titleSelected += title;

                if (this.reportSelected != '') {
                    this.reportSelected += ',';
                }
                this.reportSelected += printKey;

                repDataset    = new Array;
                repRefDataset = new Array;
                let seen = {};
                let len = data.length;
                for (let i=0; i<len; i++) { // variables
                    let varName, rec, refRec, value, refValue, refDiff, printMe;
                    rec = data[i];
//                    if (refData != null) {
//                        refRec = refData[i];
//                    }
//                    else {
//                        refRec = null;
//                    }
                    printMe = false;
                    printTag = String(rec.print);
                    let tags = printTag.split(',');
                    for (let tag of tags) {
                        if (tag == printKey) {
                            printMe = true;
                            break;
                        }
                    }
                    if ( printMe ) {
                        if (title != currentTitle) {
                            repDataset.push([ title, '', '', '', '', '', '', '', -1 ]);
                            currentTitle = title;
                        }
                        varName = rec.labels ? String(rec.labels[locale]) : rec.var;
                        value   = rec.value;
                        if (refRec != null) {
                            refValue = refRec.value;
                            refDiff = value - refValue;
                        }
                        else {
                            refValue = '-';
                            refDiff  = '-';
                        }
                        if (rec.filters && rec.filters.length>0 && showFilterGroups) {
                            var filters = rec.filters;
                            let filterTitles = [];
                            let filterKeys   = [];
                            for (let filter of filters) {
                                filterTitles.push(filter.label[locale]);
                                filterKeys.push(filter.enum[locale]);
                            }
                            varName = '. . . . . . ' + filterKeys.join(', ');
                        }
                        else {
                            // TODO: remove hack
                            if (seen[rec.var]) {
                                continue;
                            }
                            else {
                                seen[rec.var] = true;
                            }
                        }
                        repDataset.push([ '', // moduleName
                            varName,
                            refValue, // reference
                            value,
                            refDiff, // change
                            rec.units[locale],
                            rec.print,
                            rec.labels.sort
                        ]);
                    } // printMe
                } // variables
                dataSet = dataSet.concat(repDataset);
            } // reports
            this.tableModel.setData(dataSet);
        },

        __clearTable: function() {
            this.tableModel.setData(new Array);
        },

        __updateMenu: function(msg) {
            if (msg.getData() != null) {
                this.resultData = msg.getData().sort(this.__sortByOrder);
            }
            else {
                this.debug('__createMenu: msg=null');
            }
        },

        __dataReady: function(msg) {
            this.__outputPending--;
            this.__getOutputData();
        },

        __recalc: function() {
            if (this.getEnabled()) {
                this.__outputPending++;
                this.__clearTable();
                qx.event.message.Bus.dispatchByName('agrammon.Output.getOutput');
            }
        },

        __enabled: function(msg) {
            var enable = msg.getData();
            if (this.getEnabled() && enable) {
                return;
            }
            if (!this.getEnabled() && !enable) {
                return;
            }
            if (enable) {
                this.debug('enable');
                this.__outputPending++;
                qx.event.message.Bus.dispatchByName('agrammon.Output.getOutput');
                this.__title.setValue(this.tr("<b>Result summary</b>"));
            }
            else {
                this.__clearTable();
                this.__title.setValue(this.tr("No results yet, incomplete input data"));
            }
            this.setEnabled(enable);
        }

    }
});



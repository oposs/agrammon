/* ************************************************************************

************************************************************************ */

/**
 * @asset(agrammon/info.png)
 * @asset(agrammon/nh3.png)
 * @asset(agrammon/nh3-rotate.gif)
 * @asset(qx/icon/${qx.icontheme}/16/actions/document-send.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/utilities-statistics.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/office-spreadsheet.png)
 */

qx.Class.define('agrammon.module.output.Reports', {
    extend: qx.ui.tabview.Page,

    construct: function (outputData, referenceData) {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox(10));
        this.set({label: this.tr("Tabular Results"), enabled: false});

        var variant = agrammon.Info.getInstance().getVariant();
        var version = agrammon.Info.getInstance().getVersion();
        this.__version = 'Agrammon, ' + variant + ', ' + version;

        var baseUrl = agrammon.io.remote.Rpc.getInstance().getBaseUrl();
        this.__info = agrammon.Info.getInstance();
        this.outputData = outputData;
        this.referenceData = referenceData;

        qx.locale.Manager.getInstance().addListener("changeLocale",
                                                    this.__changeLanguage,
                                                    this);
        qx.event.message.Bus.subscribe('agrammon.Reports.showReference',
                                       this.__showReferenceColumn, this);
        qx.event.message.Bus.subscribe('agrammon.Reports.clear',
                                       this.__clearTable, this);
        qx.event.message.Bus.subscribe('agrammon.Reports.createMenu',
                                       this.__updateMenu, this);
        qx.event.message.Bus.subscribe('agrammon.Output.dataReady',
                                       this.__dataReady, this);
        qx.event.message.Bus.subscribe('agrammon.outputEnabled',
                                       this.__enabled, this);
        qx.event.message.Bus.subscribe('agrammon.Info.setModelVariant',
                                       this.__setModelVariant, this);


        this.busyIcon = new qx.ui.basic.Atom('','agrammon/nh3.png');

        // Output selection
        this.selectLabel = new qx.ui.basic.Label(this.tr("Choose table: "));

        this.resultData = new Array;
        this.selectMenu  =
            new agrammon.module.output.OutputSelector(
                qx.lang.Function.bind(this.__getOutputData, this));

        var selectRow =
            new qx.ui.container.Composite(new qx.ui.layout.HBox().set({
                spacing: 20})).set({
                  padding: 0
            });

        selectRow.add(this.busyIcon);
        selectRow.add(this.selectLabel);
        selectRow.add(this.selectMenu);
        this.add(selectRow, {flex : 0});


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

        var outputTable = new qx.ui.table.Table(tableModel, custom);
        outputTable.set({ padding: 0,
                  keepFirstVisibleRowComplete: true,
                  columnVisibilityButtonVisible: false,
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

        var logBox = new qx.ui.groupbox.GroupBox(this.tr("Simulation log"), 'agrammon/info.png');
        logBox.setLayout(new qx.ui.layout.VBox(5));
        var scrollBox = new qx.ui.container.Stack();
        scrollBox.setMaxHeight(250);
        logBox.setMaxHeight(250);

        var tt = new qx.ui.tooltip.ToolTip(this.tr("Simulation-Info"));
        tt.set({maxWidth: 300, rich: true});
        logBox.setToolTip(tt);
        this.__logAreaOutput = new qx.ui.basic.Atom();
        this.__logAreaOutput.set({rich: true});
//        logBox.add(this.__logAreaOutput);
        scrollBox.add(this.__logAreaOutput);
        logBox.add(scrollBox, { flex : 1 });

        this.__logAreaReference = new qx.ui.basic.Atom();
        this.__logAreaReference.set({rich: true});
//        logBox.add(this.__logAreaReference);
        scrollBox.add(this.__logAreaReference);

        this.__logAreaReference.exclude();
        this.add(logBox, { flex : 0 });

        this.__excelButton =
            new qx.ui.form.Button(this.tr("Open in Excel"),
                                  'icon/16/apps/office-spreadsheet.png');
        this.__excelButton.set({ maxWidth: 150, enabled: false });
        selectRow.add(new qx.ui.core.Spacer(1), {flex:1});
        selectRow.add(this.__excelButton);


        this.__excelButton.addListener('execute', function(e) {
            var locale      = qx.locale.Manager.getInstance().getLocale().replace(/_.+/,'');
            var userName    = this.__info.getUserName();
            var variant     = agrammon.Info.getInstance().getVariant();
            var version     = agrammon.Info.getInstance().getVersion();
            var datasetName = this.__info.getDatasetName();
            var params = {
                language     : locale,
                username     : userName,
                reports      : this.reportSelected,
                format       : 'excel',
                titles       : this.titleSelected,
                datasetName  : datasetName,
                modelVariant : agrammon.Info.getInstance().getModelVariant(),
                guiVariant   : agrammon.Info.getInstance().getGuiVariant(),
                version      : version
            };

            var url = '/get_excel_export';
            if (baseUrl != null) {
                url = baseUrl + url;
            }

            var form    = document.createElement("form");
            form.target = 'AgrammonExcelExport' + Math.random();
            form.method = "POST";
            form.action = url;

            for (var key in params) {
                this.__addTextInput(form, key, params[key]);
            }
            document.body.appendChild(form);

            // status=1 open's in new tab in Chrome at least
            var options = "menubar=1,scrollbars=1,resizable=1,status=0,titlebar=1,height=600,width=800,toolbar=1"
            var win = window.open('', form.target, options);
            if (win) {
                form.submit();
            }
            else {
                alert('You must allow popups for reports to work.');
            }
        }, this);

        this.__pdfButton =
            new qx.ui.form.Button(this.tr("Create PDF"),
                                  'icon/16/apps/utilities-statistics.png');
        this.__pdfButton.set({ maxWidth: 150, enabled: false });
        selectRow.add(this.__pdfButton);

        this.__pdfButton.addListener('execute', function(e) {
            var locale = qx.locale.Manager.getInstance().getLocale();
            var lang   = 'lang=' + locale.replace(/_.+/,'');
            var format = 'format=pdf';
            var reportUrl    = 'reports=' + this.reportSelected;
            var pidUrl       = 'pid=' + outputData.getPid();
            var titleUrl     = 'titles='  + this.titleSelected;
            var sessionUrl   = 'session=' + outputData.getSession();
            var userName     = this.__info.getUserName();
            var userUrl      = 'user=' + userName;
            var datasetName  = this.__info.getDatasetName();
            var datasetUrl   = 'dataset=' + datasetName;
            var modelVariant = 'modelVariant='+agrammon.Info.getInstance().getModelVariant();
            var guiVariant   = 'guiVariant='+agrammon.Info.getInstance().getGuiVariant();
//	        var variant = agrammon.Info.getInstance().getVariant();
            var version = agrammon.Info.getInstance().getVersion();
            var versionUrl   = 'version=' + version;
            var url = 'export/latex'
                               + '?' + 'mode=public'
                               + '&' + reportUrl
                               + '&' + titleUrl
                               + '&' + pidUrl
                               + '&' + sessionUrl
                               + '&' + userUrl
                               + '&' + datasetUrl
                               + '&' + lang
                               + '&' + versionUrl
                               + '&' + format
                               + '&' + guiVariant
                               + '&' + modelVariant;
            if (baseUrl != null) {
                url = baseUrl + url;
            }

        // var req = new qx.io.request.Xhr(url, 'GET');
        // req.setRequestData({ key: 'value'} );
        // req.addListener("success", function(e) {
        //     var req = e.getTarget();

        // 	// Response parsed according to the server's
        // 	// response content type, e.g. JSON
        // 	var response = req.getResponse();
        // 	this.debug('response='+response);
        // }, this);
        // req.send();

        // works with source and FF 21 on Linux, but in same window
//             document.location=url;
           window.open(url);
//             agrammon.ui.ViewerIframe.getInstance().loadDocument(url);
        }, this);

        this.__submitButton =
            new qx.ui.form.Button(this.tr("Submission"),
                                  'icon/16/actions/document-send.png');
        this.__submitButton.set({ maxWidth: 150, enabled: false });
        this.__submitButton.exclude();
        selectRow.add(this.__submitButton);
        this.__submitButton.addListener('execute', this.__submit, this);

        this.addListener("appear", this.__appear, this);

        return this;
    }, // construct

    members :
    {
        __outputPending: null,
        __info: null,
        __version: null,
        outputData: null,
        busyIcon: null,
        selectLabel: null,
        selectMenu: null,
        resultData: null,
        reportSelected: null,
        titleSelected: null,
        tableModel: null,
        __excelButton: null,
        __pdfButton: null,
        __submitButton: null,
        tcm: null,
        __log: null,
        __logAreaOutput:    null,
        __logAreaReference: null,

        __addTextInput: function(form, name, value) {
            var input = document.createElement("input");
            input.type  = 'hidden';
            input.name  = name;
            input.value = value;
            form.appendChild(input);
        },

    __setModelVariant: function(msg) {
        var model=msg.getData();
            if (model == 'LU') {
            this.__submitButton.show();
            }
        else {
            this.__submitButton.exclude();
            }
    },

        __submit: function() {
            var logText = agrammon.module.output.Output.formatLog(this.outputData.getLog());
            var submitWindow =
                new agrammon.module.output.SubmitWindow(this.outputData, this.reportSelected,
                                                        this.titleSelected, logText);
            submitWindow.open();
        },

        __showReference: function (show) {
            this.debug('__showReference(): show=' + show);
            this.tcm.setColumnVisible(2,show); // refValue
            this.tcm.setColumnVisible(4,show); // change
            if (show) {
                this.__logAreaReference.show();
            }
            else {
                this.__logAreaReference.exclude();
            }
        },

        __showReferenceColumn: function (msg) {
            this.debug('__showReferenceColumn(): msg=' + msg.getData());
            this.__showReference(msg.getData());
            this.__appear();
        },

        __sortByVarName: function (a,b) {
            var x = a[7];
            var y = b[7];
            return ((x < y) ? -1 : ((x > y) ? 1 : 0));
        },

        __sortByOrder: function (a,b) {
            var x = a['_order'];
            var y = b['_order'];
            return ((x < y) ? -1 : ((x > y) ? 1 : 0));
        },

    /**
      * @ignore(TAGS)
      */
        __getOutputData:  function(e) {
            if (! e.getData()) {
                return;
            }

            if ( !(this.outputData.isValid()
                   && this.referenceData.isValid) ) {
                return;
            }

            // FIX ME: why is this needed ?
            if (! this.selectMenu.getSelection()[0]) {
                return;
            }

            var reportName = this.selectMenu.getSelection()[0].getModel();
            var ri, rdlen;
            var dataSet = new Array;

            rdlen = this.resultData.length;
            var found = false;
            var showFilterGroups;
            for (ri=0; ri<rdlen; ri++) {
                if (this.resultData[ri]['name'] ==  reportName) {
                    found = true;
                    this.reportSelected = ri;
                    break;
                }
            }
            if (! found) {
                this.debug('selectMenu: no matching report for '
                           +reportName);
                return;
            }

            showFilterGroups = this.resultData[ri].type == 'reportDetailed' ? true : false;
            var reports = this.resultData[ri]['data'];
            var subReports;
            var r, sr, srlen;
            var rlen = reports.length;

            var i, rec, refRec, varName, value, refValue, refDiff,
                printMe, repLen;
            var data    = new Array;
            var refData = new Array;
            data        = this.outputData.getDataset();
            refData     = this.referenceData.getDataset();
            if (refData == null) {
                this.__showReference(false);
            }
            else {
                this.__showReference(true);
            }

            var len = data.length;
            var n=0;
            var title, currentTitle='';
            var printTag = '';
            var tags, tlen, t;
            var repDataset;
            var repRefDataset;
            var locale = qx.locale.Manager.getInstance().getLocale();
            locale = locale.replace(/_.+/,'');
            this.reportSelected = '';
            this.titleSelected = '';
            for (r=0; r<rlen; r++) { // reports selected

                subReports = reports[r]['subReports'];
                srlen = subReports.length;
                if (this.reportSelected != '') {
                    this.reportSelected += ',';
                }
                this.reportSelected += subReports[0];
                for (sr=1; sr<srlen; sr++) {
                    this.reportSelected =
                        this.reportSelected + '_' + subReports[sr];
                }

                currentTitle='';
                if (reports[r][locale] != null)  {
                    title = reports[r][locale];
                }
                else {
                    title = reports[r]['en'];
                }
                if (this.titleSelected != '') {
                    this.titleSelected += ',';
                }
                this.titleSelected += title;
                repDataset = new Array;
                repRefDataset = new Array;
                var lastFTitle = '';

                var seen = {};
                for (i=0; i<len; i++) { // variables
                    rec = data[i];
                    if (refData != null) {
                        refRec = refData[i];
                    }
                    else {
                        refRec = null;
                    }
                    printMe = false;
                    printTag = String(rec.print);
                    tags = new Array;
                    tags = printTag.split(',');
                    tlen = tags.length;
              TAGS: for (t=0; t<tlen; t++) {
                        for (sr=0; sr<srlen; sr++) {
                            if (tags[t] == subReports[sr]) {
                                printMe = true;
                                break TAGS;
                            }
                        }
                    }
                    if ( printMe ) {
                        if (title != currentTitle) {
                            repDataset.push([ title, '', '', '', '', '', '', '', -1 ]);
                            currentTitle = title;
                        }
                        varName = 'unknown';
                        if (rec.labels) {
                            varName = String(rec.labels[locale]);
                        }
                        else {
                            varName = rec['var'];
                        }
                        value = rec.value;
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
//                            console.log('filters=', filters);
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
                            if (seen[rec.var]) continue;
                            seen[rec.var] = true;
                        }
//                        console.log(rec.var + ' - ' + varName+ ': ' + value);
                        repDataset.push([ '', // moduleName
                            varName,
                            refValue, // reference
                            value,
                            refDiff, // change
                            rec.units[locale],
                            rec.print,
                            rec.labels.sort
                        ]);
                        n++;
                    } // printMe
                } // variables
                repLen = repDataset.length;
                if (repLen > 0) {
                    repDataset.sort(this.__sortByVarName);
                    for (i=0; i<repLen; i++) {
                        dataSet.push(repDataset[i]);
                    }
                }
            } // reports

            this.tableModel.setData(dataSet);
            this.__excelButton.setEnabled(true);
            this.__pdfButton.setEnabled(true);
            if (reportName == 'KtLU') {
                this.__submitButton.setEnabled(true);
            }
            else {
                this.__submitButton.setEnabled(false);
            }
        },

        __clearTable: function() {
            this.tableModel.setData(new Array);
            this.selectMenu.clearSelection();
            this.__excelButton.setEnabled(false);
            this.__pdfButton.setEnabled(false);
            this.__submitButton.setEnabled(false);
        },

        __updateMenu: function(msg) {
            if (msg.getData() != null) {
                this.resultData = msg.getData().sort(this.__sortByOrder);
            }
            else {
                this.debug('__createMenu: msg=null');
            }

            this.selectMenu.update(this.resultData);
        },

        __appear: function() {
            if ( ! (this.referenceData.isValid() && this.outputData.isValid()) ) {
                this.selectMenu.setEnabled(false);
                this.selectLabel.setEnabled(false);
                this.__clearTable();
            }
            this.__outputPending = 0;
            qx.event.message.Bus.dispatchByName('agrammon.PropTable.stop');
            if ( ! this.referenceData.isValid() ) {
                this.__logAreaReference.setLabel(null);
                this.busyIcon.setIcon('agrammon/nh3-rotate.gif');
                this.__outputPending++;
                this.debug('Getting reference data');
                this.debug('Output pending: ' + this.__outputPending);
                qx.event.message.Bus.dispatchByName('agrammon.Output.getReference');
            }
            if (! this.outputData.isValid()) {
                this.__logAreaOutput.setLabel(null);
                this.busyIcon.setIcon('agrammon/nh3-rotate.gif');
                this.__outputPending++;
                this.debug('Getting output data');
                this.debug('Output pending: ' + this.__outputPending);
                qx.event.message.Bus.dispatchByName('agrammon.Output.getOutput');
            }
        },

        __dataReady: function(msg) {
            this.__outputPending--;
            var dataset = msg.getData();
            this.debug('Received: ' + dataset);
            this.debug('Output pending: ' + this.__outputPending);
            if (this.__outputPending == 0) {
                this.busyIcon.setIcon('agrammon/nh3.png');
                this.selectMenu.setEnabled(true);
                this.selectLabel.setEnabled(true);
            }
            var logText, log;
            if (dataset == 'output') {
                log = this.outputData.getLog();
            }
            else {
                log = this.referenceData.getLog();
            }
            if (log != '' && log != null && log != undefined) {
                logText = agrammon.module.output.Output.formatLog(log, 'html');
            }
            else {
                logText = null;
            }
            if (dataset == 'output') {
                this.__logAreaOutput.setLabel(logText);
            }
            else {
                this.__logAreaReference.setLabel(logText);
            }
        },

        __changeLanguage: function() {
            this.__clearTable();
        },

        __enabled: function(msg) {
            this.setEnabled(msg.getData());
        }

    }
});

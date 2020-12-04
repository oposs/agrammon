/* ************************************************************************

************************************************************************ */

/**
 * @asset(agrammon/info.png)
 * @asset(agrammon/nh3.png)
 * @asset(agrammon/nh3-rotate.gif)
 */


qx.Class.define('agrammon.module.output.Graphs', {
    extend: qx.ui.tabview.Page,

    construct: function (outputData, referenceData) {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox(5));
        this.set({label: this.tr("Graphical Results"), enabled: false});

        this.__info = agrammon.Info.getInstance();
        this.outputData = outputData;
        this.referenceData = referenceData;

        qx.locale.Manager.getInstance().addListener("changeLocale",
                                                    this.__changeLanguage,
                                                    this);
        qx.event.message.Bus.subscribe('agrammon.Graphs.clear',
                                       this.__clearGraph, this);
        qx.event.message.Bus.subscribe('agrammon.Graphs.createMenu',
                                       this.__updateMenu, this);
        qx.event.message.Bus.subscribe('agrammon.Output.dataReady',
                                       this.__dataReady, this);
        qx.event.message.Bus.subscribe('agrammon.outputEnabled',
                                        this.__enabled, this);
        this.addListener("appear", this.__appear, this);

        this.__busyIcon = new qx.ui.basic.Atom('','agrammon/nh3.png');

        // Output selection
        var selectLabel = new qx.ui.basic.Label(this.tr("Choose table: "));
        this.selectLabel = selectLabel;

        this.selectMenu  = new qx.ui.form.SelectBox();
        this.selectMenu  =
            new agrammon.module.output.OutputSelector(qx.lang.Function.bind(this.__getOutputData, this));

        var selectRow =
            new qx.ui.container.Composite(new qx.ui.layout.HBox().set({
                spacing: 20})).set({
                  padding: 0
            });

        selectRow.add(this.__busyIcon);
        selectRow.add(selectLabel);
        selectRow.add(this.selectMenu);
        this.add(selectRow, {flex : 0});

        var graphBox =
            new qx.ui.container.Composite(new qx.ui.layout.VBox(5));
        graphBox.setMinHeight(300);
        this.__graphBox = graphBox;
        this.add(graphBox, {flex:1});
        var logBox = new qx.ui.groupbox.GroupBox(this.tr("Simulation log"), 'agrammon/info.png');
        var scroll = new qx.ui.container.Scroll().set({
            maxHeight: 200,
            height: null,
            allowShrinkY: true
        });

        logBox.setLayout(new qx.ui.layout.VBox(5));
        this.__logAreaOutput = new qx.ui.basic.Atom();
        this.__logAreaOutput.set({rich: true});
        scroll.add(this.__logAreaOutput);
        logBox.add(scroll);
        this.__logAreaReference = new qx.ui.basic.Atom();
        this.__logAreaReference.set({rich: true});
        logBox.add(this.__logAreaReference);
        this.__logAreaReference.exclude();
        this.add(logBox);

        this.pie = function(dataset, title) {
            var data = new Array;
            var len = dataset.length;
            var i;
            // transform data for jqplot pie chart
            for (i=0; i< len; i++) {
                // FIX ME: where is undefined coming from?
                data.push([dataset[i]['label'].replace(/undefined/,''), Number(dataset[i]['data'])]);
            }
            if (this.__currentGraph != null) {
                graphBox.remove(this.__currentGraph);
            }
            this.__currentGraph = new qxjqplot.Plot(
                [data], function($jqplot){return {
                    title: { text: title, fontSize: '12pt'},
                    seriesDefaults: {
                        renderer:        $jqplot.PieRenderer,
                        rendererOptions: {sliceMargin:6, shadow:true}
                    },
                    legend: {show:true, fontSize: '8pt'}
                };},
                ['pieRenderer']
            );
//            this.add(this.__currentGraph, {flex:1});
            graphBox.add(this.__currentGraph, {flex:1});
        };

        this.bar = function(dataset, refDataset, title) {
            var data = new Array;
            var labels = new Array;
            var len = dataset.length;
            var i, xTicks;
            var refLabelValue, dataLabelValue;
            // transform data for jqplot bar graph
            var y, ry, maxY=0;
            var re;
            if (this.refDatasetName != null && this.refDatasetName != '-') {
                this.debug('refDatasetName='+this.refDatasetName);
                for (i=0; i<len; i++) {
                    y  = Number(dataset[i]['data']);
                    ry = Number(refDataset[i]['data']);
                    if (maxY < y) {
                        maxY = y;
                    }
                    if (maxY < ry) {
                        maxY = ry;
                    }
                    data.push([ry, y]);
                    refLabelValue = refDataset[i]['label'];
                    if (refLabelValue == '') { // no corresponding reference value
                        refLabelValue = dataset[i]['label'];
                    }
                    dataLabelValue = dataset[i]['label'].split(/: /)[1];
                    labels.push({label: refLabelValue + ' --- ' + dataLabelValue});
                }
                xTicks = [this.refDatasetName, this.datasetName, ' '];
                re = /.+: ([\d\.]+) (.+) ---/;
            }
            else {
                for (i=0; i<len; i++) {
                    y = Number(dataset[i]['data']);
                    if (maxY < y) {
                        maxY = y;
                    }
                    data.push([y]);
                    // FIX ME: where is undefined coming from?
                    labels.push({label: dataset[i]['label'].replace(/undefined/,'')});
                }
                xTicks = [this.datasetName, ' '];
                re = /.+: ([\d\.]+) (.+)/;
            }
            this.debug('maxY='+maxY);
            // FIX ME: should pass unit from outside, I guess ...
            //         The regex match only works with integers ...
            re.exec(labels[0].label);
            var unit = RegExp.$2;
            if (unit == undefined || 'undefined') {
                this.debug('unit='+unit+', label='+labels[0].label);
                unit='';
            }

            var logMaxY = Math.log(maxY)/Math.log(10);
            this.debug('logMaxY='+logMaxY);
            var dY=1;
            for (i=0; i < (logMaxY-1); i++) {
                dY = dY*10;
            }
            maxY = maxY + dY;
            this.debug('maxY='+maxY+', dY='+dY+', nTicks='+nTicks);
            maxY = Math.floor(maxY/dY)*dY;
            var nTicks = maxY/dY;
            if (nTicks<5) {
                nTicks *= 2;
            }
            nTicks++;
            this.debug('maxY='+maxY+', dY='+dY+', nTicks='+nTicks);
            if (nTicks>11) {
                nTicks = 11;
            }
            if (this.__currentGraph != null) {
                graphBox.remove(this.__currentGraph);
            }
            this.__currentGraph = new qxjqplot.Plot(
                data,
                function($jqplot){
//                    $jqplot.config.enablePlugins = true;
                    return {
                    legend: {show:true, location:'ne', fontSize: '8pt'},
                    title:  { text: title, fontSize: '12pt'},
                    seriesDefaults: {
                        renderer:$jqplot.BarRenderer,
                        rendererOptions:{barPadding: 8, barMargin: 20}
                    },
                    series: labels,
                    axes: {
                        xaxis:{
                            tickOptions: {
                                enableFontSupport: true,
                                fontFamily: 'Georgia',
                                fontSize: '10pt'
                            },
                            renderer: $jqplot.CategoryAxisRenderer,
                            ticks: xTicks,
                            enableFontSupport: true,
                            fontSize: '10pt'
                        },
                        yaxis:{
                            numberTicks: nTicks,
                            tickOptions: {
                                formatString: '%.0f',
                                enableFontSupport: true,
                                fontFamily: 'Georgia',
                                fontSize: '10pt'
                            },
                            labelRenderer: $jqplot.CanvasAxisLabelRenderer,
                            labelOptions: {
                                enableFontSupport: true,
                                fontFamily: 'Georgia',
                                fontSize: '12pt'
                            },

                            label: 'y-axis',
                            fontSize: '10pt',
                            min:0, max: maxY}
                    },
                    cursor: {zoom: true, clickReset: true, show: true,
                             useAxesFormatters: false,
                             showTooltip:true,
                             // show only y-value
                             tooltipFormatString: '%.0s %.0f ' + unit,
//                                           tooltipAxisGroups:  [['yaxis','yaxis']],
                             followMouse: true
                            }
                 };},
                ['barRenderer', 'categoryAxisRenderer',
                 'canvasTextRenderer','canvasAxisLabelRenderer',
                 'canvasAxisTickRenderer', 'cursor'
                ]
            );
//            this.add(this.__currentGraph, {flex:1});
            graphBox.add(this.__currentGraph, {flex:1});
        };


        return this;
    }, // construct

    members :
    {
        bar: null,
        pie: null,
        datasetName: null,
        __currentGraph: null,
        __info: null,
        resultData: null,
        outputData: null,
        referenceData: null,
        __busyIcon: null,
        selectMenu: null,
        __graphBox: null,
        __logAreaOutput: null,
        __logAreaReference: null,

        __sortByVarName: function (a,b) {
            var x = a['order'];
            var y = b['order'];
            return ((x < y) ? -1 : ((x > y) ? 1 : 0));
        },

        __sortByOrder: function (a,b) {
            var x = a['order'];
            var y = b['order'];
            return x - y;
        },

 	/**
	  * @ignore(TAGS)
	  * @lint ignoreDeprecated(alert)
	  */
       __getOutputData:  function(e) {
                if (! e.getData()[0]) {
                    return;
                }
                if ( !(this.outputData.isValid()
                       && this.referenceData.isValid) ) {
                    return;
                }

                var reportTitle = e.getData()[0].getLabel();

                var reportName = this.selectMenu.getSelection()[0].getModel();

                var ri, rdlen;
                var dataSet = new Array;
                var refDataSet = new Array;
                rdlen = this.resultData.length;
                var found = false;
                for (ri=0; ri<rdlen; ri++) {
                    if (this.resultData[ri]['name'] ==  reportName) {
                        found = true;
                        break;
                    }
                }

                if (! found) {
                    this.debug('__getOutputData: no matching report for '
                               +reportName);
//                    this.tableModel.setData(dataSet);
                    return;
                }
                var reports = this.resultData[ri]['data'];
                var graphType = this.resultData[ri]['type'];
                var subReports;
                var r, sr, srlen;
                var rlen = reports.length;
                this.datasetName = this.__info.getDatasetName();
                this.refDatasetName = this.__info.getRefDatasetName();

                var i, rec, refRec, varName, value, refValue,
                    printMe, repLen, legend, refLegend;
                var data = new Array;
                var refData = new Array;
                data = this.outputData.getDataset();
                refData = this.referenceData.getDataset();

                var len = data.length;
                var n=0;
                var title, currentTitle='';
                var printTag = '';
                var tags, tlen, t;
                var repDataset, repRefDataset, report;
                var locale = qx.locale.Manager.getInstance().getLocale();
                locale = locale.replace(/_.+/,'');
                for (r=0; r<rlen; r++) { // reports selected
                    report = String(reports[r]['label']);
//                    this.debug('report=' + report);

                    subReports = reports[r]['subReports'];
                    srlen = subReports.length;
                    currentTitle='';
                    if (reports[r][locale] != null)  {
                        title = reports[r][locale];
                    }
                    else {
                        title = reports[r]['en'];
                    }
                    repDataset = new Array;
                    repRefDataset = new Array;
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
                            varName = 'unknown';
                            if (rec.labels) {
                                varName = String(rec.labels[locale]);
                            }
                            else {
                                varName = rec['var'];
                            }
                            value = rec.value;
                            legend = varName + ': ' + value + ' ' + rec.units[locale];
                            if (refRec != null) {
                                refValue = refRec.value;
                                refLegend = varName + ': ' + refValue + ' ' + rec.units[locale];
                            }
                            else {
                                refValue = 0;
                                refLegend = '-';
                            }
                            if (   ((graphType == 'pie') && (value > 0))
                                || (graphType == 'bar') ) {
                                repDataset.push({data: value,
                                                 label: legend,
                                                 order: rec.labels.sort});
                                repRefDataset.push({data: refValue,
                                                    label: refLegend,
                                                    order: rec.labels.sort});
                                n++;
                            }
                        } // printMe
                    } // variables
                    repLen = repDataset.length;
                    if (repLen > 0) {
                        repDataset.sort(this.__sortByVarName);
                        repRefDataset.sort(this.__sortByVarName);
                        for (i=0; i<repLen; i++) {
                            dataSet.push(repDataset[i]);
                            refDataSet.push(repRefDataset[i]);
                        }
                    }
                } // reports
//                this.debug('selectMenu: ' + n + ' output variables selected');

                switch (graphType) {
                case 'bar':
                    this.bar(dataSet, refDataSet, reportTitle);
                    break;
                case 'pie':
                    this.pie(dataSet, reportTitle);
                    break;
                default:
                    alert(graphType + ' not yet implemented');
                    break;
                }

                return;
        },

        __clearGraph: function() {
            if (this.__currentGraph != null) {
                this.__graphBox.remove(this.__currentGraph);
                this.__currentGraph = null;
                this.selectMenu.clearSelection();
            }
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

        __appear: function(e) {
            if ( !(this.outputData.isValid() && this.referenceData.isValid()) ) {
                this.selectMenu.setEnabled(false);
                this.selectLabel.setEnabled(false);
                this.__logAreaOutput.setLabel(null);
                this.__logAreaReference.setLabel(null);
                this.__clearGraph();
            }
            qx.event.message.Bus.dispatchByName('agrammon.PropTable.stop');
            if ( ! this.referenceData.isValid() ) {
                this.__busyIcon.setIcon('agrammon/nh3-rotate.gif');
                qx.event.message.Bus.dispatchByName('agrammon.Output.getReference');
            }
            if (! this.outputData.isValid()) {
                this.__busyIcon.setIcon('agrammon/nh3-rotate.gif');
                qx.event.message.Bus.dispatchByName('agrammon.Output.getOutput');
            }
        },

        __dataReady: function(msg) {
//            var dataset = msg.getData();
            this.__busyIcon.setIcon('agrammon/nh3.png');
            this.selectMenu.setEnabled(true);
            this.selectLabel.setEnabled(true);
            var logText, log;
	    log = this.outputData.getLog();
//	    this.debug('log='+log);
            if (log != '' && log != null && log != undefined) {
                logText = agrammon.module.output.Output.formatLog(log, 'html');
	    }
	    else {
	    	 logText = null;
	    }
//	    this.debug('logText='+logText);
	    this.__logAreaOutput.setLabel(logText);
        },

        __changeLanguage: function() {
            this.__clearGraph();
        },

        __enabled: function(msg) {
            this.setEnabled(msg.getData());
        }

    }
});



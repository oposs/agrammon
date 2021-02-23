/* ************************************************************************

************************************************************************ */

qx.Class.define('agrammon.module.output.Output', {
    extend: qx.core.Object,

        /**
          * TODOC
          *
          * @return {var} TODOC
          * @lint ignoreDeprecated(alert)
          */
    construct: function (reference) {
        this.base(arguments);
        // qx.locale.Manager.getInstance().addListener("changeLocale",
        //                                             this._update, this);
        var that = this;
        this.__info = agrammon.Info.getInstance();
        this.__rpc  = agrammon.io.remote.Rpc.getInstance();
        this.__reference = reference;

        this.outputIsValid = false;

        if (reference) {
            qx.event.message.Bus.subscribe('agrammon.Output.getReference',
                                           this.__getOutput, this);
            qx.event.message.Bus.subscribe('agrammon.Reference.invalidate',
                                           this.__setInValid, this);
        }
        else {
            qx.event.message.Bus.subscribe('agrammon.Output.getOutput',
                                           this.__getOutput, this);
            qx.event.message.Bus.subscribe('agrammon.Output.invalidate',
                                           this.__setInValid, this);
        }

        this.getOutputFunc = function(data,exc,id) {
            that.__running = false;
            that.__rpc.setTimeout(that.__oldTimeout);
            if (exc == null) {
                var pid = data.pid;
                var session = data.sessionid;
                var result = data.data;
                var i;
                var len = result.length;
                var dataSet = new Array;
                for (i=0; i<len; i++) {
                    dataSet.push(result[i]);
                }
                that.outputData = dataSet;
                that.referenceData = dataSet;
                that.outputPid = pid;
                that.outputSession = session;
                that.outputIsValid = true;
                that.__outputLog = data.log;
            }
            else {
                alert(exc);
            }
            var msg;
            if (that.__reference) {
                msg = 'reference';
            }
            else {
                msg = 'output';
            }
            qx.event.message.Bus.dispatchByName('agrammon.Output.dataReady', msg);
        };

        return this;
    }, // construct

    statics :
    {

        formatLog: function(logData, format) {
            var locale = qx.locale.Manager.getInstance().getLocale();
            locale = locale.replace(/_.+/,'');
            var i, len = logData.length;
            var logText = '';
            if (format == 'html') {
                logText += "<ul>";
            }
            for (i=0; i<len; i++) {
                if (format == 'html') {
//                    if (logData[i]['msg']) {
//                        logText += '<li><b>'+logData[i]['msg'][locale]+'</b></li>';
//                    }
                    logText += '<li>'+logData[i][locale]+'</li>';
                }
                else { // FIX ME: remove this (but fix in submit() first (Kantonalmodell)
//                    logText += '\\verbdef\\varTitle{' + logData[i]['msg'][locale]+ '}';
//                    logText += '\\verbdef\\varDesc{'  + logData[i]['var']        + '}';
//                    logText += '\\mbox{ }\\newline (\\varDesc)';
                    logText += '\\verbdef\\varTitle{' + logData[i][locale]+ '}';
                    logText += '\\item[\\varTitle]';
                }
            }
            if (format == 'html') {
                logText += "</ul>";
            }

            return logText;
        }
    },


    members :
    {
        __running: false,
        __oldTimeout: null,
        getOutputFunc: null,
        outputIsValid: null,
        outputData: null,
        referenceData: null,
        outputPid: null,
        outputSession: null,
        __info: null,
        __rpc: null,
        __reference: null,
        __outputLog: null,

        isValid: function() {
            return this.outputIsValid;
        },

        __setInValid: function() {
          if (this.outputIsValid) {
              this.outputIsValid = false;
              qx.event.message.Bus.dispatchByName('agrammon.Graphs.clear');
              qx.event.message.Bus.dispatchByName('agrammon.Reports.clear');
              this.__outputLog = null;
          }
        },

        getDataset: function() {
            return this.outputData;
        },

        getLog: function() {
            return this.__outputLog;
        },

        getPid: function() {
            return this.outputPid;
        },

        getSession: function() {
            return this.outputSession;
        },

        __getOutput: function(msg) {
            if (this.__running) {
                this.debug('__getOutput(): already running');
                return;
            }
            this.__running = true;
            this.debug('__getOutput(): starting calculation');
            this.outputIsValid = false;
//            var dataset = msg.getData();
            var datasetName;
            if (this.__reference) {
                datasetName = this.__info.getRefDatasetName();
            }
            else {
                datasetName = this.__info.getDatasetName();
            }
            if (datasetName == '-' || datasetName == undefined) {
                this.outputData = null;
                // FIX ME: this is a bit counter intuitive
                this.outputIsValid = true;
                if (this.__reference) {
                    msg = 'reference';
                }
                else {
                    msg = 'output';
                }
                qx.event.message.Bus.dispatchByName('agrammon.Output.dataReady', msg);
                return;
            }
            this.__oldTimeout = this.__rpc.getTimeout();
            this.__rpc.setTimeout(600*1000);  // 10 minutes CPU limit
            this.__rpc.callAsync(this.getOutputFunc, 'get_output_variables', { datasetName: datasetName} );
            return;
        }

    }
});

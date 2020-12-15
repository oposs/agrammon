/* ************************************************************************

   Agrammon

   http://agrammon.ch/

   Authors:
     * Fritz Zaucker

************************************************************************ */
/* ************************************************************************

************************************************************************ */
/**
 * Store for the users' datasets.
 */

qx.Class.define('agrammon.module.dataset.DatasetCache',
{
    extend: qx.core.Object,
    type: 'singleton',

     /**
       * TODOC
       *
       * @return {var} TODOC
       * @lint ignoreDeprecated(alert)
       */
    construct: function () {
        this.base(arguments);
        var that = this;
        var rpc = agrammon.io.remote.Rpc.getInstance();
        this.__datasets = [];

        // FIX:  abort pending async calls
        //   if (this.__locationCalls != null) {
        //       this._rpc.abort(this.__locationCalls);
        //   }
        qx.event.message.Bus.subscribe('agrammon.DatasetCache.refresh', function(msg) {
            var user = msg.getData();
            this.debug('Called DatasetCache.refresh: user='+user);
            qx.event.message.Bus.dispatchByName('Agrammon.datasetsLoading');
            rpc.callAsync( this.__getDatasets, 'get_datasets');
            rpc.callAsync( this.__getTags,     'get_tags');
        }, this);

        /**
         * Callback for loading the dataset table
         * @param data {Array} data returned from the JSON RPC call.
         * @param exc {String} exception string.
         * @param id {Integer} reference id for the RPC call.
         */
        this.__getDatasets = function(data,exc,id){
            if (exc == null) {
                that.debug('__getDatasetCache(): '+data.length+' datasets loaded.');
//                console.log('data=', data);
                var i, len = data.length;
                let datasets = [];
                for (i=0; i<len; i++) {
                    // TODO: why is this necessary???
                    // skip datasets without name
                    if (!data[i][0]) continue;
                    data[i][0] = '' + data[i][0];
//                    console.log('   adding', data[i][0]);
                    datasets.push(data[i]);
                }
                that.__datasets = datasets;
//                console.log('datasets=', datasets);
                qx.event.message.Bus.dispatchByName('Agrammon.datasetsLoaded');
            }
            else {
                alert(exc);
            }
        };

        /**
         * Callback for loading the dataset tag table
         * @param data {Array} data returned from the JSON RPC call.
         * @param exc {String} exception string.
         * @param id {Integer} reference id for the RPC call.
         */
        this.__getTags = function(data,exc,id){
            if (exc == null) {
                // that.debug('DatasetCache(): '+data.length+' tags loaded.');
                that.__tags = data;
                qx.event.message.Bus.dispatchByName('Agrammon.tagsLoaded');
            }
            else {
                alert(exc);
            }
        };

        return this;

    },

    members:
    {
        __getDatasets: null,
        __datasets: null,
        __tags: null,
        __getTags: null,

        /**
        * Is the current selection valid.
        */
        isValid: function(){
            return true;
        },

        tagExists: function(tag) {
            var i;

            var len = this.__tags.length;
            for (i=0; i<len; i++) {
                if (this.__tags[i] === tag) {
                    return true;
                }
            }
            return false;
        },

        datasetExists: function(dataset) {
            var i;

            var len = this.__datasets.length;
            for (i=0; i<len; i++) {
                if (this.__datasets[i][0] === dataset) {
                    return true;
                }
            }
            return false;
        },

        /**
        * Get the datasets.
        */
        getDatasets: function(){
            console.log('getDatasets(): __datasets=', this.__datasets);
            return this.__datasets;
        },

        /**
        * Get the dataset tags.
        */
        getTags: function(){
            return this.__tags;
        },

        /**
        * Rename a  tag.
        */
        renTag: function(oldTag, newTag){
            // FIX ME: handle tags in datasets
            var i, len = this.__tags.length;
            for (i=0; i<len; i++) {
                if (this.__tags[i] == oldTag) {
                    this.__tags[i] = newTag;
                    break;
                }
            }
            return this.__tags;
        },

        /**
        * Create a new tag.
        */
        newTag: function(tag){
            this.__tags.push(tag);
            return this.__tags;
        },

        /**
        * Del a tag.
        */
        delTag: function(tag){
            // FIX ME: handle tags in datasets
//            this.debug('Datasets.delTag: tag=' + tag );
            var i, len = this.__tags.length;
            for (i=0; i<len; i++) {
                if (this.__tags[i] == tag) {
//                    this.debug('Datasets.delTag: i=' + i );
                    this.__tags.splice(i,1);
                    break;
                }
            }
            return this.__tags;
        }

    }
});

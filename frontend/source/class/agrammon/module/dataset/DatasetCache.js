/* ************************************************************************

   Agrammon

   http://agrammon.ch/

   Authors:
     * Fritz Zaucker

************************************************************************ */

/**
 * Store for the users' datasets.
 */

qx.Class.define('agrammon.module.dataset.DatasetCache', {
    extend: qx.core.Object,
    type: 'singleton',

     /**
       * TODOC
       *
       * @return {var} TODOC
       * @lint ignoreDeprecated(alert)
       */
    construct: function() {
        this.base(arguments);
        var that = this;
        var rpc = agrammon.io.remote.Rpc.getInstance();
        this.__datasets = [];
        this.__loading = false;

        qx.event.message.Bus.subscribe('agrammon.DatasetCache.refresh', function(msg) {
            if (this.__loading) return;
            this.__loading = true;
            var user = msg.getData();
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
                that.__datasets = data;
                this.__loading = false;
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
                that.__tags = data;
                qx.event.message.Bus.dispatchByName('Agrammon.tagsLoaded');
            }
            else {
                alert(exc);
            }
        };

        return this;

    },

    members: {
        __getDatasets: null,
        __datasets: null,
        __tags: null,
        __getTags: null,
        __loading: null,

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
            var i, len = this.__tags.length;
            for (i=0; i<len; i++) {
                if (this.__tags[i] == tag) {
                    this.__tags.splice(i,1);
                    break;
                }
            }
            return this.__tags;
        }

    }
});

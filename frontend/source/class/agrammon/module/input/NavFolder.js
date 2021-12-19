/* ************************************************************************

************************************************************************ */

/**
 * @asset(agrammon/*)
 */


qx.Class.define('agrammon.module.input.NavFolder', {
    extend: qx.ui.tree.TreeFolder,

    construct: function (labels, type, data, folderName, instanceOrder) {
        this.base(arguments);
        this.__labels = {};
        for (var key in labels) {
            // remove instance marker
            this.__labels[key]  = String(labels[key]).replace(/\[\]/, '');
        }
        // FIX ME: deal with sub locale
        var locale = qx.locale.Manager.getInstance().getLocale();
        locale = locale.replace(/_.+/,'');

        // FIX ME: this is a hack, should be fixed in model descriptions
        if (locale == 'en' && this.__labels['it']) {
            this.setLabel(this.__labels['it']);
        }
        else {
            this.setLabel(this.__labels[locale]);
        }

        qx.locale.Manager.getInstance().addListener("changeLocale", function() {
            var locale = qx.locale.Manager.getInstance().getLocale();
            locale = locale.replace(/_.+/,'');
            // FIX ME: this is a hack, should be fixed in model descriptions
            if (locale == 'en' && this.__labels['it']) {
                this.setLabel(this.__labels['it']);
            }
            else {
                this.setLabel(this.__labels[locale]);
            }
        }, this);

        if (type != 'isInstance') {
            this.setDraggable(false);
            this.setDroppable(false);
        }
        this.__type         = type;
        this.__folderName   = folderName;
        this.__propData     = new Array;
        this.__childrenHash = new Object;
        this.__instanceOrder = instanceOrder;
        if (data != null) {
            this.addData(data);
        }

        this.setIcon(null);
    }, // construct

    members :
    {
        __type: null,
        __parent: null,
        __folderName: null,
        __labels: null,
        __propData: null,
        __childrenHash: null,
        __instanceOrder: null,

        destruct : function() {
            this.__propData = null;
            this._disposeMap(this.__childrenHash);
            this.__childrenHash = null;
        },

        addData: function(newData) {
            this.__propData.push(newData);
            this.isComplete();
            return this.__propData.length;
        }, // addData

        getData: function(key) {
            this.debug('getData(): key=' + key);
            var i;
            var len = this.__propData.length;
            for (i=0; i<len; i++) {
                if (this.__propData[i].getName() == key) {
                    return this.__propData[i].getValue();
                }
            }
            return null;
        }, // getData

        getDataset: function() {
            return this.__propData;
        }, // getDataSet

        cloneDataset: function(newLabel) {
            var i, len=this.__propData.length;
            var varNew, varOld, newData = new Array;
            for (i=0; i<len; i++) {
                varOld = this.__propData[i];
                varNew = varOld.clone(varOld.getName().replace(/\[.*\]/, newLabel));
                newData.push(varNew);
            }
            return newData;
        }, // cloneDataset

        getLabels: function(key) {
            return this.__labels;
        }, // getLabels

        setType: function(type) {
            this.__type = type;
        }, // setType

        getType: function() {
            return this.__type;
        }, // getType

        getOrder: function() {
            return this.__instanceOrder;
        }, // getOrder

        getName: function() {
            return this.__folderName;
        }, // getName

        __updateVariableNames : function(newInstanceName) {
            var data = this.__propData;
            for (let row of data) {
                let oldName = row.getName();
                let newName = oldName.replace(/\[.+\]/, '[' + newInstanceName + ']');
                row.setName(newName);
            }
        },

        setName: function(newName, propEditor) {
            this.__folderName = newName;
            this.__updateVariableNames(newName);
            // set this folders data in propEditor table
            propEditor.setData(this, this.__propData);
            this.setLabel(newName);
        }, // setName

        isInstance: function() {
            return (this.__type == 'isInstance');
        }, // isInstance

        canInstance: function() {
            return (this.__type == 'canInstance');
        }, // canInstance

        isSingleton: function() {
            return (this.__type == 'isSingleton');
        }, // isSingleton

        isPlain: function() {
            return (this.__type == 'isPlain' || this.__type == 'isTop');
        }, // isPlain

        isTop: function() {
            return (this.__type == 'isTop');
        }, // isTop

        isRoot: function() {
            return (this.__type == 'isRoot');
        }, // isRoot

        addChild: function(folder) {
            this.__childrenHash[folder.getName()] = folder;
        }, // addChild

        delChild: function(folder) {
            // this.debug('delChild(): deleting ' + folder.getName()
            //            + ' from ' + this.getName());
            delete this.__childrenHash[folder.getName()];
        }, // delChild

        getParentNavFolder: function(folder) {
            return this.__parent;
        }, // getParentNavFolder

        getRootNavFolder: function(folder) {
            var parent = folder.getParentNavFolder();
            if (parent.isRoot()) {
                return parent;
            }
            else {
                return this.getRootNavFolder(parent);
            }
        }, // getRootNavFolder

        setParentNavFolder: function(folder) {
            this.__parent = folder;
        }, // setParentNavFolder

        childrenCanInstance: function() {
            var key;
            for (key in this.__childrenHash) {
                if (this.__childrenHash[key].canInstance()) {
                    return true;
                }
            }
            return false;
        }, // childrenCanInstance

        childrenComplete: function(nset) {
            var key;
            var complete = undefined;
            var childComplete;
            var childName;

            var reallyUndefined = true;
            if (this.childrenCanInstance()) {
                // one false => false
                // one true, others undefined => true
                //this.debug('   childrenCanInstance');
                for (key in this.__childrenHash) {
                    childName = this.__childrenHash[key].getName();
                    childComplete = this.__childrenHash[key].isComplete();

                    if (reallyUndefined) { // first child
                        complete = childComplete;
                        reallyUndefined = false;
                    }
                    else {
                        if (childComplete == undefined) {
                            // stay as is complete (one true/false is enough)
                        }
                        else {
                            if (complete == undefined) {
                                complete = childComplete;
                            }
                            else {
                                complete = complete && childComplete;
                            }
                        }
                    }
                }
            }
            else {
                // one false => false
                // one undefined => false (or undefined)

                for (key in this.__childrenHash) {
                    childName = this.__childrenHash[key].getName();
                    childComplete = this.__childrenHash[key].isComplete();

                    if (reallyUndefined) { // first child
                        complete = childComplete;
                        reallyUndefined = false;
                    }
                    else {
                        if (childComplete == undefined) {
                            if (complete) {
                                complete = undefined;
                            }
                            else {
                                // make sure it stays false:
                                //    (false && undefined) == undefined
                                complete = false;
                            }
                        }
                        else {
                            complete = complete && childComplete;
                        }
                    }
                }
            }

            // no direct data
            if (this.isPlain()) {
                if (complete == undefined) {
                    this.setIcon('agrammon/grey-dot.png');
                    if (this.isTop()) {
                        complete = true;
                    }
                }
                else if (complete) {
                    this.setIcon('agrammon/green-dot.png');
                }
                else {
                    this.setIcon('agrammon/red-dot.png');
                }
            }
            if (this.canInstance()) {
                if (complete == undefined) {
                    this.setIcon('agrammon/empty-circle.png');
                }
                else if (complete) {
                    this.setIcon('agrammon/green-circle.png');
                }
                else {
                    this.setIcon('agrammon/red-circle.png');
                }
            }
            if (this.isRoot()) {
                if (nset !=0) {
                    if (complete != undefined) {
                        qx.event.message.Bus.dispatchByName('agrammon.outputEnabled', complete);
                    }
                }
            }
            return complete;
        }, // childrenComplete

        /**
          * TODOC
          *
          * @return {var} TODOC
          * @lint ignoreDeprecated(alert)
          */
        isComplete: function(nset) {

            if (this.canInstance()) { // no data here
                this.setIcon('agrammon/empty-circle.png');
            }

            if (! this.isInstance() && ! this.isSingleton()) {
                var childrenComplete = this.childrenComplete(nset);
                return childrenComplete;
            }

            if (this.__propData == null) {
                alert('this.__propData is null');
                return false;
            }

            var len = this.__propData.length;
            // no variables
            if (len == 0) {
                this.setIcon('agrammon/grey-dot.png');
                return false;
            }

            // not empty
            var complete = true;
            for (let i=0; i<len; i++) {
                let varName = this.__propData[i].getName();
                let metaData = {};
                if (!varName.match('ignore')) {
                    let value = this.__propData[i].getValue();
                    let defaultValue = this.__propData[i].getDefaultValue();
                    if (   (!value                     && defaultValue == null)
                           ||
                           (value === '*** Select ***' && defaultValue === '*** Select ***')
                    ) { // incomplete
                        complete = false;
                        break; // one false is enough
                    }
                    else if (value === 'branched') {
                        metaData = this.__propData[i].getMetaData();
                        if (!metaData.branches) {
                            complete = false;
                        }
                        else {
                            var total = 0;
                            for (var j=0; j<metaData.branches.length; j++) {
                                total += metaData['branches'][j];
                            }
                            // this.debug('isComplete(): total='+total);
                            if (total == 0) {
                                complete = false;
                            }
                        }
                    } // value === branched
                }
            }

            if (complete) {
                this.setIcon('agrammon/green-dot.png');
            }
            else {
                this.setIcon('agrammon/red-dot.png');
            }
            return complete;
        }, // isComplete

        /**
          * TODOC
          *
          * @return {var} TODOC
          * @lint ignoreDeprecated(alert)
          */
        setData: function(key, value, comment, noCheck, branch_values) {
            var i, ii, len, len2, option, found,
                options, metaData, msg;
            len = this.__propData.length;
            if (len == 0) {
//                this.debug('setData(): propData.length = '+len);
                return undefined;
            }
            for (i=0; i<len ; i++) {
                var varName = this.__propData[i].getName();
                if (varName == key) {

                    // check for enum changes between dataset and model
                    metaData = null;
                    metaData = this.__propData[i].getMetaData();
                    if (metaData == null) {
//                        this.debug('setData(): getMetaData() returned null');
                        metaData = {};
                    }
                    if (comment) {
                        this.__propData[i].setComment(comment);
                    }
                    if (value == undefined) {
                        value = this.__propData[i].getDefaultValue();
                    }
                    if (value == 'branched') {
                        metaData['branches'] = branch_values;
                        this.__propData[i].setMetaParameter('branches', branch_values);
                    }
                    if ( ! metaData['options'] ) { // simple data
                        if (value == undefined || value === '') {
                            value = null; // make sure it is not shown in cellRenderer
                        }
                        this.__propData[i].setValue(value);
                    }
                    else { // enum selector
                        value = '' + value;
                        value = value.replace(/\s+/g, '');
                        value = value.replace(/\'/g,'');
                        // TODO: remove if statement
                        if (value != '***Select***' && value != 'ignore') {
                            options = new Array();
                            found = false;
                            len2 = metaData['options'].length;
                            for (ii=0; ii<len2; ii++) {
                                options[ii] = metaData['options'][ii][2];
                                option = options[ii];
                                option = option.replace(/\s*/g, '');
                                option = option.replace(/\'/g, '');
                                // FIX ME: ignore check can be removed, I guess (Fritz, 2012-10-11)
                                if (option == value || value == 'flattened' || value == 'branched' || value == 'ignore') {
                                    found = true;
                                    break;
                                }
                            }
                            if (found) {
                                this.__propData[i].setValue(value);
                            }
                            else {
                                this.debug('No match: key='+key+', var='+this.__propData[i].getName());
                                msg = this.__propData[i].getName() + ': ';
                                if (value == '') {
                                    msg += ' empty variable,';
                                }
                                else {
                                    msg += ' no match for >' + value + '< in'
                                         + ' >' + options + '<';
                                }
                                msg += ', should be removed from dataset.';
                                alert(msg);
                                qx.event.message.Bus.dispatchByName('agrammon.NavBar.deleteInstanceData', this.__propData[i].getName());
                            }
                        }
                    } // selector
                    if (noCheck) {
                        return true;
                    }
                    else {
                        this.getRootNavFolder(this).childrenComplete();
                        return true;
                    }
                    break; // there should only be one match; FIX ME: check?
                }
                else {
//                    this.debug('No match: key='+key+', var='+this.__propData[i].getName());
                }
            }
            return undefined;
        }, // setData

        insertData: function(key, value, noCheck, pos) {
            var oldVar = this.__propData[pos-1];
            key.match(/.+_flattened(\d?\d?)_(.+)$/);
            var i = RegExp.$1;
            var f = RegExp.$2;
            var labels = oldVar.getOptionLabels(f);
            var newVar = oldVar.clone(key);
            // flattened inputs are percentages not enum as their parent
            newVar.setType('percent');
            newVar.setDefaultValue(null);
            newVar.setValue(value);
            newVar.setLabels(labels);
            newVar.setUnits({en: '%', de: '%', fr: '%'});
            newVar.setHelpIcon(null);
            newVar.setHelpFunction(null);
            newVar.setMetaData({type: 'percent'});
            // flattened inputs come after parent
            newVar.setOrder(oldVar.getOrder()+Number(i)+1);
            if (pos>this.__propData.length) {
                this.__propData.push(newVar);
            }
            else {
                this.__propData.splice(pos,0,newVar);
            }
            // FIX ME: comments?
            this.setData(key, value, null, noCheck, null);
        },

        setDataset: function(newData, handleIgnore, storeAll) {
            var i;
            this.__propData = new Array;
            var len = newData.length;
            // FIX ME
            var noCheck = true;
            var data;
            for (i=0; i<len; i++) {
                data = newData[i];
                var name = data.getName();
                var value = data.getValue();
                var comment = data.getComment();
                var meta = data.getMetaData();
                this.__propData.push(data);
                // prevent default value (*** Select ***) on instance creation
                if (name.match(/_flattened/) && value === null) {
                    value = '';
                }
                if (storeAll) {
                    if (handleIgnore && name.match(/::ignore/)) { // FIX ME
                        this.setData(name, 'ignore', null, noCheck, null);
                        qx.event.message.Bus.dispatchByName('agrammon.PropTable.storeData',
                                                            { 'var':    name,
                                                              value:    'ignore',
                                                              branches: meta.branches,
                                                              options:  meta.options
                                                            });
                    }
                    else {
                        qx.event.message.Bus.dispatchByName('agrammon.PropTable.storeData',
                                                            { 'var':    name,
                                                              value:    value,
                                                              branches: meta.branches,
                                                              options:  meta.options
                                                            });
                        this.setData(name, value, comment, noCheck, meta.branches);
                    }
                }

                if (handleIgnore && name.match(/::ignore/)) { // FIX ME
                    this.setData(name, 'ignore', null, noCheck, null);
                    qx.event.message.Bus.dispatchByName('agrammon.PropTable.storeData',
                                                        { 'var':    name,
                                                          value:    'ignore',
                                                          branches: meta.branches,
                                                          options:  meta.options
                                                        });
                }
            }

            this.isComplete();
            // This must be done outside!
            // this.rootFolder.isComplete();
            return this.__propData.length;
        }, // setDataSet

        /**
         * Add a tree item to this item before the existing child <code>before</code>.
         *
         * @param treeItem {AbstractTreeItem} tree item to add
         * @param before {AbstractTreeItem} existing child to add the item before
         */
        addBefore : function(treeItem, before) {
            var parent  = before.getParentNavFolder();
            if ((qx.core.Environment.get("qx.debug"))) {
                this.assert(parent.getChildren().indexOf(before) >= 0);
            }
            var it = parent.getChildren().indexOf(treeItem);
            var ib = parent.getChildren().indexOf(before);
            if (it>ib) {
                parent.addAt(treeItem, ib);
            }
            else {
                parent.addAt(treeItem, ib-1);
            }
        }

    }

});

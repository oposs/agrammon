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
        // #420: the instance name is the single source of truth for this
        // folder's instance. Derive it from the folderName here (e.g.
        // "Module[Stall 1]" -> "Stall 1"); updated on rename in setName.
        // null for singleton / non-instance folders.
        var instMatch = ('' + folderName).match(/\[(.*)\]/);
        this.__instanceName = instMatch ? instMatch[1] : null;
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
        __instanceName: null,
        __labels: null,
        __propData: null,
        __childrenHash: null,
        __instanceOrder: null,
        // Tracks whether any input under this folder currently holds a value
        // that was display-mapped from a foreign-version enum alias. Drives
        // the orange dot/circle in the navbar. Session-only; never persisted.
        __mapped: false,

        isMapped: function() {
            return this.__mapped;
        },

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
                // #431: a flattened option row identifies its marker via the
                // flattenedOf metadata pointer (a full var name carrying the
                // instance label). clone() only renames the var's own name, so
                // re-point flattenedOf to the new instance too — otherwise the
                // copied rows still reference the SOURCE marker, setDataset
                // splits marker and rows into separate groups, and the copied
                // instance is persisted with no flattened table rows (the
                // marker then reloads as a bare enum Select).
                var meta = varNew.getMetaData();
                if (meta && meta.flattenedOf) {
                    meta.flattenedOf = meta.flattenedOf.replace(/\[.*\]/, newLabel);
                    varNew.setMetaData(meta);
                }
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

        setName: function(newName, propEditor) {
            this.__folderName = newName;
            // #420: the folder is the single source of truth for its instance.
            // Record the new instance here; resolveVariable() re-qualifies the
            // (instance-free) variable names against it on demand, so we no
            // longer rewrite the [instance] into every variable name on rename
            // (the old __updateVariableNames workaround).
            this.__instanceName = newName;
            // rebuild this folder's data in the propEditor table
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

            // Aggregate mapped state from children: any descendant input
            // holding a foreign-version alias makes this folder orange-when-
            // otherwise-green. Missing data still wins (red), since orange
            // is informational and must not mask incomplete inputs.
            var mapped = false;
            for (key in this.__childrenHash) {
                if (typeof this.__childrenHash[key].isMapped === 'function'
                    && this.__childrenHash[key].isMapped()) {
                    mapped = true;
                    break;
                }
            }
            this.__mapped = mapped;

            // no direct data
            if (this.isPlain()) {
                if (complete == undefined) {
                    this.setIcon('agrammon/grey-dot.png');
                    if (this.isTop()) {
                        complete = true;
                    }
                }
                else if (!complete) {
                    this.setIcon('agrammon/red-dot.png');
                }
                else if (mapped) {
                    this.setIcon('agrammon/orange-dot.png');
                }
                else {
                    this.setIcon('agrammon/green-dot.png');
                }
            }
            if (this.canInstance()) {
                if (complete == undefined) {
                    this.setIcon('agrammon/empty-circle.png');
                }
                else if (!complete) {
                    this.setIcon('agrammon/red-circle.png');
                }
                else if (mapped) {
                    this.setIcon('agrammon/orange-circle.png');
                }
                else {
                    this.setIcon('agrammon/green-circle.png');
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
            var mapped = false;
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
                        // Don't break here: we still want to detect any mapped
                        // values further down the list so a single missing
                        // input doesn't suppress the orange signal once it
                        // gets filled in.
                        continue;
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
                    else {
                        // Mapped: stored value is a cross-version alias for
                        // one of the local enum keys. enumAliases is populated
                        // by the backend's Input.as-hash when `accepts =` is
                        // declared in the .nhd. Surfaces as orange; does not
                        // block calculation.
                        metaData = this.__propData[i].getMetaData();
                        if (   metaData
                            && metaData.enumAliases
                            && metaData.enumAliases.hasOwnProperty(value)
                        ) {
                            mapped = true;
                        }
                    }
                }
            }
            this.__mapped = mapped;

            if (!complete) {
                this.setIcon('agrammon/red-dot.png');
            }
            else if (mapped) {
                this.setIcon('agrammon/orange-dot.png');
            }
            else {
                this.setIcon('agrammon/green-dot.png');
            }
            return complete;
        }, // isComplete

        /**
          * TODOC
          *
          * @return {var} TODOC
          * @lint ignoreDeprecated(alert)
          */
        // #420: return the authoritative, instance-qualified variable name for
        // `name` within this folder, matched on the instance-independent part
        // (the name with any [instance] marker stripped). The folder's propData
        // carries the current instance (this folder is the single source of
        // truth for it), so a caller can pass a name whose [instance] is stale
        // — e.g. a table cell that lags an instance rename — and still get the
        // name pointing at this folder's *current* instance. Returns null if no
        // variable matches. Singletons (no [instance]) round-trip unchanged.
        resolveVariable: function(name) {
            var bare = ('' + name).replace(/\[[^\]]*\]/, '');
            for (var i = 0; i < this.__propData.length; i++) {
                var full = this.__propData[i].getName();
                if (full.replace(/\[[^\]]*\]/, '') === bare) {
                    // Re-qualify using this folder's current instance (single
                    // source of truth). The stored name supplies only the
                    // [instance] *position*; its value may be stale after a
                    // rename since we no longer rewrite it eagerly.
                    return this.__instanceName != null
                        ? full.replace(/\[[^\]]*\]/, '[' + this.__instanceName + ']')
                        : full;
                }
            }
            return null;
        }, // resolveVariable

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
                // #420: match on the instance-independent name. The stored
                // variable name's [instance] may be stale after a rename (we no
                // longer rewrite it), and callers may pass either the bare name
                // or a freshly re-qualified one — compare with the marker
                // stripped from both sides. Bare names are unique within a
                // folder, so this stays unambiguous.
                if (('' + varName).replace(/\[[^\]]*\]/, '') == ('' + key).replace(/\[[^\]]*\]/, '')) {

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
                            // Cross-version enum alias: declared via `accepts =`
                            // in the .nhd. Accept the value, keep it as-is in
                            // storage (so reopening in the source version still
                            // sees its own value); the cell renderer maps it
                            // to the canonical label and paints it orange.
                            if (   ! found
                                && metaData.enumAliases
                                && metaData.enumAliases.hasOwnProperty(value)
                            ) {
                                found = true;
                            }
                            if (found) {
                                this.__propData[i].setValue(value);
                            }
                            else {
                                // invalid enum value: surface to NavBar
                                // via the same "missing" path so the user
                                // can decide whether to delete it. Return
                                // the bad value so NavBar can display it.
                                this.debug('Invalid enum value: key=' + key
                                    + ', value=>' + value + '<,'
                                    + ' options=>' + options + '<');
                                return { invalidValue: value };
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

        // #431: build the inline percent rows for a flattened input from the
        // structured {options, fractions} carried by load_dataset. Identity is
        // metadata (flattenedOf / flattenedKey), not a parsed _flattenedNN_ name.
        buildFlattenedRows: function(markerName, options, fractions) {
            var marker = null, pos = -1;
            for (var i = 0; i < this.__propData.length; i++) {
                if (this.__propData[i].getName() === markerName) { marker = this.__propData[i]; pos = i; break; }
            }
            if (!marker) { return; }
            for (var j = 0; j < options.length; j++) {
                var key    = options[j];   // canonical underscore enum key
                var rowName = markerName + '#flat#' + key;   // non-semantic, unique
                var labels  = marker.getOptionLabelsByKey(key) || {};
                var v = marker.clone(rowName);
                v.setType('percent');
                v.setDefaultValue(null);
                v.setValue(fractions && fractions[j] != null ? '' + fractions[j] : null);
                v.setLabels(labels);
                v.setUnits({ en: '%', de: '%', fr: '%', it: '%' });
                v.setHelpIcon(null);
                v.setHelpFunction(null);
                v.setMetaData({ type: 'percent', flattenedOf: markerName, flattenedKey: key });
                v.setOrder(marker.getOrder() + j + 1);
                this.__propData.splice(pos + 1 + j, 0, v);
            }
        },

        setDataset: function(newData, handleIgnore, storeAll) {
            var i;
            this.__propData = new Array;
            var len = newData.length;
            // FIX ME
            var noCheck = true;
            var data;
            // #431: flattened inputs are persisted per-marker via
            // store_flattened_data after the loop, never as per-row store_data.
            // markerVarName -> { rows: [{key,value}], hasMarker: bool }
            var flattenedGroups = {};
            for (i=0; i<len; i++) {
                data = newData[i];
                var name = data.getName();
                var value = data.getValue();
                var comment = data.getComment();
                var meta = data.getMetaData();
                this.__propData.push(data);
                // prevent default value (*** Select ***) on instance creation
                if (meta && meta.flattenedOf && value === null) {
                    value = '';
                }
                if (storeAll) {
                    if (handleIgnore && name.match(/::ignore/)) { // FIX ME
                        this.setData(name, 'ignore', null, noCheck, null);
                        qx.event.message.Bus.dispatchByName('agrammon.PropTable.storeData',
                                                            { 'var': name, value: 'ignore' });
                    }
                    else if (value === 'branched') {
                        // #421/copy: only reflect the branched state in the
                        // grid. The matrix itself is copied server-side
                        // (copy_branch_data) when an instance is duplicated, so
                        // it survives cross-version option drift verbatim — the
                        // old per-pair reconstruction reshaped to the current
                        // option counts and silently dropped drifted matrices.
                        this.setData(name, value, comment, noCheck, meta.branches);
                    }
                    else if (value === 'flattened') {
                        // marker row: collect the group, persist the marker
                        // value only (no per-row store_data).
                        if (!flattenedGroups[name]) {
                            flattenedGroups[name] = { rows: [], hasMarker: false };
                        }
                        flattenedGroups[name].hasMarker = true;
                        this.setData(name, value, comment, noCheck, null);
                    }
                    else if (meta && meta.flattenedOf) {
                        // flattened option row: identity is metadata. Collect
                        // its percent for the marker's group; do NOT store_data.
                        if (!flattenedGroups[meta.flattenedOf]) {
                            flattenedGroups[meta.flattenedOf] = { rows: [], hasMarker: false };
                        }
                        flattenedGroups[meta.flattenedOf].rows.push({ key: meta.flattenedKey, value: value });
                        this.setData(name, value, comment, noCheck, null);
                    }
                    else {
                        qx.event.message.Bus.dispatchByName('agrammon.PropTable.storeData',
                                                            { 'var': name, value: value });
                        this.setData(name, value, comment, noCheck, meta.branches);
                    }
                }

                if (handleIgnore && name.match(/::ignore/)) { // FIX ME
                    this.setData(name, 'ignore', null, noCheck, null);
                    qx.event.message.Bus.dispatchByName('agrammon.PropTable.storeData',
                                                        { 'var': name, value: 'ignore' });
                }
            }
            if (storeAll) {
                for (var mk in flattenedGroups) {
                    if (flattenedGroups.hasOwnProperty(mk)) {
                        this.__storeFlattenedGroup(mk, flattenedGroups[mk]);
                    }
                }
            }

            this.isComplete();
            // This must be done outside!
            // this.rootFolder.isComplete();
            return this.__propData.length;
        }, // setDataSet

        // #431: persist one flattened input via store_flattened_data. The marker
        // var name carries the instance; rows carry option key + percent.
        // onDone (optional) runs after the RPC completes — used by incremental
        // edits to trigger the output recalc only once the write has landed.
        __storeFlattenedGroup: function(markerName, group, onDone) {
            var regex = /\[(.+)\]/;
            var m = regex.exec(markerName);
            if (!m) { return; }
            var instance = m[1];
            var varName  = markerName.replace(regex, '[]');
            var options = [], fractions = [];
            for (var i = 0; i < group.rows.length; i++) {
                options.push(group.rows[i].key);
                // #431: keep unset cells empty (null) rather than coercing them
                // to 0 — an empty percent means "not yet set", not zero. An
                // explicitly typed 0 is preserved.
                var rv = group.rows[i].value;
                fractions.push(rv === '' || rv === null || rv === undefined ? null : Number(rv));
            }
            if (options.length === 0) { return; }
            var datasetName = '' + agrammon.Info.getInstance().getDatasetName();
            agrammon.io.remote.Rpc.getInstance().callAsync(
                (onDone || function() {}), 'store_flattened_data',
                { datasetName: datasetName,
                  data: { instance: instance, var: varName, options: options, fractions: fractions } });
        },

        // #431: persist a single-cell edit of a flattened percent. Incremental
        // edits flow through PropTable.__dataChanged_func, which only knows
        // store_data — for a flattened-option row that would (wrongly) write a
        // `#flat#` data row and never touch the flattened table, leaving the run
        // to read stale/empty fractions (sums-to-0 → 500). Detect such an edit,
        // gather the marker's current percents from propData (identity is the
        // flattenedOf / flattenedKey metadata, never the row name) and re-store
        // the whole group via store_flattened_data. Returns true when handled so
        // the caller skips its plain store_data. Match instance-independently
        // (#420: a row's [instance] may be stale after a rename).
        storeFlattenedForEdit: function(editedVarName, onDone) {
            var stripInst = function(n) { return ('' + n).replace(/\[[^\]]*\]/, ''); };
            var bareEdited = stripInst(editedVarName);
            // Learn the edited row's marker from its metadata.
            var markerOf = null;
            for (var i = 0; i < this.__propData.length; i++) {
                if (stripInst(this.__propData[i].getName()) === bareEdited) {
                    var m = this.__propData[i].getMetaData() || {};
                    markerOf = m.flattenedOf || null;
                    break;
                }
            }
            if (markerOf == null) { return false; }
            // Gather all sibling percents for that marker (current values).
            var bareMarker = stripInst(markerOf);
            var group = { rows: [], hasMarker: true };
            for (var j = 0; j < this.__propData.length; j++) {
                var mj = this.__propData[j].getMetaData() || {};
                if (mj.flattenedOf && stripInst(mj.flattenedOf) === bareMarker) {
                    group.rows.push({ key: mj.flattenedKey,
                                      value: this.__propData[j].getValue() });
                }
            }
            this.__storeFlattenedGroup(markerOf, group, onDone);
            return true;
        },

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

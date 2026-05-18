/* ************************************************************************

    Row renderer for the dataset table that greys out rows whose dataset
    version doesn't match the active model version of THIS process.

    The row data layout is the one produced by Agrammon::DB::Datasets.list:
        [name, mod-date, records, read-only, version, tags, comment, model, is-demo]

************************************************************************ */

qx.Class.define('agrammon.ui.table.rowrenderer.DatasetVersion', {
    extend:    qx.core.Object,
    implement: qx.ui.table.IRowRenderer,

    construct: function(versionColumn) {
        this.base(arguments);
        this.__versionColumn = versionColumn;

        this.__fontStyle = qx.bom.Font.getDefaultStyles();
        this.__fontStyleString = qx.bom.element.Style.compile(this.__fontStyle).replace(/"/g, "'");

        var colorMgr = qx.theme.manager.Color.getInstance();
        this._colors = {
            bgcolFocused: colorMgr.resolve("table-row-background-focused"),
            bgcolEven:    colorMgr.resolve("table-row-background-even"),
            bgcolOdd:     colorMgr.resolve("table-row-background-odd"),
            colNormal:    colorMgr.resolve("table-row"),
            horLine:      colorMgr.resolve("table-row-line")
        };
    },

    properties: {
        highlightFocusRow: { check: "Boolean", init: true },
        activeVersion:     { check: "String",  init: "", nullable: true }
    },

    members: {
        __versionColumn:   null,
        __fontStyle:       null,
        __fontStyleString: null,
        _colors:           null,
        _insetY:           1,

        __isMismatch: function(rowData) {
            var v = this.getActiveVersion();
            if (!v || !rowData) return false;
            var rowVersion = rowData[this.__versionColumn];
            return rowVersion != null && rowVersion !== '' && rowVersion !== v;
        },

        // interface implementation
        updateDataRowElement: function(rowInfo, rowElem) {
            var style = rowElem.style;
            qx.bom.element.Style.setStyles(rowElem, this.__fontStyle);

            if (rowInfo.focusedRow && this.getHighlightFocusRow()) {
                style.backgroundColor = this._colors.bgcolFocused;
            }
            else {
                style.backgroundColor = (rowInfo.row % 2 == 0)
                    ? this._colors.bgcolEven
                    : this._colors.bgcolOdd;
            }

            style.color = this._colors.colNormal;
            style.borderBottom = "1px solid " + this._colors.horLine;
            style.opacity = this.__isMismatch(rowInfo.rowData) ? "0.45" : "1";
        },

        getRowHeightStyle: function(height) {
            if (qx.core.Environment.get("css.boxmodel") == "content") {
                height -= this._insetY;
            }
            return "height:" + height + "px;";
        },

        // interface implementation
        createRowStyle: function(rowInfo) {
            var rowStyle = [";", this.__fontStyleString, "background-color:"];
            if (rowInfo.focusedRow && this.getHighlightFocusRow()) {
                rowStyle.push(this._colors.bgcolFocused);
            }
            else {
                rowStyle.push((rowInfo.row % 2 == 0) ? this._colors.bgcolEven
                                                    : this._colors.bgcolOdd);
            }
            rowStyle.push(';color:', this._colors.colNormal);
            rowStyle.push(';border-bottom: 1px solid ', this._colors.horLine);
            if (this.__isMismatch(rowInfo.rowData)) {
                rowStyle.push(';opacity:0.45');
            }
            return rowStyle.join("");
        },

        getRowClass: function(rowInfo) { return ""; },
        getRowAttributes: function(rowInfo) { return ""; }
    },

    destruct: function() {
        this._colors = this.__fontStyle = this.__fontStyleString = null;
    }
});

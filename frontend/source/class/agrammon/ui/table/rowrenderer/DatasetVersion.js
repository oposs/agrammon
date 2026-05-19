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

        // Resolve the THEME's default font so cells render in the same
        // typeface as the rest of the app. qx.bom.Font.getDefaultStyles()
        // returns the BROWSER default (serif) which shows up as Times New
        // Roman.
        var font = qx.theme.manager.Font.getInstance().resolve("default");
        this.__fontStyle = font ? font.getStyles()
                                : qx.bom.Font.getDefaultStyles();
        this.__fontStyleString = qx.bom.element.Style.compile(this.__fontStyle).replace(/"/g, "'");

        var colorMgr = qx.theme.manager.Color.getInstance();
        // Mismatch rows use a muted color rather than opacity: opacity
        // stacking drops effective contrast below WCAG AA (DevTools
        // flags it), but a real gray that still meets 4.5:1 on the row
        // background passes the contrast check. #555 = ~7.5:1 on white.
        this._colors = {
            bgcolFocused: colorMgr.resolve("table-row-background-focused"),
            bgcolEven:    colorMgr.resolve("table-row-background-even"),
            bgcolOdd:     colorMgr.resolve("table-row-background-odd"),
            colNormal:    colorMgr.resolve("table-row"),
            colMismatch:  "#555",
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

            style.color = this.__isMismatch(rowInfo.rowData)
                ? this._colors.colMismatch
                : this._colors.colNormal;
            style.borderBottom = "1px solid " + this._colors.horLine;
            style.fontStyle = this.__isMismatch(rowInfo.rowData) ? "italic" : "normal";
            style.opacity = "1";
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
            var mismatch = this.__isMismatch(rowInfo.rowData);
            rowStyle.push(';color:', mismatch ? this._colors.colMismatch
                                              : this._colors.colNormal);
            rowStyle.push(';border-bottom: 1px solid ', this._colors.horLine);
            if (mismatch) {
                rowStyle.push(';font-style:italic');
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

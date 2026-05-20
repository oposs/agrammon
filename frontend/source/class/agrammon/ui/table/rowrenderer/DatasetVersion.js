/* ************************************************************************

    Row renderer for the dataset table.  Highlights the currently selected
    row with the theme's selected background + text colors.  The historical
    grey/italic styling for rows whose dataset_version didn't match the
    active model version was removed in 2026-05; the activeVersion property
    is kept as a no-op setter so external callsites (Application.js,
    DatasetTable.js) don't need to change.

    The row data layout is the one produced by Agrammon::DB::Datasets.list:
        [name, mod-date, records, read-only, version, tags, comment, model, is-demo]

************************************************************************ */

qx.Class.define('agrammon.ui.table.rowrenderer.DatasetVersion', {
    extend:    qx.core.Object,
    implement: qx.ui.table.IRowRenderer,

    construct: function(versionColumn) {
        this.base(arguments);

        // Resolve the THEME's default font so cells render in the same
        // typeface as the rest of the app. qx.bom.Font.getDefaultStyles()
        // returns the BROWSER default (serif) which shows up as Times New
        // Roman.
        var font = qx.theme.manager.Font.getInstance().resolve("default");
        this.__fontStyle = font ? font.getStyles()
                                : qx.bom.Font.getDefaultStyles();
        this.__fontStyleString = qx.bom.element.Style.compile(this.__fontStyle).replace(/"/g, "'");

        var colorMgr = qx.theme.manager.Color.getInstance();
        this._colors = {
            bgcolSelected: colorMgr.resolve("table-row-background-selected"),
            bgcolFocused:  colorMgr.resolve("table-row-background-focused"),
            bgcolEven:     colorMgr.resolve("table-row-background-even"),
            bgcolOdd:      colorMgr.resolve("table-row-background-odd"),
            colSelected:   colorMgr.resolve("table-row-selected"),
            colNormal:     colorMgr.resolve("table-row"),
            horLine:       colorMgr.resolve("table-row-line")
        };
    },

    properties: {
        highlightFocusRow: { check: "Boolean", init: true },
        // No-op setter retained for callers in Application.js / DatasetTable.js.
        // Drove the mismatch grey/italic styling before that was removed.
        activeVersion:     { check: "String",  init: "", nullable: true }
    },

    members: {
        __fontStyle:       null,
        __fontStyleString: null,
        _colors:           null,
        _insetY:           1,

        // interface implementation
        updateDataRowElement: function(rowInfo, rowElem) {
            var style = rowElem.style;
            qx.bom.element.Style.setStyles(rowElem, this.__fontStyle);

            if (rowInfo.selected) {
                style.backgroundColor = this._colors.bgcolSelected;
                style.color           = this._colors.colSelected;
            }
            else if (rowInfo.focusedRow && this.getHighlightFocusRow()) {
                style.backgroundColor = this._colors.bgcolFocused;
                style.color           = this._colors.colNormal;
            }
            else {
                style.backgroundColor = (rowInfo.row % 2 == 0)
                    ? this._colors.bgcolEven
                    : this._colors.bgcolOdd;
                style.color = this._colors.colNormal;
            }
            style.borderBottom = "1px solid " + this._colors.horLine;
            style.fontStyle    = "normal";
            style.opacity      = "1";
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
            var textColor;
            if (rowInfo.selected) {
                rowStyle.push(this._colors.bgcolSelected);
                textColor = this._colors.colSelected;
            }
            else if (rowInfo.focusedRow && this.getHighlightFocusRow()) {
                rowStyle.push(this._colors.bgcolFocused);
                textColor = this._colors.colNormal;
            }
            else {
                rowStyle.push((rowInfo.row % 2 == 0) ? this._colors.bgcolEven
                                                    : this._colors.bgcolOdd);
                textColor = this._colors.colNormal;
            }
            rowStyle.push(';color:', textColor);
            rowStyle.push(';border-bottom: 1px solid ', this._colors.horLine);
            return rowStyle.join("");
        },

        getRowClass:      function(rowInfo) { return ""; },
        getRowAttributes: function(rowInfo) { return ""; }
    },

    destruct: function() {
        this._colors = this.__fontStyle = this.__fontStyleString = null;
    }
});

/* ************************************************************************

   Authors:
     * Fritz Zaucker, Oetiker+Partner

************************************************************************ */

/**
 * Data cell renderer for custom background color and indentation of flattened variables.
 */
qx.Class.define('agrammon.ui.table.cellrenderer.input.Label', {
    extend : qx.ui.table.cellrenderer.Html,

    construct : function() {
        this.base(arguments);
        var colorMgr = qx.theme.manager.Color.getInstance();
        this.__colors = {};
        this.__colors.bgcolEven = colorMgr.resolve("table-row-background-even");
        this.__colors.bgcolOdd  = colorMgr.resolve("table-row-background-odd");
        this.__colors.bgcolFocusedSelected = colorMgr.resolve("table-row-background-focused-selected");
    },

    members : {
        __colors: null,

        _getCellStyle : function(cellInfo) {
            var color;
            if (cellInfo.rowData[0].match(/.+_flattened[\d]*_.+/)) { // match variable name
                cellInfo.value = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
                                 + cellInfo.value;
                color = (cellInfo.row % 2 == 1 ? this.__colors.bgcolOdd
                                               : this.__colors.bgcolEven);
                return this.base(arguments,  cellInfo) + "background-color:" +  color + ";" + "foreground-color: black;";
            }
            else {
                return this.base(arguments,  cellInfo);
            }
        }
    }
});

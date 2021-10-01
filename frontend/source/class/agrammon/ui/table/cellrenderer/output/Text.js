/* ************************************************************************

   Authors:
     * Fritz Zaucker, Oetiker+Partner AG

************************************************************************ */

/**
 * Data cell renderer for bold text.
 */
qx.Class.define('agrammon.ui.table.cellrenderer.output.Text', {
    extend : qx.ui.table.cellrenderer.Default,

    members : {
        _getCellStyle : function(cellInfo) {
            return this.base(arguments,  cellInfo) + "font-weight: bold;";
        }
    }
});

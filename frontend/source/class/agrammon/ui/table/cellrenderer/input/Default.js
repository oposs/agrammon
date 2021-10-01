/* ************************************************************************

   Copyright:
     2010 OETIKER+PARTNER AG, http://www.oetiker.ch

   Authors:
     * Fritz Zaucker, Oetiker+Partner AG after a mailing list suggestion by Derrell Lipmann

************************************************************************ */

/**
 * Data cell renderer for custom background colors and alignment.
 */
qx.Class.define('agrammon.ui.table.cellrenderer.input.Default', {
    extend : qx.ui.table.cellrenderer.Default,

    members : {
        _getCellStyle : function(cellInfo) {
            var color;
            if (cellInfo.value == null || cellInfo.value == undefined || cellInfo.value == '') {
              color = (cellInfo.row % 2 == 1 ? "#f1c6ca" : "#f1dfe1");
            }
            else {
              color = (cellInfo.row % 2 == 1 ? "#c5e1af" : "#dff1d1");
            }
            return this.base(arguments,  cellInfo) + "background-color:" +  color + "; text-align: right;";
        }
    }
});

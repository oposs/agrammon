/* ************************************************************************

   Authors:
     * Fritz Zaucker, Oetiker+Partner AG after a mailing list suggestion by Derrell Lipmann

************************************************************************ */

/**
 * Data cell renderer for custom background color and marking flattened/branched inputs.
 */
qx.Class.define('agrammon.ui.table.cellrenderer.input.Replace', {
    extend : qx.ui.table.cellrenderer.Replace,

    construct : function() {
        this.base(arguments);
        var colorMgr = qx.theme.manager.Color.getInstance();
        this.__colors = {};
        this.__colors.bgcolEven = colorMgr.resolve("table-row-background-even");
        this.__colors.bgcolOdd  = colorMgr.resolve("table-row-background-odd");
    },

    members : {
        __colors: null,

        _getCellStyle : function(cellInfo) {
            var color;
            var metaData = cellInfo.rowData[7];
            switch (cellInfo.value) {
            case null:
            case undefined:
            case '':
            case '*** Select ***':
                color = (cellInfo.row % 2 == 1 ? "#f1c6ca" : "#f1dfe1");
                break;
            case 'flattened':
                color = (cellInfo.row % 2 == 1 ? this.__colors.bgcolOdd
                                               : this.__colors.bgcolEven);
                cellInfo.value = '*** ' + qx.locale.Manager.tr("Flattened") + ' ***';
                break;
            case 'branched':
                cellInfo.value = qx.locale.Manager.tr("*** Configure Branching ***");
                var branches = metaData.branches;
                if (!branches) {
                    color = (cellInfo.row % 2 == 1 ? "#f1c6ca" : "#f1dfe1");
                    break;
                }
                else {
                    var total = 0;
                    for (var j=0; j<branches.length; j++) {
                        total += Number(branches[j]);
                    }
                    if (total == 0) {
                        color = (cellInfo.row % 2 == 1 ? "#f1c6ca" : "#f1dfe1");
                        break;
                    }
                }
            default:
                color = (cellInfo.row % 2 == 1 ? "#c5e1af" : "#dff1d1");
                break;
            }
            return this.base(arguments,  cellInfo) + "background-color:" +  color + ";";
        }
    }
});

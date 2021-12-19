/* ************************************************************************

   Copyright:
     2010 OETIKER+PARTNER AG, http://www.oetiker.ch

   Authors:
     * Fritz Zaucker, Oetiker+Partner AG after a mailing list suggestion by Derrell Lipmann

************************************************************************ */

/**
 * Data cell renderer for custom background color and default handling.
 */
qx.Class.define('agrammon.ui.table.cellrenderer.input.Number', {
    extend : qx.ui.table.cellrenderer.Number,

    members : {
        _getContentHtml : function(cellInfo) {
            var nf = new agrammon.util.FancyNumberFormat();

            let value = cellInfo.value;
            let defaultValue = (cellInfo.rowData[16] != null) ? cellInfo.rowData[16] : null;
            if (value || value == 0) {
                if ( String(value).match(/Flattened|Select|Standard/) || value === '' || isNaN(value) ) {
                    return value;
                }
                else {
                    return nf.format(value);
                }
            }
            else {
                if (defaultValue == null) return '';
                return defaultValue;
            }
        },

        _getCellStyle : function(cellInfo) {
            var color;
            var align;
            var style = 'normal';

            switch (cellInfo.value) {
            case null:
            case undefined:
            case '':
            case 'Standard':
                if (cellInfo.rowData[16] != null) {
                    color = (cellInfo.row % 2 == 1 ? "#c5e1af" : "#dff1d1");
                    // mark default values
                    style = 'italic';
                }
                else {
                    color = (cellInfo.row % 2 == 1 ? "#f1c6ca" : "#f1dfe1");
                }
                break;
            default:
                color = (cellInfo.row % 2 == 1 ? "#c5e1af" : "#dff1d1");
                break;
            }

            if (align) {
                return this.base(arguments,  cellInfo) + 'font-style:' + style
                     + '; background-color:' +  color + '; text-align:' + align + ';';

            }
            else {
                return this.base(arguments,  cellInfo) + 'font-style:' + style
                     + '; background-color:' +  color + ';';
            }
        }
    }
});

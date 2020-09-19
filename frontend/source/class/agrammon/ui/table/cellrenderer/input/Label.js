/* ************************************************************************

   qooxdoo - the new era of web development

   http://qooxdoo.org

   Copyright:
     2010 OETIKER+PARTNER AG, http://www.oetiker.ch

   License:
     LGPL: http://www.gnu.org/licenses/lgpl.html
     EPL: http://www.eclipse.org/org/documents/epl-v10.php
     See the LICENSE file in the project's top-level directory for details.

   Authors:
     * Fritz Zaucker, Oetiker+Partner AG after a mailing list suggestion by Derrell Lipmann

************************************************************************ */

/**
 * Data cell renderer for custom background color.
 */
qx.Class.define('agrammon.ui.table.cellrenderer.input.Label', {
//  extend : qx.ui.table.cellrenderer.Default,
  extend : qx.ui.table.cellrenderer.Html,

  construct : function()
  {
      this.base(arguments);
      var colorMgr = qx.theme.manager.Color.getInstance();
      this.__colors = {};
      this.__colors.bgcolEven = colorMgr.resolve("table-row-background-even");
      this.__colors.bgcolOdd  = colorMgr.resolve("table-row-background-odd");
      this.__colors.bgcolFocusedSelected =
          colorMgr.resolve("table-row-background-focused-selected");
  },

  members :
    {
        __colors: null,

    _getCellStyle : function(cellInfo)
    {
        var color;
        if (cellInfo.rowData[0].match(/.+_flattened[\d]*_.+/)) { // match variable name
//            cellInfo.value = ':..........' + cellInfo.value;
            cellInfo.value = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' 
                             + cellInfo.value;
//        }
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

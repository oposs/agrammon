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
qx.Class.define('agrammon.ui.table.cellrenderer.input.Boolean', {
  extend : qx.ui.table.cellrenderer.Boolean,

  members :
  {
    _getCellStyle : function(cellInfo)
    {
      var color;
      if (cellInfo.value == null) {
          color = (cellInfo.row % 2 == 1 ? "#f1c6ca" : "#f1dfe1");
      }
      else {
          color = (cellInfo.row % 2 == 1 ? "#c5e1af" : "#dff1d1");
      }
      return this.base(arguments,  cellInfo) + "background-color:" +  color + ";";
    }
  }
});

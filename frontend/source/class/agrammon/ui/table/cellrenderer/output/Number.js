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
qx.Class.define('agrammon.ui.table.cellrenderer.output.Number', {
  extend : qx.ui.table.cellrenderer.Number,

  members :
  {
    _getContentHtml : function(cellInfo)
    {
      var nf = this.getNumberFormat();
      if (nf)
      {
        if (cellInfo.value || cellInfo.value == 0) {
          // I don't think we need to escape the resulting string, as I
          // don't know of any decimal or separator which use a character
          // which needs escaping. It is much more plausible to have a
          // prefix, postfix containing such characters but those can be
          // (should be) added in their escaped form to the number format.
          return nf.format(cellInfo.value);
        } else {
          return "";
        }
      }
      else
      {
        return cellInfo.value === 0 ? "0" : (cellInfo.value || "");
      }
    },


    _getCellStyle : function(cellInfo)
    {
      var color;
      if (cellInfo.value == '') { // no value
          return this.base(arguments,  cellInfo);
      }
      else if (cellInfo.value === null || cellInfo.value === undefined) {
          color = (cellInfo.row % 2 == 1 ? "#f1c6ca" : "#f1dfe1");
      }
      else {
          color = (cellInfo.row % 2 == 1 ? "#c5e1af" : "#dff1d1");
      }
      return this.base(arguments,  cellInfo) + "background-color:" +  color + ";";
    }
  }
});

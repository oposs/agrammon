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
qx.Class.define('agrammon.ui.table.cellrenderer.input.Number', {
  extend : qx.ui.table.cellrenderer.Number,

  construct : function()
  {
      this.base(arguments);
      var colorMgr = qx.theme.manager.Color.getInstance();
      this.__colors = {};
      this.__colors.bgcolEven = colorMgr.resolve("table-row-background-even");
      this.__colors.bgcolOdd  = colorMgr.resolve("table-row-background-odd");
  },


  members :
  {

    __colors: null,

    _getContentHtml : function(cellInfo)
    {
//      var nf = this.getNumberFormat();
      var nf = new agrammon.util.FancyNumberFormat();

      if (nf)
      {
        if (cellInfo.value || cellInfo.value == 0) {
          // I don't think we need to escape the resulting string, as I
          // don't know of any decimal or separator which use a character
          // which needs escaping. It is much more plausible to have a
          // prefix, postfix containing such characters but those can be
          // (should be) added in their escaped form to the number format.
          if ( String(cellInfo.value).match(/Flattened|Select/) ) {
              return cellInfo.value;
          }
          else {
              return nf.format(cellInfo.value);
          }
        } else {
          return "";
        }
      }
      else
      {
        return cellInfo.value == 0 ? "0" : (cellInfo.value || "");
      }
    },


    _getCellStyle : function(cellInfo)
    {
        var color;
        var align;
        switch (cellInfo.value) {
        case null:
        case undefined:
        case '':
            color = (cellInfo.row % 2 == 1 ? "#f1c6ca" : "#f1dfe1");
            break;
        case 'flattened':
            color = (cellInfo.row % 2 == 1 ? this.__colors.bgcolOdd
                                           : this.__colors.bgcolEven);
            cellInfo.value = '*** ' + qx.locale.Manager.tr("Flattened") + ' ***';
            align = 'left';
            break;
        default:
            color = (cellInfo.row % 2 == 1 ? "#c5e1af" : "#dff1d1");
            break;
        }

        if (align) {
            return this.base(arguments,  cellInfo)
                 + 'background-color:' +  color + '; text-align:' + align + ';';

        }
        else {
            return this.base(arguments,  cellInfo)
                 + 'background-color:' +  color + ';';
        }
    }
  }
});

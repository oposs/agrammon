
/* ************************************************************************

    qooxdoo - the new era of web development

    http://qooxdoo.org

    Copyright:
      2007 by Tartan Solutions, Inc, http://www.tartansolutions.com

    License:
      LGPL 2.1: http://www.gnu.org/licenses/lgpl.html

    Authors:
      * Dan Hummon

************************************************************************ */

/**
 * @asset(Agrammon/*)
 * @asset(qx/icon/${qx.icontheme}/16/actions/list-add.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/utilities-text-editor.png)
 */

/**
 * The image cell renderer renders image into table cells.
 */
qx.Class.define('agrammon.ui.table.cellrenderer.Comment', {
  extend : qx.ui.table.cellrenderer.AbstractImage,


  /*
  *****************************************************************************
     CONSTRUCTOR
  *****************************************************************************
  */


  /**
   * @param height {Integer?16} The height of the image. The default is 16.
   * @param width {Integer?16} The width of the image. The default is 16.
   */
  construct : function(width, height)
  {
    this.base(arguments);

    if (width) {
      this.__imageWidth = width;
    }

    if (height) {
      this.__imageHeight = height;
    }

    this.__am = qx.util.AliasManager.getInstance();
  },




  /*
  *****************************************************************************
     MEMBERS
  *****************************************************************************
  */

  members :
  {
    __am : null,
    __imageHeight : 16,
    __imageWidth : 16,


    // overridden
    _identifyImage : function(cellInfo)
    {
      var imageHints =
      {
        imageWidth  : this.__imageWidth,
        imageHeight : this.__imageHeight
      };

      if (cellInfo.value == "" || cellInfo.value == null) {
        imageHints.url = this.__am.resolve('icon/16/actions/list-add.png');
      } else {
        imageHints.url = this.__am.resolve('icon/16/apps/utilities-text-editor.png');
//        imageHints.url = this.__am.resolve('Agrammon/comment.png');
      }

      imageHints.tooltip = cellInfo.tooltip;

      return imageHints;
    }
  },

  /*
  *****************************************************************************
     DESTRUCTOR
  *****************************************************************************
  */

  destruct : function() {
    this.__am = null;
  }
});

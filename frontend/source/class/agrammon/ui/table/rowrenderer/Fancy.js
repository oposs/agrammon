/* ************************************************************************

   qooxdoo - the new era of web development

   http://qooxdoo.org

   Copyright:
     2006 STZ-IDA, Germany, http://www.stz-ida.de
     2007 Visionet GmbH, http://www.visionet.de

   License:
     LGPL: http://www.gnu.org/licenses/lgpl.html
     EPL: http://www.eclipse.org/org/documents/epl-v10.php
     See the LICENSE file in the project's top-level directory for details.

   Authors:
     * Til Schneider (til132) STZ-IDA
     * Dietrich Streifert (level420) Visionet

************************************************************************ */

/**
 * The default data row renderer.
 */
qx.Class.define('agrammon.ui.table.rowrenderer.Fancy', {
  extend : qx.core.Object,
  implement : qx.ui.table.IRowRenderer,




  /*
  *****************************************************************************
     CONSTRUCTOR
  *****************************************************************************
  */

  construct : function()
  {
    this.base(arguments);

    this.__fontStyleString = "";
    this.__fontStyleString = {};

    this._colors = {};

    // link to font theme
    this._renderFont(qx.theme.manager.Font.getInstance().resolve("default"));

    // link to color theme
    var colorMgr = qx.theme.manager.Color.getInstance();
    this._colors.bgcolFocusedSelected = colorMgr.resolve("table-row-background-focused-selected");
    this._colors.bgcolFocused = colorMgr.resolve("table-row-background-focused");
    this._colors.bgcolSelected = colorMgr.resolve("table-row-background-selected");
    this._colors.bgcolEven = colorMgr.resolve("table-row-background-even");
    this._colors.bgcolOdd = colorMgr.resolve("table-row-background-odd");
    this._colors.colSelected = colorMgr.resolve("table-row-selected");
    this._colors.colNormal = colorMgr.resolve("table-row");
    this._colors.horLine = colorMgr.resolve("table-row-line");
  },




  /*
  *****************************************************************************
     PROPERTIES
  *****************************************************************************
  */

  properties :
  {
    /** Whether the focused row should be highlighted. */
    highlightFocusRow :
    {
      check : "Boolean",
      init : true
    }
  },



  /*
  *****************************************************************************
     MEMBERS
  *****************************************************************************
  */

  members :
  {
    _colors : null,
    __fontStyle : null,
    __fontStyleString : null,


    /**
     * the sum of the vertical insets. This is needed to compute the box model
     * independent size
     */
    _insetY : 1, // borderBottom

    /**
     * Render the new font and update the table pane content
     * to reflect the font change.
     *
     * @param font {qx.bom.Font} The font to use for the table row
     */
    _renderFont : function(font)
    {
      if (font)
      {
        this.__fontStyle = font.getStyles();
        this.__fontStyleString = qx.bom.element.Style.compile(this.__fontStyle);
        this.__fontStyleString = this.__fontStyleString.replace(/"/g, "'");
      }
      else
      {
        this.__fontStyleString = "";
        this.__fontStyle = qx.bom.Font.getDefaultStyles();
      }
    },


    // interface implementation
    updateDataRowElement : function(rowInfo, rowElem)
    {
      var fontStyle = this.__fontStyle;
      var style = rowElem.style;

      // set font styles
      qx.bom.element.Style.setStyles(rowElem, fontStyle);

      if (rowInfo.focusedRow && this.getHighlightFocusRow())
      {
        style.backgroundColor = this._colors.bgcolFocused;
      }
      else
      {
          style.backgroundColor =
              (rowInfo.row % 2 == 0) ? this._colors.bgcolEven
                                     : this._colors.bgcolOdd;
      }

      style.color = this._colors.colNormal;
	  if ( rowInfo.rowData != undefined && (
              rowInfo.rowData[5] === undefined
           || rowInfo.rowData[5] === '*** Select ***'
           || rowInfo.rowData[5] === null
           || rowInfo.rowData[5] === '' )
         ) {
              style.color = this._colors.undefined;
      }
      else {
          style.borderBottom = "1px solid " + this._colors.horLine;
      }
    },


    /**
     * Get the row's height CSS style taking the box model into account
     *
     * @param height {Integer} The row's (border-box) height in pixel
     */
    getRowHeightStyle : function(height)
    {
      if (qx.core.Environment.get("css.boxmodel") == "content") {
        height -= this._insetY;
      }

      return "height:" + height + "px;";
    },


    // interface implementation
    createRowStyle : function(rowInfo)
    {
      var rowStyle = [];
      rowStyle.push(";");
      rowStyle.push(this.__fontStyleString);
      rowStyle.push("background-color:");

      if (rowInfo.focusedRow && this.getHighlightFocusRow())
      {
        rowStyle.push(this._colors.bgcolFocused);
      }
      else
      {
          rowStyle.push((rowInfo.row % 2 == 0) ? this._colors.bgcolEven
                                               : this._colors.bgcolOdd);
      }

      rowStyle.push(';color:');
	  if (    rowInfo.rowData[5] === undefined
           || rowInfo.rowData[5] === '*** Select ***'
           || rowInfo.rowData[5] === null
           || rowInfo.rowData[5] === ''
         ) {
             rowStyle.push(this._colors.undefined);
              // rowStyle.push(';font-weight: bold');
      }
      else {
          rowStyle.push(this._colors.colNormal);
      }
      rowStyle.push(';border-bottom: 1px solid ', this._colors.horLine);

      return rowStyle.join("");
    },

    getRowClass : function(rowInfo) {
      return "";
    },

    /**
     * Add extra attributes to each row.
     *
     * @param rowInfo {Object}
     *   The following members are available in rowInfo:
     *   <dl>
     *     <dt>table {qx.ui.table.Table}</dt>
     *     <dd>The table object</dd>
     *
     *     <dt>styleHeight {Integer}</dt>
     *     <dd>The height of this (and every) row</dd>
     *
     *     <dt>row {Integer}</dt>
     *     <dd>The number of the row being added</dd>
     *
     *     <dt>selected {Boolean}</dt>
     *     <dd>Whether the row being added is currently selected</dd>
     *
     *     <dt>focusedRow {Boolean}</dt>
     *     <dd>Whether the row being added is currently focused</dd>
     *
     *     <dt>rowData {Array}</dt>
     *     <dd>The array row from the data model of the row being added</dd>
     *   </dl>
     *
     * @return {String}
     *   Any additional attributes and their values that should be added to the
     *   div tag for the row.
     */
    getRowAttributes : function(rowInfo)
    {
      return "";
    }
  },




  /*
  *****************************************************************************
     DESTRUCTOR
  *****************************************************************************
  */

  destruct : function() {
    this._colors = this.__fontStyle = this.__fontStyleString = null;
  }
});

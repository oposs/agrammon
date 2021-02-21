/* ************************************************************************

   Agrammon

   http://agrammon.ch/

   Authors:
     * Fritz Zaucker

************************************************************************ */

/**
 * @asset(agrammon/info_s.png)
 */

qx.Class.define('agrammon.module.input.Variable', {
    extend: qx.core.Object,

    /**
    * Creates a new Agrammon model variable
    */
    construct: function () {
        this.base(arguments);
    },

    properties: {
        name:         { init: null,
                        check: "String"
                      },
        labels:       { init: null },
        show  :       { init: true },
        value:        { init: null,
                        nullable: true
                      },
        defaultValue: { init: null,
                        nullable: true
                      },
        comment:      { init: null,
                        nullable: true,
                        check: "String"
                      },
        metaData:     { init: null, nullable: true },
        type:         { init: null},
        units:        { init: null, nullable: true},
        order:        { init: null, nullable: true},
        desc:         { init: null, nullable: true},
        helpIcon:     { init: 'agrammon/info_s.png', nullable: true},
        helpFunction: { init: null, nullable: true}
    },

    members: {

        getRow: function() {
            var rec = new Array;
            var locale = qx.locale.Manager.getInstance().getLocale();
            locale = locale.replace(/_.+/,'');
            rec.push(this.getName());
            rec.push(this.getLabels().en);
            rec.push(this.getLabels().de);
            rec.push(this.getLabels().fr);
            rec.push(this.getLabels()[locale]);
            rec.push(this.getValue());
            rec.push(this.getUnits()[locale]);
            rec.push(this.getMetaData());
            rec.push(this.getType());
            rec.push(this.getHelpIcon());
            rec.push(this.getHelpFunction());
            rec.push(this.getUnits().en);
            rec.push(this.getUnits().de);
            rec.push(this.getUnits().fr);
            rec.push(this.getComment());
            rec.push(this.getOrder());
            rec.push(this.getDefaultValue());
            return rec;
        },

        getBranchRow: function() {
            var rec = new Array;
            var locale = qx.locale.Manager.getInstance().getLocale();
            locale = locale.replace(/_.+/,'');
            rec.push(this.getName());
            rec.push(this.getLabels().en);
            rec.push(this.getLabels().de);
            rec.push(this.getLabels().fr);
            rec.push(this.getLabels()[locale]);
            rec.push(this.getValue());
            rec.push(this.getUnits()[locale]);
            rec.push(this.getMetaData());
            rec.push(this.getType());
            rec.push(null);
            rec.push(null);
            rec.push(this.getHelpIcon());
            rec.push(this.getHelpFunction());
            rec.push(this);
            rec.push(this.getDefaultValue());
            return rec;
        },

        setMetaParameter: function(key, val) {
          var meta = {};
          meta = this.getMetaData();
          if (!meta) {
              meta = {};
          }
          meta[key] = val;
          this.setMetaData(meta);
        },

        getMetaOptions: function() {
          var options = [];
          var optArray = this.getMetaData()['options'];
          var i, len=optArray.length;
          for (i=0; i<len; i++) {
              options.push(optArray[i][0]);
          }
          return options;
        },

        getMetaOptionsLang: function() {
          var optionsLang = [];
          var optArray = this.getMetaData()['optionsLang'];
          var i, len=optArray.length;
          for (i=0; i<len; i++) {
              optionsLang.push(optArray[i]);
          }
          return optionsLang;
        },

        /**
          * TODOC
          *
          * @return {var} TODOC
          * @lint ignoreDeprecated(alert)
          */
        getOptionLabels: function(key) {
            var labels, label;
            var optArray = this.getMetaOptions();
            var found = false, i, len=optArray.length;
            for (i=0; i<len; i++) {
                label = optArray[i];
                if (label == key) {
                    found = true;
                    break;
                }
            }
            var lang;
            if (!found) {
                alert('Variable.getOptionLabels(): key='+key+' not found for variable '+this.getName());
                labels = {};
                for (lang in ['en', 'de', 'fr']) {
                    labels[lang] = 'labels not found';
                }
            }
            else {
                labels = this.getMetaOptionsLang()[i];
            }
            return labels;
        },

        cloneLabels: function() {
            var newLabels = {};
            for (var key in this.getLabels()) {
                newLabels[key] = this.getLabels()[key];
            }
            return newLabels;
        },

        cloneUnits: function() {
            var newUnits = {};
            for (var key in this.getUnits()) {
                newUnits[key] = this.getUnits()[key];
            }
            return newUnits;
        },

        // FIX ME: this should probably go at least one level deeper
        cloneMetaData: function() {
            var newMeta = {};
            for (var key in this.getMetaData()) {
                newMeta[key] = this.getMetaData()[key];
            }
            return newMeta;
        },

        clone: function(name) {
            var newVar = new agrammon.module.input.Variable().set({
                name:         name,
                labels:       this.cloneLabels(),
                show:         this.getShow(),
                value:        this.getValue(),
                defaultValue: this.getDefaultValue(),
                comment:      this.getComment(),
                metaData:     this.cloneMetaData(),
                type:         this.getType(),
                units:        this.cloneUnits(),
                helpIcon:     this.getHelpIcon(),
                helpFunction: this.getHelpFunction(),
                order:        this.getOrder()
            });
            return newVar;
        }

    }

});

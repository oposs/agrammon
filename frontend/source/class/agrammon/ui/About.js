/* ************************************************************************

   Copyright: OETIKER+PARTNER AG
   License:   Proprietary
   Author(s): Fritz Zaucker
   Utf8Check:  äöü

   $Id: About.js 2412 2014-11-05 08:46:14Z zaucker $

************************************************************************* */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/help-about.png)
 */

qx.Class.define('agrammon.ui.About', {
    extend : qx.ui.window.Window,
    type: 'singleton',

    construct : function() {
        this.base(arguments);

        this.set({
                   caption: this.tr("About AGRAMMON"),
                   layout:    new qx.ui.layout.VBox(0),
                   modal: true,
                   showClose: true, showMinimize: false, showMaximize: false,
                   icon: 'icon/16/actions/help-about.png',
		   width: 300
        });
        this.__version = new qx.ui.basic.Atom();

        var model = new qx.ui.basic.Atom();
        model.set({
                     rich: true,
                     label:   "<h2>" + this.tr("Model Agrammon") + "</h2>"
		            + '<p>'
			    + this.tr("The simulation model Agrammon allows ammonia emissions to be calculated, and shows how changes in structure and production methods at the farm level affect emissions.")
                 });

        var docu = new qx.ui.basic.Atom();
        docu.set({
                     rich: true,
                     label:   "<h2>" + this.tr("Documentation") + "</h2>"
		            + "<p>"
			    + this.tr("For detailed information about the model please consult the Agrammon website at") 
			    + ' <a target=\"_blank\" href="http://www.agrammon.ch">www.agrammon.ch</a>.'
			    + "</p>"
   
                 });

        var implemented = new qx.ui.basic.Atom();
        implemented.set({
                     rich: true,
                     label:   "<hr/>"
                            + "<p align=\"right\">" + this.tr('Implemented by') + " <a target=\"_blank\" href=\"http://www.oetiker.ch\">OETIKER+PARTNER AG</a></p>"
                 });

        this.add(this.__version);
        this.add(model);
        this.add(docu);
	this.add(implemented);

        var closeButton = new qx.ui.form.Button(this.tr("Close"));
        closeButton.addListener('execute', function() {
                                    this.close();
                                }, this);
        closeButton.set({ allowGrowX: false, alignX: 'right'});
        this.add(closeButton);

        this.addListener('appear', function() {
                             this.center();
                         }, this);

    }, // construct

    members : {
        __version: '',

        setVersion: function(version) {
            this.__version.setLabel('Version '+version+' (#VERSION#)');
        }

    } // members

});


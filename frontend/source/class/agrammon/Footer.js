/* ************************************************************************
   Copyright: 2008, OETIKER+PARTNER AG
   License: GPL
   Authors: Fritz Zaucker nach Tobias Oetiker
************************************************************************ */

/**
 * Show a footer which is clickable.
 */
qx.Class.define('agrammon.Footer', {
    extend : qx.ui.container.Composite,

    /**
         * @param text {String}  Text for the link to show
         * @param url {String}  URL to point to
         */
    construct : function(text, url) {
        this.base(arguments, new qx.ui.layout.Dock());
        this.add(new agrammon.ui.basic.Link(text, url, '#888', '10px sans-serif'),{edge: 'east'});
//        this.__add_lang('Deutsch','de');
//        this.__add_lang('English','en');
    },
    members: {
        __add_lang: function(lab,lang){
            var lmgr = qx.locale.Manager.getInstance();
            this.info(lmgr.getLanguage());
            var but = new qx.ui.basic.Label(lab);
            but.set({
                font: qx.bom.Font.fromString('10px sans-serif'),
                marginRight: 5,
                opacity: 0.7
            });
            but.addListener('click',function(e){
                qx.locale.Manager.getInstance().setLocale(lang);
            });
            but.addListener('mouseover', function(e) {
                but.setOpacity(1);
            });

            but.addListener('mouseout', function(e) {
                but.setOpacity(0.7);
            });
            this.add(but,{edge:'west'});
        }
    }
});

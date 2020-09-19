/* ************************************************************************
   Copyright: OETIKER+PARTNER AG
   License:   Proprietary
   Author(s): Fritz Zaucker
   $Id: ViewerIframe.js 2412 2014-11-05 08:46:14Z zaucker $
   Utf8Check:  äöü
************************************************************************ */

qx.Class.define('agrammon.ui.ViewerIframe', {
    extend: qx.ui.core.Widget,
    type: 'singleton',

    construct: function () {
        this.base(arguments);
    }, // construct

    members : {
        __iframe: null,
        __docId:  null,

        __load : function() {
            console.log("ViewerIframe.__load()");
            var source = this.__iframe.getSource();
            if (source === null || source == 'about:blank' 
                                || source.match(/undefined$/) 
                                || source.match(/null$/) ) {
                console.log("ViewerIframe.__load(): empty source");
                return;
            }
            console.log("ViewerIframe.__load(): source="+source);

            var body = this.__iframe.getBody();
            var bodyText=qx.dom.Node.getText(body);
            
            var msg = '<p>' + bodyText  + '</p>';
            Agrammon.ui.dialog.MsgBox.getInstance().error(this.tr("ViewerIframe.__load(): could not load document %1", this.__docId), msg);
            this.__iframe.destroy();
            this.__iframe = null;
        },

        loadDocument : function(url) {
//            this.__docId = docId;
            this.__docId = url;
//            var url = bwt.data.Rpc.getInstance().getUrl()
//                   + '?download=' + docId + ';nocache='+String(Math.round(Math.random()*10000000));
            console.log('loadDocument(): url='+url);
            this.__iframe = new qx.ui.embed.Iframe();
//            this.__iframe.addListener("load", this.__load, this);
            this.__iframe.setSource(url);
        }

    }
});

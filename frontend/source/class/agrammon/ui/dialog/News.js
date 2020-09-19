/* ************************************************************************

************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/window-close.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/utilities-text-editor.png)
 */

qx.Class.define('agrammon.ui.dialog.News', {
    extend: qx.ui.window.Window,

  construct: function (title, newsList, execFunc, lastLogin) {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox(10));

        // qx.locale.Manager.getInstance().addListener("changeLocale",
        //                                                 this._update, this);

        var maxHeight = qx.bom.Document.getHeight() - 20;
        this.set({modal: true, showClose: false, // centered: true,
                  padding:0, minHeight: 200, minWidth: 400, maxWidth: 800,
                  maxHeight: maxHeight,
                  allowGrowY: true, allowGrowX: true
                 });
        this.setCaption(title);

        var vbox = new qx.ui.container.Composite(new qx.ui.layout.VBox());
        vbox.set({allowGrowY: true,
                  allowGrowX: true});
        this.add(vbox, {flex: 1});


        this.setIcon("icon/16/apps/utilities-text-editor.png");

        var text, i, len=newsList.length;

        var old_type='', old_date='';

        text = '<p>'
             + this.tr("The following messages have been published since your last login on ")
             + lastLogin.split(/ /)[0] + '</p>';
        text += '<dl>';
        for (i=0; i<len; i++) {
          var type = newsList[i][0];
          var date = newsList[i][1].split(/ /)[0];
          var news = newsList[i][2];
          if (date != old_date) {
            if (old_date != '') {
              text += '</dl>';
            }
            old_date = date;
            text += '<dt style="font-weight: bold; padding-left: 0em;">' + date + '</dt>';
              text += '<dd><dl>';
              old_type = '';
          }
          if (type != old_type) {
            if (old_type != '') {
              text += '</ul>';
            }
            old_type = type;
            text += '<dt style="font-weight: bold; padding-left: 0em;">' + type + '</dt>';
            text += '<dd><ul style="list-style: disc; padding-left: 0em;">';
          }
          text += '<li>' + news + '</li>';
        }
        text += '</ul></dl></dl>';
//    alert(text);
        var newsText = new qx.ui.basic.Label(text).set({rich: true});
        var newsBox  = new qx.ui.container.Stack();
        newsBox.set({allowGrowX: true, allowGrowY: true});
        newsText.set({allowGrowX: true, allowGrowY: true});
//        newsBox.add(newsText, {flex: 1});
        newsBox.add(newsText);
        vbox.add(newsBox,     {flex: 1});

        var btnClose = new qx.ui.form.Button(this.tr("Close"),
                                              "icon/16/actions/window-close.png");

      btnClose.addListener("execute", function(e) {
                               execFunc();
//                                 this.close();

        }, this);

        this.addListener('keydown', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                btnClose.execute();
            }
        });

        var buttonRow = new qx.ui.container.Composite(new qx.ui.layout.HBox(10));
        // var btnAll =
        //   new qx.ui.form.Button("Show all", "icon/16/actions/dialog-ok.png");

        // btnAll.addListener("execute", function(e) {
        //                        alert('Show all not yet implemented');
        // }, this);
        // buttonRow.add(btnAll);
        buttonRow.add(btnClose);
        vbox.add(buttonRow);

        this.addListenerOnce("resize", this.center, this);
        this.open();
    }, // construct

    members :
    {
    }
});

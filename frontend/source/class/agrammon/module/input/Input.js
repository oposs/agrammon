/* ************************************************************************

************************************************************************ */

qx.Class.define('agrammon.module.input.Input', {
    extend: qx.ui.tabview.Page,

    construct: function (propEditor, navbar, results) {
        this.base(arguments);
        this.setLayout(new qx.ui.layout.VBox());
        this.set({label: this.tr("Input"),
                  backgroundColor: 'white',
                  padding: 0
                 });

        qx.event.message.Bus.subscribe('agrammon.inputEnabled',
                                        this.__Enabled, this);

        var user = new Object;
        user['name'] = '-';
        var dataset = new Object;
        dataset['name'] = '-';

        var splitpane = new qx.ui.splitpane.Pane("horizontal");
        splitpane.set({backgroundColor: 'white', padding:0});
        splitpane.add(navbar, 0);

	// The regional model doesn't have the result preview
	if (results) {
            var splitpane2 = new qx.ui.splitpane.Pane("vertical");
            splitpane2.set({backgroundColor: 'white', padding:0});
            splitpane2.add(propEditor, 2);
            splitpane2.add(results, 1);

            splitpane.add(splitpane2, 1);
	}
        else {
            splitpane.add(propEditor, 1);
	}

        this.add(splitpane, { flex : 1 });

        this.addListener("appear", function() {
            qx.event.message.Bus.dispatchByName('agrammon.mainMenu.enable', true);
        }, this);
        this.addListener("disappear", function() {
            qx.event.message.Bus.dispatchByName('agrammon.mainMenu.enable', false);
        }, this);

    }, // construct

    members :
    {

        __Enabled: function(msg) {
            this.setEnabled(msg.getData());
        }

    }
});

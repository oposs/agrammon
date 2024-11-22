/* ************************************************************************

************************************************************************ */

qx.Class.define('agrammon.ui.menu.ModelMenu', {
    extend: qx.ui.menu.Menu,

    construct: function (modelVersions) {
        this.base(arguments);
console.log('ModelMenu: modelVersions=', modelVersions);
        modelVersions.split(',').forEach(model => {
            this.debug('model=', model);
            let cmd = new qx.ui.command.Command();
            cmd.addListener('execute', () => {
                console.log('modelVersion=', model);
                // agrammon.module.model.Model.getInstance().setModel(model);
            });
            this.add(new qx.ui.menu.Button(this.tr('Version %1', model), null, cmd));
        });

    }, // construct

    members :
    {
        // __selectModel: function(model) {
        //     console.log('__selectModel():', model);
        // }
    }
});

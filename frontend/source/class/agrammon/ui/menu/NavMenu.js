/* ************************************************************************

************************************************************************ */

qx.Class.define('agrammon.ui.menu.NavMenu', {
    extend: qx.ui.menu.Menu,

        /**
          * TODOC
          *
          * @return {var} TODOC
	  * @lint ignoreDeprecated(alert)
          */
    construct: function (navBar) {
        this.base(arguments);

        var navTree  = navBar.getTree();
        this.__navTree = navTree;
        this.__navBar  = navBar;
        this.__info = agrammon.Info.getInstance();

        var addCmd  = new qx.ui.command.Command;
        addCmd.addListener("execute", function(e){
            this.__navBar.addInstance(this.__navTree);
        }, this);

        var delCmd  = new qx.ui.command.Command;
        delCmd.addListener("execute", function(e){
            // doesn't really matter which of the next two I call
            var treeFolder = this.__navTree.getSelection()[0];
            this.__navBar.delInstance(treeFolder);
        }, this);

        var renCmd  = new qx.ui.command.Command;
        renCmd.addListener("execute", function(e){
            var treeFolder = this.__navTree.getSelection()[0];
            this.__navBar.renInstance(treeFolder);
        }, this);

        var copyCmd  = new qx.ui.command.Command;
        copyCmd.addListener("execute", function(e){
            var treeFolder = this.__navTree.getSelection()[0];
            this.__navBar.copyInstance(treeFolder);
        }, this);

        var checkCmd  = new qx.ui.command.Command;
        checkCmd.addListener("execute", function(e){
            var treeFolder = this.__navTree.getSelection()[0];
            var complete = treeFolder.isComplete();
            this.debug('checkCmd: ' + treeFolder.getName() + '='
                       + treeFolder.getType()
                       + ', complete='+complete
                       + ', order='+treeFolder.getOrder()
                      );
        }, this);

        this.__addButton =
            new qx.ui.menu.Button(this.tr("Add instance"),
                                  null, addCmd);
        this.__copyButton =
            new qx.ui.menu.Button(this.tr("Duplicate instance"),
                                  null, copyCmd);
        this.__renButton =
            new qx.ui.menu.Button(this.tr("Rename instance"),
                                  null, renCmd);
        this.__delButton =
            new qx.ui.menu.Button(this.tr("Delete instance"),
                                  null, delCmd);
//        this.__checkButton =
//            new qx.ui.menu.Button(this.tr("Check instance"),
//                                  null, checkCmd);
        this.add(this.__addButton);
        this.add(this.__copyButton);
        this.add(this.__renButton);
        this.add(this.__delButton);
        this.add(new qx.ui.menu.Separator());
//        this.add(this.__checkButton);

        this.addListener("appear",  function(e) {
            var selectedFolder = this.__navTree.getSelection()[0];
//            this.debug('selectedFolder='+selectedFolder);
            if (selectedFolder == undefined
               ) {
                   this.disableAll();               // needed for edit menu
                   return;
            }
            // this condition is met when the current dataset ist deleted
            // or no dataset is selected at login
            if ( this.__info != undefined && this.__info.getDatasetName() == '-') {
                   this.disableAll();               // needed for edit menu
            }

            var CanInstance    = selectedFolder.canInstance();
            var IsInstance     = selectedFolder.isInstance();
            if (! CanInstance && ! IsInstance) { // no context menu
                this.disableAll();               // needed for edit menu
                return;
            }
            if (! IsInstance) {              // can only use add function
                this.disableInstance();
            }
            else {                           // can use all other functions
                this.enableInstance();
            }

        }, this);
        this.disableInstance();
    }, // construct

    members :
    {
        __addButton:   null,
        __checkButton: null,
        __testButton:  null,
        __copyButton:  null,
        __delButton:   null,
        __renButton:   null,
        __navBar:      null,
        __navTree:     null,
        __info:        null,

         enableInstance: function() {
             this.__addButton.setEnabled(false);
             this.__copyButton.setEnabled(true);
             this.__renButton.setEnabled(true);
             this.__delButton.setEnabled(true);
         },

         disableInstance: function() {
             this.__addButton.setEnabled(true);
             this.__copyButton.setEnabled(false);
             this.__renButton.setEnabled(false);
             this.__delButton.setEnabled(false);
         },

         disableAll: function() {
             this.__addButton.setEnabled(false);
             this.__copyButton.setEnabled(false);
             this.__renButton.setEnabled(false);
             this.__delButton.setEnabled(false);
         }

    }
});

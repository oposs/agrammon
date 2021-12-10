/* ************************************************************************

************************************************************************ */

qx.Class.define('agrammon.ui.menu.MainMenu', {
    extend: qx.ui.toolbar.ToolBar,

    construct: function (inputOutput, title, editMenu) {
        this.base(arguments);
        qx.core.Id.getInstance().register(this, "Menu");
        this.setQxObjectId("Menu");
        this.__title = title;

        qx.locale.Manager.getInstance().addListener("changeLocale",
                                                    this.__changeLanguage,
                                                    this);

        qx.event.message.Bus.subscribe('agrammon.mainMenu.enable',
                                       this.__enableEdit, this);

        var info = agrammon.Info.getInstance();

        var fileMenu = new agrammon.ui.menu.FileMenu();
        var fileButton =  new qx.ui.toolbar.MenuButton(this.tr("File"));
        this.addOwnedQxObject(fileButton, "FileButton");
        fileButton.setMenu(fileMenu);
        this.addOwnedQxObject(fileMenu, "File");

        var editButton = new qx.ui.toolbar.MenuButton(this.tr("Edit"));
        this.__editButton = editButton;
        editButton.setMenu(editMenu);

        var optionMenu = new agrammon.ui.menu.OptionMenu();
        var optionButton = new qx.ui.toolbar.MenuButton(this.tr("Options"));
        optionButton.setMenu(optionMenu);

        var adminMenu = new agrammon.ui.menu.AdminMenu();
        this.__adminMenu = adminMenu;
        var adminButton = new qx.ui.toolbar.MenuButton(this.tr("Admin"));
        this.__adminButton = adminButton;
        adminButton.setMenu(adminMenu);
        this.showAdmin(false);

        var helpMenu = new agrammon.ui.menu.HelpMenu();
        var helpButton = new qx.ui.toolbar.MenuButton(this.tr("Help"));
        helpButton.setMenu(helpMenu);

        this.__tooltip = new qx.ui.tooltip.ToolTip(
            "<h2>AGRAMMON</h2>"
          + "<p>&copy; #YEAR#</p>", null);

        this.__tooltip.set({
                      minWidth: 200,
                      minHeight: 100,
//                      alignY: 'top',
                        padding: 20,
                      rich: true,
                      showTimeout: 50,
                      hideTimeout: 10000
                    });

        title.setToolTip(this.__tooltip);
        this.add(fileButton);
        this.add(editButton);
        this.add(optionButton);
        this.add(adminButton);
        this.add(helpButton);
        this.addSpacer();
        this.add(title);
        this.addSpacer();
        this.add(info);

        return;

    }, // construct

    members :
    {
        __adminMenu:   null,
        __adminButton: null,
        __editButton:  null,
        __title:       null,  // the Label widget
        __titles:      null, // multi-lingual hash of title values
        __tooltip:     null,

        showAdmin: function(show) {
            var info = agrammon.Info.getInstance();
            if (show) {
                this.__adminButton.show();

                this.__adminMenu.enableAdmin(info.isAdmin() || info.isSupport());
            }
            else {
                this.__adminButton.exclude();
            }
        },

        setTitle: function(titles, version) {
            this.__titles = titles;
            var locale = qx.locale.Manager.getInstance().getLocale();
            locale = locale.replace(/_.+/,'');
            this.__title.setValue(this.__titles[locale]);
            this.__tooltip.setLabel(
              "<h2>AGRAMMON</h2>"
            + "<p>" + version + "; &copy; #YEAR#</p>");

        },

        __enableEdit: function(msg) {
            this.__editButton.setEnabled(msg.getData());
        },

        __changeLanguage: function() {
            // FIX ME: deal with sub locales
            var locale = qx.locale.Manager.getInstance().getLocale();
            locale = locale.replace(/_.+/,'');
            if (this.__titles[locale]) {
                this.__title.setValue(this.__titles[locale]);
            }
        } // __changeLanguage


    }

});

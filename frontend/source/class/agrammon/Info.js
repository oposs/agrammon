
/* ************************************************************************

************************************************************************ */

qx.Class.define( 'agrammon.Info',
{
    extend : qx.ui.container.Composite,
    type: 'singleton',

    construct: function () {
        this.base(arguments);
        qx.core.Id.getInstance().register(this, "Info");
        this.setQxObjectId("Info");
        this.setLayout(new qx.ui.layout.VBox());
        // qx.locale.Manager.getInstance().addListener("changeLocale",
        //                                                 this._update, this);

        qx.event.message.Bus.subscribe('agrammon.info.setDataset',
                                       this.__setDataset, this);
        qx.event.message.Bus.subscribe('agrammon.info.setReferenceDataset',
                                       this.__setReferenceDataset, this);
        qx.event.message.Bus.subscribe('agrammon.info.setUser',
                                       this.__setUser, this);

        this.__dataset = new Object;
        this.__refDataset = new Object;
        this.__user = new Object;
        this.__refDataset['name']  = '-';

        this.__datasetLabel =
            new agrammon.ui.form.LabelValue(this.tr("Dataset"+': '),'-');
        this.addOwnedQxObject(this.__datasetLabel, "Dataset");
        this.__userLabel =
            new agrammon.ui.form.LabelValue(this.tr("User"+': '),'-');
        this.addOwnedQxObject(this.__userLabel, "User");
        this.__refDatasetLabel =
            new agrammon.ui.form.LabelValue(this.tr("Reference"+': '),'-');
        this.addOwnedQxObject(this.__refDatasetLabel, "Reference");
        var labelBox      =
            new qx.ui.container.Composite(new qx.ui.layout.VBox());
        var datasetRow    =
            new qx.ui.container.Composite(new qx.ui.layout.HBox());
        var refDatasetRow =
            new qx.ui.container.Composite(new qx.ui.layout.HBox());
        labelBox.set({paddingRight:10});

        datasetRow.add(this.__datasetLabel);
        datasetRow.add(new qx.ui.core.Spacer(20));
        datasetRow.add(this.__userLabel);
        refDatasetRow.add(this.__refDatasetLabel);
        labelBox.add(refDatasetRow);
        labelBox.add(datasetRow);

        this.add(labelBox);
        return;
    }, // construct

    properties: {
        title:   { init: 'Agrammon'
//                   check: "String"
                 },
        version: { init: '?',
                   check: "String"
                 },
        variant: { init: '?',
                   check: "String"
                 },
        modelVariant: { init: '?',
                   check: "String"
                 },
        guiVariant: { init: '?',
                   check: "String"
                 },
        submissionAddresses: {
            nullable: true
        }
    },

    members :
    {
        __dataset: null,
        __refDataset: null,
        __user: null,
        __userLabel: null,
        __datasetLabel: null,
        __refDatasetLabel: null,

        // FIX ME: remove duplicate functions

        clearDatasetName: function() {
            this.__dataset['name'] = '-';
            this.__datasetLabel.setValue('-');
            qx.event.message.Bus.dispatchByName('agrammon.FileMenu.enableClone',
                                          false);
            return;
        },

        setDatasetName: function(value) {
            this.__dataset['name'] = value;
            this.__datasetLabel.setValue(value);
            qx.event.message.Bus.dispatchByName('agrammon.FileMenu.enableClone',
                                          true);
            return;
        },

        setReferenceDatasetName: function(value) {
            this.__refDataset['name'] = value;
            this.__refDatasetLabel.setValue(value);
            return;
        },

        getDatasetName: function() {
            return this.__dataset['name'];
        },

        getRefDatasetName: function() {
            return this.__refDataset['name'];
        },

        setUserName: function(value) {
            this.__user['name'] = value;
            if (value) {
                this.__userLabel.setValue(value);
            }
            else {
                this.__userLabel.setValue('-');
            }
            return;
        },

        getUserName: function() {
            return this.__user['name'];
        },

        setRole: function(value) {
            this.__user['role'] = value;
        },

        getRole: function() {
            return this.__user['role'];
        },

        isAdmin: function() {
            return (this.__user.role == 'admin');
        },

        isSupport: function() {
            return (this.__user.role == 'support');
        },

        __setUser: function(msg) {
            var data = msg.getData();
            this.setUserName(data.username);
            this.setRole(data.role);
        },

        __setDataset: function(msg) {
            this.setDatasetName(msg.getData());
        },

        __setReferenceDataset: function(msg) {
            this.setReferenceDatasetName(msg.getData());
        }


    }
});

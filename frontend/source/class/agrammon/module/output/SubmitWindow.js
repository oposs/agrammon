/* ************************************************************************

************************************************************************ */

/*
 * @asset(qx/icon/${qx.icontheme}/16/actions/document-print-preview.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/document-send.png)
 * @asset(qx/icon/${qx.icontheme}/16/actions/window-close.png)
 * @asset(qx/icon/${qx.icontheme}/16/apps/office-database.png)
 */

qx.Class.define('agrammon.module.output.SubmitWindow', {
    extend: qx.ui.window.Window,
//    type: 'singleton',

        /**
          * TODOC
          *
          * @return {var} TODOC
	  * @lint ignoreDeprecated(alert)
          */
    construct: function (outputData, reportSelected, titleSelected, logMsg) {
        this.base(arguments);

        this.__outputData = outputData;
        this.__reportSelected = reportSelected;
        this.__titleSelected  = titleSelected;
        this.__logMsg = logMsg;

        var variant = agrammon.Info.getInstance().getVariant();
        var version = agrammon.Info.getInstance().getVersion();
        this.__version = 'Agrammon, ' + variant + ', ' + version;
        var maxHeight = qx.bom.Document.getHeight() - 20;
//        this.debug('maxHeight='+maxHeight);
        this.set({
                   layout: new qx.ui.layout.VBox(10),
                     minWidth: 250,
                     maxHeight: maxHeight, //allowShrinkY: true,
                   modal: true,
                   showClose: true, showMinimize: false, showMaximize: false,
                   caption: this.tr("Submission"),
                   icon: 'icon/16/actions/document-send.png',
//                   contentPadding: [0, 0, 10, 0],
                   padding: 10
                 });
        this.getChildControl("pane").setBackgroundColor("white");

        var infoBox = new qx.ui.groupbox.GroupBox(this.tr("Agrammon Simulation"));
        var infoLayout = new qx.ui.layout.Grid(10,5);
        infoBox.setLayout(infoLayout);
        this.add(infoBox);

        var info = agrammon.Info.getInstance();

        var row = 0;
        var dateFormat = new qx.util.format.DateFormat('yyyy-MM-dd HH:mm:ss');
        this.__date = dateFormat.format(new Date());
        var dataset = info.getDatasetName() + ' --- '+ this.__date;
        infoBox.add(new qx.ui.basic.Label(this.tr("User:")),          {row: row, column: 0});
        infoBox.add(new qx.ui.basic.Label(info.getUserName()),        {row: row++, column: 1});
        infoBox.add(new qx.ui.basic.Label(this.tr("Dataset:")),       {row: row, column: 0});
        infoBox.add(new qx.ui.basic.Label(dataset),                   {row: row++, column: 1});
        infoBox.add(new qx.ui.basic.Label(this.tr("Model version:")), {row: row, column: 0});
        infoBox.add(new qx.ui.basic.Label(this.__version),            {row: row++, column: 1});

        this.__manager = new qx.ui.form.validation.Manager();

        // add a listener to the form manager for the validation complete
        this.__manager.addListener("complete", function() {
            if (! this.__manager.getValid()) {
                alert(this.__manager.getInvalidMessages().join("\n"));
            }
        }, this);

        var inputBox = new qx.ui.groupbox.GroupBox(this.tr("Farm information"));
        var inputLayout = new qx.ui.layout.Grid(10,10);
        inputBox.setLayout(inputLayout);
        this.add(inputBox);

        row=0;
        this.__farmNumberLabel =
            new qx.ui.basic.Label(this.tr("Farm number:")).set({alignY: 'middle'});
        this.__farmNumberInput = new qx.ui.form.TextField();
//        this.__farmNumberInput.setMaxWidth(80);

        this.__manager.add(this.__farmNumberInput, agrammon.util.Validators.farmNumberRequired);

        inputBox.add(this.__farmNumberLabel, { row: row,   column: 0});
        inputBox.add(this.__farmNumberInput, { row: row++, column: 1});

        this.__addressLabel =
            new qx.ui.basic.Label(this.tr("Sender:")).set({alignY: 'top'});
        this.__addressInput = new qx.ui.form.TextArea();
//        this.__addressInput.set(
//            {
//                maxWidth: 80, // about 80 char in default font
//                wrap: false
//            }
//        );
        this.__manager.add(this.__addressInput, agrammon.util.Validators.addressRequired);
        inputBox.add(this.__addressLabel, { row: row,   column: 0});
        inputBox.add(this.__addressInput, { row: row++, column: 1});

        this.__farmSituationLabel
            = new qx.ui.basic.Label(this.tr("Variant:")).set({alignY: 'middle'});
        this.__farmSituationSelect = new qx.ui.form.SelectBox();
        inputBox.add(this.__farmSituationLabel,  { row: row,   column: 0});
        inputBox.add(this.__farmSituationSelect, { row: row++, column: 1});
        var situations = [ this.tr("Situation before building application"),
                           this.tr("Situation after building application")];
        var item, i, len=situations.length;
        for (i=0; i<len; i++) {
            item = new qx.ui.form.ListItem(situations[i]);
            this.__farmSituationSelect.add(item);
        }

        this.__commentLabel =
            new qx.ui.basic.Label(this.tr("Comments:")).set({alignY: 'top'});
        this.__commentInput = new qx.ui.form.TextArea();
        this.__commentInput.set(
            {
                width: 80*4, // about 80 char in default font
                wrap: true
            }
        );
        inputBox.add(this.__commentLabel, { row: row,   column: 0});
        inputBox.add(this.__commentInput, { row: row++, column: 1});

        this.__recipientLabel
            = new qx.ui.basic.Label(this.tr("Submit to:")).set({alignY: 'middle'});
        this.__recipientSelect = new qx.ui.form.SelectBox();
        inputBox.add(this.__recipientLabel,  { row: row,   column: 0});
        inputBox.add(this.__recipientSelect, { row: row++, column: 1});
//                           {name: 'Oetiker+Partner AG',  email: 'fritz.zaucker@oetiker.ch'},
//                           {name: 'Bonjour Engineering', email: 'cyrill.bonjour@bjengineering.ch'},
        var recipients = [ 
                           {name: 'Kt. Luzern, lawa',   email: 'agrammon-baugesuche.lawa@lu.ch'}
                         ];
        len = recipients.length;
        for (i=0; i<len; i++) {
            item = new qx.ui.form.ListItem(recipients[i].name, null, recipients[i].email );
            this.__recipientSelect.add(item);
        }

        var btnCancel = new qx.ui.form.Button(this.tr("Cancel"),
                                              "icon/16/actions/window-close.png");
        btnCancel.addListener("execute", function(e) {
            this.close();
        }, this);

        var btnClose = new qx.ui.form.Button(this.tr("Close"),
                                              "icon/16/actions/window-close.png");
        this.__previewWindow = new qx.ui.window.Window();
        this.__previewWindow.setLayout();

        this.__previewWindow.set({
                   layout: new qx.ui.layout.VBox(10),
                   width: 850, height: 500, //allowShrinkY: true,
                   modal: true,
                   showClose: true, showMinimize: true, showMaximize: true,
                   caption: this.tr("Agrammon Report"),
                   icon: 'icon/16/actions/document-print-preview.png',
//                   contentPadding: [0, 0, 10, 0],
                   padding: 10
                 });

        btnClose.addListener("execute", function(e) {
            this.__previewWindow.close();
        }, this);

        var pButtonRow =
            new qx.ui.container.Composite(new qx.ui.layout.HBox(10,'right'));
        pButtonRow.add(btnClose);

        this.__iframe =  new qx.ui.embed.Iframe();
        this.__previewWindow.add(this.__iframe, {flex:1});
        this.__previewWindow.add(pButtonRow);

        var btnPreview = new qx.ui.form.Button(this.tr("Preview"),
                                              "icon/16/actions/document-print-preview.png");
        btnPreview.addListener("execute", function(e) {
            if (! this.__manager.validate()) {
                this.debug('__preview(): Form is invalid');
                return;
            }
            this.__preview();
        }, this);


        this.__btnSubmit = new qx.ui.form.Button(this.tr("Submit"),
                                                 "icon/16/actions/document-send.png");
        this.__btnSubmit.addListener("execute", function(e) {
            if (! this.__manager.validate()) {
                this.debug('__submit(): Form is invalid');
                return;
            }
            this.__submit();
        }, this);

        this.__buttonRow =
            new qx.ui.container.Composite(new qx.ui.layout.HBox(10,'right'));

        this.__buttonRow.add(btnCancel);
        this.__buttonRow.add(btnPreview);
        this.__buttonRow.add(this.__btnSubmit);

        this.add(this.__buttonRow);

        this.addListener("resize", this.center, this);

        // resize window if browser window size changes
        qx.core.Init.getApplication().getRoot().addListener("resize",
                                                            function () {
            var height = qx.bom.Document.getHeight() - 20;
//            this.debug('maxHeight='+height);
            this.setMaxHeight(height);
//            this.setHeight(height);
        }, this);

        this.addListener("appear", this.__appear, this);

    }, // construct

    members :
    {
        __btnSubmit:       null,
        __reportSelected:  null,
        __outputData:      null,
        __version:         null,
        __date:            null,
        __logMsg:          null,
        __manager:         null,
        __addressInput:    null,
        __addressLabel:    null,
        __commentInput:    null,
        __commentLabel:    null,
        __farmNumberInput: null,
        __farmNumberLabel: null,
        __titleSelected:   null,
        __recipientSelect: null,
        __recipientLabel:  null,
        __previewWindow:   null,
        __iframe:          null,
        __buttonRow:       null,
        __farmSituationSelect: null,
        __farmSituationLabel:  null,

        __appear: function() {
            this.__btnSubmit.setEnabled(false);
        },

        __preview: function() {
            var info = agrammon.Info.getInstance();
            var baseUrl = agrammon.io.remote.Rpc.getInstance().getBaseUrl();
            var sender = this.__addressInput.getValue();
            if (sender != undefined) {
                sender = sender.replace(/\n/g, 'XXX');
            }
            var comment =  this.__commentInput.getValue();
            if (comment != undefined) {
                comment = comment.replace(/\n/g, 'XXX');
            }
            var locale       = qx.locale.Manager.getInstance().getLocale();
            var lang         = 'lang='    + locale.replace(/_.+/,'');
            var reportUrl    = 'reports=' + this.__reportSelected;
            var titleUrl     = 'titles='  + this.__titleSelected;
            var pidUrl       = 'pid='     + this.__outputData.getPid();
            var sessionUrl   = 'session=' + this.__outputData.getSession();
            var userUrl      = 'user='    + info.getUserName();
            var datasetUrl   = 'dataset=' + info.getDatasetName();
            var modelVariant = 'modelVariant='+agrammon.Info.getInstance().getModelVariant();
            var guiVariant   = 'guiVariant='+agrammon.Info.getInstance().getGuiVariant();
            var url = 'export/latex'
                               + '?' + 'mode=kantonLU'
                               + '&' + 'format=pdf'
                               + '&' + reportUrl
                               + '&' + titleUrl
                               + '&' + pidUrl
                               + '&' + sessionUrl
                               + '&' + userUrl
                               + '&' + datasetUrl
                               + '&' + lang
                               + '&' + guiVariant
                               + '&' + modelVariant
                               + '&' + 'version='   + this.__version
                               + '&' + 'farm='      + this.__farmNumberInput.getValue()
                               + '&' + 'sender='    + sender
                               + '&' + 'comment='   + comment
                               + '&' + 'recipient=' + this.__recipientSelect.getSelection()[0].getLabel()
                               + '&' + 'email='     + this.__recipientSelect.getSelection()[0].getModel()
                               + '&' + 'situation=' + this.__farmSituationSelect.getSelection()[0].getLabel()
                               + '&' + 'log='       + this.__logMsg;
            if (baseUrl != null) {
                url = baseUrl + url;
            }
            this.debug('baseUrl='+baseUrl);
            this.debug('url='+url);
//            document.location=url;
	       window.open(url);

            this.__btnSubmit.setEnabled(true);
        },

        __submit: function() {
            var rpc = agrammon.io.remote.Rpc.getInstance();
            var info = agrammon.Info.getInstance();
            var dataset    = info.getDatasetName();
            var username   = info.getUserName();
            var newDataset = this.__farmNumberInput.getValue() + ', '
                           + this.__farmSituationSelect.getSelection()[0].getLabel() + ', '
                           + username + ', ' + dataset
                           + this.__date;
            rpc.callAsync( qx.lang.Function.bind(this.__submitHandler, this),
                           'submit_dataset',
			               { username:   username,
                             oldDataset: dataset,
                             newDataset: newDataset,
                             recipient:  this.__recipientSelect.getSelection()[0].getModel(),
                             session:    this.__outputData.getSession(),
                             pid:        this.__outputData.getPid()
                           });
        },

        __submitHandler: function(data,exc,id) {
            this.debug('__submitHandler(): data='+data);
            if (exc == null) {
                agrammon.ui.dialog.MsgBox.getInstance().info(this.tr("Submission"),
                                                       this.tr("Report submitted sucessfully."));
	        }
            else {
                agrammon.ui.dialog.MsgBox.getInstance().error(this.tr("Submission"),
                                                       this.tr("Report submission failed."));
            }
            this.close();
        }

    }
});

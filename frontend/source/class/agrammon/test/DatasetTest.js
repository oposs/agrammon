/*****************************************
  Agrammon
   Copyright: OETIKER+PARTNER AG, 2021-
   Authors:   Fritz Zaucker
 *****************************************/

/**
 * Test class for {agrammon.module.dataset.Dataset*}
 *
 **/
qx.Class.define("agrammon.test.DatasetTest", {
    extend : agrammon.test.AbstractRestTest,

    members : {

        test000_Login : function() { this.loginTestUser(); this.wait(); },

        test010_getDatasets : function() {
                this.rest.post('get_datasets').then(
                    (datasets) => {
                        this.resume( () => {
                            console.log('### getDatasets(): datasets=', JSON.stringify(datasets, null, 4));
                            this.assertEquals('TestRegional', datasets[0][0], 'Got correct dataset name');
                            this.assertEquals('6.0', datasets[0][4], 'Got correct dataset version');
                            this.assertEquals('Agrammon6', datasets[0][7], 'Got correct GUI version');
                        }, this);
                    },
                    (reason) => {
                        this.resume( () => {
                            console.log('### getDatasets() failed:', reason);
                            throw reason;
                        }, this);
                    }
                );
            this.wait();
        },

        test020_createDataset : function() {
            this.rest.post('create_dataset', { name : 'TestXYZ' }).then(
                    (dataset) => {
                        this.resume( () => {
                            console.log('### createDataset(): dataset=', JSON.stringify(dataset, null, 4));
                            this.assertEquals('TestXYZ', dataset.name, 'Got correct dataset name');
                        }, this);
                    },
                    (reason) => {
                        this.resume( () => {
                            console.log('### createDataset() failed:', reason);
                            throw reason;
                        }, this);
                    }
                );
            this.wait();
        },

        test030_deleteDatasets : function() {
            this.rest.post('delete_datasets', {datasets : ['TestXYZ']}).then(
                    (response) => {
                        this.resume( () => {
                            console.log('### deleteDatasets(): response=', JSON.stringify(response, null, 4));
                            this.assertEquals(1, response.deleted, 'Got correct number of deleted datasets');
                        }, this);
                    },
                    (reason) => {
                        this.resume( () => {
                            console.log('### deleteDatasets() failed:', reason);
                            throw reason;
                        }, this);
                    }
                );
            this.wait();
        }

    }

});

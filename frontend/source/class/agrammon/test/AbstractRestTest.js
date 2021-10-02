/*****************************************
  Agrammon
   Copyright: OETIKER+PARTNER AG, 2018-
   Authors:   Fritz Zaucker
 *****************************************/

/**
 * The base class for test classes ofthe REST interface classes.
 *
 * Provides method loginTestUser() that simplifies the initial login
 * to the backend.
 *
 * This class tests has test methods to test itself.
 *
 **/
 qx.Class.define("agrammon.test.AbstractRestTest", {
    type   : "abstract",
    extend : qx.dev.unit.TestCase,

    properties : {
        'info' : {
            init : {}
        }
    },

    members : {
        rest : null,
        __testUsername : "testUser",
        __testPassword : "frontendTests",

        rest : function() {
            return new agrammon.io.remote.Rest();
        },

        /**
         * Make an auth() REST call with the pre-defined test username and password.
         *
         * Uses {qx.dev.unit.TestCase#wait} and {qx.dev.unit.TestCase#resume} for async operation.
         *
         * Sets the property user upon sucessful authentication.
         *
         * @return
         */
        loginTestUser : function() {
            // console.log('### loginTestUser: username=', this.__testUsername, ', password=', this.__testPassword);
            this.rest =  new agrammon.io.remote.Rest();
            return this.rest.post('auth', {
                username: this.__testUsername,
                password: this.__testPassword
            }).then(
                (userData) => {
                    this.resume( () => {
                        // console.log('### LOGIN SUCCESS: userData=', JSON.stringify(userData, null, 4));
                        let info = agrammon.Info.getInstance();
                        info.setUserName(userData.username);
                        this.assertEquals(this.__testUsername, info.getUserName(), 'Got correct username');
                        this.setInfo(info);
                        return info;
                    });
                },
                (reason) => {
                    this.resume( () => {
                        console.log('### LOGIN FAILURE, reason=', JSON.stringify(reason, null, 4));
                        throw reason;
                    });
                }
            );
            this.wait();
        },

        /**
         * Test the method provided by this base test class.
         */
        test000_Login : function() {
             this.loginTestUser();
        },

        // test001_User : function() {
        //     this.assertEquals(this.__testUsername, this.getInfo().getUserName(), 'User has correct username');
        // }

    }

});

/*****************************************
  Agrammon
   Copyright: OETIKER+PARTNER AG, 2021-
   Authors:   Fritz Zaucker
 *****************************************/

 qx.Class.define("agrammon.test.AuthTest", {
    extend : qx.dev.unit.TestCase,

    members : {

        rest : function() {
            return new agrammon.io.remote.Rest();
        },

        login : function(username, password, callback1, callback2) {
            console.log('# login(): username=', username);
            let rest = this.rest();
            let method = "auth";

            return rest.post(
                method, {
                    username : username,
                    password : password,
                    remember : false,
                    sudoUsername : null
                }
            ).then(
                (response) => {
                    this.resume(() => { callback1(response); }, this);
                },
                (reason) => {
                    this.resume(() => { callback2(reason); }, this);
                }
            );
        },

        test010_LoginFail : function() {
            let username = "invalidUser";
            let password = "invalidPassword";

            this.login(
                username, password,
                (response) => {
                    console.log('# Login succeeded unexpectedly');
                    this.fail('Login succeeded unexpectedly');
                },
                (reason) => {
                    this.assertMatch(reason.toString(), /Invalid username or password/, 'Unauthorized');
                }
            );
            this.wait();
        },

        test020_LoginSuccessUser : function() {
            let username = "testUser";
            let password = "frontendTests";

            this.login(
                username, password,
                (user) => {
                    // console.log('# user=', JSON.stringify(user, null, 4));
                    this.assertNotUndefined(user, 'user is defined');

                    // do we have all keys
                    this.assertKeyInMap('username', user, 'user has username');
                    this.assertKeyInMap('role', user, 'user has role');
                    this.assertKeyInMap('sudoUser', user, 'user has sudoUser');
                    this.assertKeyInMap('lastLogin', user, 'user has lastLogin');
                    this.assertKeyInMap('news', user, 'user has news');

                    let loginUser = user.username;
                    this.assertNotUndefined(loginUser, 'loginUser is defined');
                    // console.log('# *** loginUser=', loginUser);
                    this.assertEquals(username, loginUser, 'Got correct login username');

                    this.assertEquals('user', user.role, 'User has role user');
                },
                (reason) => {
                    console.log('# Login failed unexpectedly: reason=', reason.toString());
                    this.fail('Login failed unexpectedly');
                }
            );
            this.wait();
        },

        test030_LoginSuccessAdmin : function() {
            let username = "testAdmin";
            let password = "frontendTests";

            this.login(
                username, password,
                (user) => {
                    console.log('# user=', JSON.stringify(user, null, 4));
                    this.assertNotUndefined(user, 'user is defined');
                    let loginUser = user.username;
                    this.assertNotUndefined(loginUser, 'loginUser is defined');
                    console.log('# *** loginUser=', loginUser);
                    this.assertEquals(username, loginUser, 'Got correct login username');
                    this.assertEquals('admin', user.role, 'User has role admin');
                },
                (reason) => {
                    console.log('# Login failed unexpectedly: reason=', reason.toString());
                    this.fail('Login failed unexpectedly');
                }
            );
            this.wait();
        }

    }

});

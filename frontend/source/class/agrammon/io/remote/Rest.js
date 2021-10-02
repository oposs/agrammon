/*****************************************
  Agrammon
   Copyright: OETIKER+PARTNER AG, 2018-
   Authors:   Fritz Zaucker
 *****************************************/

/**
 * Class for REST calls using {@link qx.io.request.Xhr} and {@link qx.Promise}.
 *
 */
qx.Class.define('agrammon.io.remote.Rest', {
    extend  : qx.core.Object,
    include : qx.locale.MTranslation,

    /*
     * @param busy {agrammon.ui.BusyBlock ? null} The busy blocker widget.
     * @param delay {Integer ? 100} Delay in msec before opening the blocker.
     *
     */
    construct : function(busy, delay=50) {
        this.base(arguments);
        this.__busy  = busy;
        this.__delay = delay;
    },

    members : {
        __baseUrl : '/',
        __busy    : null,
        __delay   : null,
        __timer   : null,
        __running : false,

        // Return a promise for the REST call and open busy blocker if defined
        __call : function(methodName, requestData, requestType) {
            // console.log('# REST __call:', methodName, requestType, requestData);
            this.__running = true;
            if (this.__busy) {
                let busy = this.__busy;
                busy.setStatus(methodName);
                let timer = this.__timer = qx.event.Timer.once(
                    () => {
                        if (this.__running) { // only if request is still running
                            busy.open();
                        }
                    },
                    this,
                    this.__delay
                );
            }

            return new qx.Promise(function(resolve, reject) {
                let request = {method : methodName, data : requestData, type : requestType};
                this._restCall(request, resolve, reject);
            }, this);
        },

        /**
         * Make a backend POST call.
         *
         * @param methodName {String} The backend method to call.
         * @param data {Map} The data to be posted.
         * @return {qx.Promise} a promise for the data returned from the backend.
         */
        post : function(methodName, data) {
            return this.__call(methodName, data, 'POST');
        },

        /**
         * Make a backend GET call.
         *
         * @param methodName {String} The backend method to call.
         * @return {qx.Promise} a promise for the data returned from the backend.
         */
        get : function(methodName) {
            return this.__call(methodName, null, 'GET');
        },

        /**
         * Authenticate to the backend.
         *
         * @param username {String} The username to authenticate.
         * @param password {String} The password to authenticate with.
         * @return {qx.Promise} a promise for the data returned from the backend.
         */
        auth : function(username, password) {
            return this.post(
                'auth', {username : username, password: password}
            ).then(
                (user) => {
                    return user;
                },
                (error) => {
                    console.log('### auth() failure - error=', JSON.stringify(error, null, 4));
                    throw error;
                }
            );
        },

        /**
         * Do the backend request.
         *
         * Define handlers calling resolve() or reject() depending on
         * the return status.
         *
         **/
        _restCall : function(request, resolve, reject) {
            let methodName = request.method;
            let data       = request.data;
            let type       = request.type;

            let url = this.__baseUrl + methodName;
            let req = new qx.io.request.Xhr(url, type);
            req.setRequestHeader('Content-Type', 'application/json');
            if (data != null) {
                req.setRequestData(qx.util.Serializer.toJson(data));
            }

            // all is fine
            req.addListener("success", (e) => {
                if (this.__busy) {
                    this.__timer.stop();
                    this.__busy.close();
                }
                this.__running = false;
                let req = e.getTarget();
                let response = req.getResponse();
                // console.log('# response=', JSON.stringify(response, null, 4));
                resolve(response);
            }, this);

            // something is wrong, log and cleanup
            // handle specific failures below
            req.addListener("fail", () => {
                // console.log('fail');
                if (this.__busy) {
                    this.__timer.stop();
                    this.__busy.close();
                }
                this.__running = false;
            }, this);

            // throw specific errors
            req.addListener("timeout", (e) => {
                console.error('# Backend timeout', methodName, e);
                reject(new Error('Timeout while waiting for backend response.'));
            }, this);

            req.addListener("error", (e) => {
                console.error('# Backend error', methodName, e);
                reject(new Error('Error while waiting for backend response.'));
            }, this);

            req.addListener("statusError", (e) => {
                let err    = e.getTarget();
                let status = err.getStatus();
                let msg    = this.__getStatusError(methodName, err, request);
                console.log('# err=', err, ', status=', status);
                switch(status) {
                    case 401:
                        if (methodName != 'auth') {
                            this.__reAuthenticate(methodName, data, resolve, reject, msg);
                        }
                        else {
                            reject(new Error(msg));
                        }
                        break;
                    case 403:
                        this.__showFailure(msg);
                        reject(new Error(msg));
                        break;
                    default:
                        this.__showFailure(msg);
                        // console.log('REST ERROR:', msg);
                        reject(new Error(msg));
                        break;
                }
            }, this);

            req.send();
        },

        // Return a formatted error message string
        __getStatusError : function(methodName, err, request) {
            let response = err.getResponse();
            let status   = err.getStatus();
            let msg = (response && response.error) ? response.error : err.getStatusText();
            // console.log('__getStatusError(): response=', response, ', status=', status, ', msg=', msg, ', request=', request);

            let error = response.error;
            if (error && error.validation) {
                console.error('ERROR: validation error=', error);
                let validations = error.results;
                let msg = '<h2>' + this.tr('Validation error') + '</h2>';
                if (validations.module.length > 0 || validations.input.length > 0 ) {
                    console.warn('WARNING: validations=', validations);
                    msg += '<p>' + this.tr('The following validation errors must be resolved before approval:') + '</p>';
                    msg += '<dl>';
                    let inputErrors  = validations.input;
                    let moduleErrors = validations.module;
                    if (inputErrors.length > 0) {
                        for (let error of inputErrors) {
                            msg += '<dt><b><i>'
                                 + qx.xml.String.escape(this["tr"](error.input))
                                 + '</i></b>';
                            if ('instance' in error) {
                                msg += ' (' + this.tr('instance') + ' '
                                     + qx.xml.String.escape(String(error.instance)) + ') ';
                            }
                            msg += '</dt>';
                            if (error.message) {
                                msg += '<dd>' + qx.xml.String.escape(this["tr"](error.message)) + '</dd>';
                            }
                            if (error.mandatory) {
                                msg += '<dd>' + this.tr('is mandatory') + '</dd>';
                            }
                        }
                        msg += '<br/>';
                    }
                    if (moduleErrors.length > 0) {
                        for (let error of moduleErrors) {
                            msg += '<dt><b><i>';
                            msg += error.warning ? this.tr('Warning')
                                                 : this.tr('Error');
                            msg += '</i></b></dt>';
                            msg += '<dd>'
                                 + qx.xml.String.escape(this["tr"](error.message))
                                 + '</dd>';
                        }
                    }
                    msg += '</dl>';
                }
                else {
                    msg += '<p>' + this.tr('Some inputs must have changed while you tried to finish the module.') + '</p>';
                    msg += '<p>' + this.tr('Please reload the module and try again.') + '</p>';
                }
                return msg;
            }

            if (methodName == 'storeInput') {
                let msg = '<h2>' + this.tr('storeInput error') + '</h2>';
                if (typeof error == 'string') {
                    msg += '<p>' + error + '</p>';
                }
                msg += '<ul>';
                let data = request.data;
                for (let key of Object.keys(data).sort()) {
                    msg += '<li><b><i>' + this["tr"](key) + '</i></b>: ' + data[key]+ '</li>';
                }
                msg += '</ul>';
                return msg;
            }
            return methodName + ' "' + this.tr('failed') + '": ' + status + " -- " + msg;
        },

        // Open popup and show error message
        __showFailure : function(errMsg) {
            agrammon.ui.dialog.MsgBox.getInstance().error(
                this.tr('Error in communication with server'),
                errMsg
            );
        },

        // // Open login window and retry previous request after sucessful re-authentication
        // __reAuthenticate : function(methodName, data, resolve, reject) {
        //     let login = agrammon.modules.desktop.Login.getInstance();
        //     login.addListenerOnce('login', (e) => {
        //         // something is wrong, lets try to reload
        //         if (e == null || e.getData().login != agrammon.CurrentSession.getInstance().getUser().getLogin()) {
        //             window.location.reload(true);
        //         }
        //         this.post(methodName, data).then(
        //             (response) => {
        //                 resolve(response);
        //             },
        //             (error) => {
        //                 console.log(methodName, 'retry failed:', error);
        //                 reject(error);
        //             }
        //         );
        //     }, this);
        //     login.open();
        // }

    }
});

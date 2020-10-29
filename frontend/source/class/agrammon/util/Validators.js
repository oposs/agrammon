/* ************************************************************************

   http://www.oetiker.ch

   Copyright:
     2010- OETIKER+PARTNER AG, Switzerland, http://www.oetiker.ch

   License:
     LGPL: http://www.gnu.org/licenses/lgpl.html
     EPL: http://www.eclipse.org/org/documents/epl-v10.php
     See the LICENSE file in the project's top-level directory for details.

   Authors:
     * Fritz Zaucker (zaucker) @ OETIKER+PARTNER AG

************************************************************************ */


/**
 * Data validation functions
 */
qx.Class.define("agrammon.util.Validators",
{

  statics :
  {

    __fieldNotEmpty: function(value) {
        return (value != null && value != undefined && value.length > 0);
    },

    farmNumberRequired: function(value, item) {
        var valid = agrammon.util.Validators.__fieldNotEmpty(value);
        if (!valid) {
            item.setInvalidMessage(qx.locale.Manager.tr("Farm number required!"));
        }
        return valid;
    },

    addressRequired: function(value, item) {
        var valid = agrammon.util.Validators.__fieldNotEmpty(value);
        if (!valid) {
            item.setInvalidMessage(qx.locale.Manager.tr("Sender address required!"));
        }
        return valid;
    },


    /**
     * Create a single validator help function
     *
     * @param name {String} of the validator function
     * @param args {Array} of arguments to the validator function
     * @return {Function} the validator function
     */
    __createHelpTextFunc : function(multiLingualHelpText) {
        return function() {
            var locale = qx.locale.Manager.getInstance().getLocale();
            locale = locale.replace(/_.+/,'');
            return multiLingualHelpText[locale];
        };
    },

    /**
     * Create a single validator help function
     *
     * @param name {String} of the validator function
     * @param args {Array} of arguments to the validator function
     * @return {Function} the validator function
     * @lint ignoreDeprecated(alert)
     */
    __createHelpFunc : function(name, args) {
        var helpFunc;
        switch (name) {
            case 'gt':
                helpFunc = function() {
                    return qx.locale.Manager.tr("Input value must greater than")
                           + ' ' + args[0];
                };
                break;
            case 'ge':
                helpFunc = function() {
                    return qx.locale.Manager.tr("Input value must equal or greater than")
                           + ' ' + args[0];
                };
                break;
          case 'lt':
              helpFunc = function() {
                  return qx.locale.Manager.tr("Input value must less than")
                         + ' ' + args[0];
              };
              break;
          case 'le':
              helpFunc = function() {
                  return qx.locale.Manager.tr("Input value must equal or less than")
                         + ' ' + args[0];
              };
              break;
          case 'between':
              helpFunc = function() {
                  return qx.locale.Manager.tr("Enter a number between %1 and %2.", args[0], args[1]);
               };
              break;
          case 'match':
              helpFunc = function() {
                  return qx.locale.Manager.tr("Input value must match")
                         + " '" + args[0] + "' ";
              };
              break;
        default:
            alert(qx.locale.Manager.tr("Unknown validator function")+' '+name);
            break;
        }
        return helpFunc;
    },

    /**
     * Create a single validator function
     *
     * @param name {String} of the validator function
     * @param args {Array} of arguments to the validator function
     * @return {Function} the validator function
     * @lint ignoreDeprecated(alert)
     */
    __createFunc : function(name, args) {
        var valFunc;
        switch (name) {
            case 'gt':
                valFunc = function(value) {
                  value = parseFloat(value);
                  var high = parseFloat(args[0]);
                    if (! (value>high) ) {
                        return value + ' '
                            + qx.locale.Manager.tr("not bigger than")
                            + ' ' + args[0];
                    }
                    else {
                        return '';
                    }
                };
                break;
            case 'ge':
                valFunc = function(value) {
                  value = parseFloat(value);
                  var high = parseFloat(args[0]);
                    if (! (value>=high) ) {
                        return value + ' '
                            + qx.locale.Manager.tr("not equal or bigger than")
                            + ' ' + args[0];
                    }
                    else {
                        return '';
                    }
                };
                break;
          case 'lt':
              valFunc = function(value) {
                  value = parseFloat(value);
                  var low = parseFloat(args[0]);
                  if (! (value<low) ) {
                      return value + ' '
                          + qx.locale.Manager.tr("not less than")
                          + ' ' + args[0];
                  }
                  else {
                      return '';
                  }
              };
              break;
          case 'le':
              valFunc = function(value) {
                  value = parseFloat(value);
                  var low = parseFloat(args[0]);
                  if (! (value<=low) ) {
                      return value + ' '
                          + qx.locale.Manager.tr("not equal or less than")
                          + ' ' + args[0];
                  }
                  else {
                      return '';
                  }
              };
              break;
        case 'between':
              valFunc = function(value) {
                  value = parseFloat(value);
                  var low = parseFloat(args[0]);
                  var high = parseFloat(args[1]);
                  if (! (value >= low && value <= high) ) {
//                      alert('between: value='+value+', arg0='+args[0]+', arg1='+args[1]);
                      return value + ' ' +
                          qx.locale.Manager.tr("not between")
                          + ' ' + args[0] + ' '
                          + qx.locale.Manager.tr("and") + ' ' + args[1];
                  }
                  else {
                      return '';
                  }
              };
              break;
          case 'match':
              valFunc = function(value) {
                  var regexp = new RegExp(args[0]);
                  if (! value.match(regexp) ) {
                      return value + ' '
                          + qx.locale.Manager.tr("doesn't match") +
                          ' ' + args[0];
                  }
                  else {
                      return '';
                  }
              };
              break;
        default:
            alert(qx.locale.Manager.tr("Unknown validator function")+' '+name);
            break;
        }
        return valFunc;
    },

    getFunction: function(validators, type) {
        var valFunc = function(newValue, oldValue) {
            var regex;
            switch ( type ) {
            case "integer":
                regex = /^[+-]?[\d]+$/;
                break;
            case "float":
                regex = /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/;
                break;
            case "percent":
                regex = /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/;
                if (validators == undefined || validators == null) {
                    validators = [{name: 'between', args: [0, 100]}];
                }
                else if (validators[0] == undefined || validators[0].name != 'between') { // only once!
                    validators.splice(0,0,{name: 'between', args: [0, 100]});
                }
                break;
            }
            if ( (newValue == null) || (newValue == '') ) {
                return null;
            }
            if (regex != undefined) {
                if (! regex.test(newValue) ) {
                    qx.event.message.Bus.dispatchByName('error',
                            [ qx.locale.Manager.tr("Invalid input"),
                              newValue + ' '
                              + qx.locale.Manager.tr("is not a valid number for type ") + type ]);
                    return oldValue;
                }
            }
            if (validators == undefined) {
                return newValue;
            }
            var i, len=validators.length;
            var error='', ret;
            for (i=0; i<len; i++) {
                ret = (agrammon.util.Validators.__createFunc(validators[i].name,
                                                           validators[i].args))(newValue);
                if (ret) {
                    error += ret + '<br/>';
                }
            }
            if (error == '') {
                return newValue;
            }
            else {
                qx.event.message.Bus.dispatchByName('error',
                    [ qx.locale.Manager.tr("Invalid input"), error ]);
                return oldValue;
            }
        };
        return valFunc;
    },

    getHelpFunction: function(validators, type, multiLingualHelp) {
        var helpFunc = function() {
            var helpText;
            var help = '';
            var i, len;
            if (validators != undefined && validators.length > 0) {
                len = validators.length;
                for (i=0; i<len; i++) {
                    help += '<li>' + (agrammon.util.Validators.__createHelpFunc(validators[i].name,
                                                                               validators[i].args))()
                         + '</li>';
                }
            }
            else {
                switch (type) {
                case "integer":
                    help = qx.locale.Manager.tr("Type: integer");
                    break;
                case "float":
                    help = qx.locale.Manager.tr("Type: floating point number");
                    break;
                case "percent":
                    help = qx.locale.Manager.tr("Type: percentage");
                    break;
                }
                if (help) {
                    help = '<li>' + help + '</li>';
                }
            }
            if (help) {
                help = '<p><b>' + qx.locale.Manager.tr("Parameter validation")+'</b></p>'
                     + '<ul>' + help + '</ul>';
            }
            if (multiLingualHelp.en != undefined) {
                helpText =
                    (agrammon.util.Validators.__createHelpTextFunc(multiLingualHelp))();
            }
            else {
                helpText = '<p><em>'
                         + qx.locale.Manager.tr("Help text currently only available in German")
                         + '</em></p>'
                         + '<p>' + helpText + '</p>';
            }
            return helpText + help;
        };
        return helpFunc;
    }

//       getHelpFunction: function(validators, type, multiLingualHelp) {
//           var helpText;
// //          alert('multiLingualHelp.en='+multiLingualHelp.en);
//           var helpFunc = function() {
//             var help = '';
//             var i, len;
//             switch ( type ) {
//             case "integer":
//                 help = qx.locale.Manager.tr("Type: integer");
//                 break;
//             case "float":
//                 help = qx.locale.Manager.tr("Type: floating point number");
//                 break;
//             case "percent":
//                 help = qx.locale.Manager.tr("Type: percentage");
//                 break;
//             }
//             if (help) {
//                 help = '<li>' + help + '</li>';
//             }
//             if (validators != undefined) {
//                 len = validators.length;
//                 for (i=0; i<len; i++) {
//                     help += '<li>' + (agrammon.util.Validators.__createHelpFunc(validators[i].name,
//                                                                               validators[i].args))()
//                           + '</li>';
//                 }
//             }
//             if (help) {
//                 help = '<p><b>' + qx.locale.Manager.tr("Parameter validation")+'</b></p>'
//                      + '<ul>' + help + '</ul>';
//             }
//             if (multiLingualHelp.en != undefined) {
//                 helpText =
//                     (agrammon.util.Validators.__createHelpTextFunc(multiLingualHelp))();
//             }
//             else {
//                 helpText = '<p><em>'
//                      + qx.locale.Manager.tr("Help text currently only available in German")
//                 + '</em></p>'
//                 + '<p>' + helpText + '</p>';
//             }
//             return helpText + help;
//         };
//         return helpFunc;
//     }

  }
});

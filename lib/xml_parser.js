(function() {
  var isEmptyObject, normalize, parser, util;
  var __hasProp = Object.prototype.hasOwnProperty;

  parser = require('xml2json');

  util = require('util');

  isEmptyObject = function(object) {
    var k, v;
    for (k in object) {
      if (!__hasProp.call(object, k)) continue;
      v = object[k];
      return false;
    }
    return true;
  };

  normalize = function(object) {
    var k, v;
    for (k in object) {
      if (!__hasProp.call(object, k)) continue;
      v = object[k];
      if (typeof v === 'object' && !(v instanceof Array)) {
        if (isEmptyObject(v)) {
          object[k] = '';
        } else if (v.type != null) {
          switch (v.type) {
            case 'boolean':
              v = v.$t === 'true' ? true : false;
              break;
            case 'datetime':
              v = new Date(Date.parse(v.$t));
              break;
            case 'integer':
              v = parseInt(v.$t, 10);
              break;
            case 'array':
              delete v.type;
              v = v[Object.keys(v)[0]] || [];
              break;
            default:
              v = v.$t;
          }
          object[k] = v;
        } else {
          object[k] = normalize(v);
        }
      } else {
        object[k] = v;
      }
    }
    return object;
  };

  module.exports.parse = function(string) {
    return normalize(JSON.parse(parser.toJson(string)));
  };

}).call(this);

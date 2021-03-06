(function() {
  var camelize, extend, flattenObject, isEmptyObject, merge, underscore;
  var __hasProp = Object.prototype.hasOwnProperty;

  extend = exports.extend = function(object, properties) {
    var key, val;
    for (key in properties) {
      val = properties[key];
      object[key] = val;
    }
    return object;
  };

  merge = exports.merge = function(options, overrides) {
    return extend(extend({}, options), overrides);
  };

  flattenObject = exports.flattenObject = function(object) {
    var key, key2, val, val2;
    for (key in object) {
      val = object[key];
      if (!(typeof val === 'object' && val !== null)) continue;
      delete object[key];
      for (key2 in val) {
        val2 = val[key2];
        object["" + key + "[" + key2 + "]"] = typeof val2 === 'object' ? JSON.stringify(val2) : val2;
      }
    }
    return object;
  };

  camelize = exports.camelize = function(string) {
    return string.replace(/([\-\_][a-z0-9])/g, function(match) {
      return match.toUpperCase().replace('-', '').replace('_', '');
    });
  };

  underscore = exports.underscore = function(string) {
    return string.replace(/([A-Z])/g, function(match) {
      return "_" + match.toLowerCase();
    });
  };

  isEmptyObject = exports.isEmptyObject = function(object) {
    var k, v;
    for (k in object) {
      if (!__hasProp.call(object, k)) continue;
      v = object[k];
      return false;
    }
    return true;
  };

}).call(this);

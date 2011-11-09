(function() {
  var extend, flattenObject;
  extend = exports.extend = function(object, properties) {
    var key, val;
    for (key in properties) {
      val = properties[key];
      object[key] = val;
    }
    return object;
  };
  exports.merge = function(options, overrides) {
    return extend(extend({}, options), overrides);
  };
  flattenObject = exports.flattenObject = function(object) {
    var key, key2, val, val2;
    for (key in object) {
      val = object[key];
      if (typeof val === 'object' && val !== null) {
        delete object[key];
        for (key2 in val) {
          val2 = val[key2];
          object["" + key + "[" + key2 + "]"] = typeof val2 === 'object' ? JSON.stringify(val2) : val2;
        }
      }
    }
    return object;
  };
}).call(this);

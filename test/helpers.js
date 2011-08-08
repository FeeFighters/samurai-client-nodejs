/**
 * Samurai - test helpers
 * Copyright (c)2011, by FeeFighters <samurai@feefighters.com>
 * Licensed under MIT license (see LICENSE)
 */

var helpers = exports;
var createHash = require('crypto').createHash;

/**
 * Creates a SHA1 hash truncated to 24 characters from a given base
 *
 * This function is used by tests to generate fake keys. `base` can be any 
 * valid JavaScript object. It will be converted to a string using `toString` 
 * method.
 * 
 * @param {Object} base Any valid JavaScript object
 * @returns {String} SHA1 hexdigest of the base 
 */
helpers.generateKey = function(base) {
  var sha1 = createHash('sha1');
  sha1.update(base.toString());
  return sha1.digest('hex').slice(0, 24);
};

/**
 * Get date with specified number of months added
 *
 * @param {Number} months Number of months to add (positive or negative)
 * @returns {Date} A new `Date` object
 */
helpers.getAdjustedDate = function(months) {
  var today = new Date();
  var newMonth;
  var addYears;

  today.setHours(0);
  today.setMinutes(0);
  today.setSeconds(0);
  today.setMilliseconds(0);

  newMonth = today.getMonth() + months;
  if (newMonth > 11 || newMonth < 0) {
    // Convert surplus months to years
    addYears = Math.floor(newMonth / 12);
    newMonth = newMonth % 12;
  }
  if (addYears) {
    today.setYear(today.getFullYear() + addYears);
  }
  today.setMonth(newMonth);
  return today;
};

/**
 * Wrapper for getAdjustedDate that returns year and month
 *
 * @param {Number} months Number of months to add (positive or negative)
 * @returns {Array} Array containing year and month
 */
helpers.getAdjustedDateparts = function(months) {
  var newDate = helpers.getAdjustedDate(months);
  return [newDate.getFullYear(), newDate.getMonth() + 1];
};


/**
 * Get a random transaction amount that does not have error-code significance
 *
 * @returns {Number} random transaction amount
 */
helpers.getRandomAmount = function() {
  return Math.floor(Math.random()*1000)/100 + 11; // Random decimal + 11 (10 is "declined" error code)
};



/**
 * Assertion helpers
 */
var assert = require('nodeunit').assert;

assert.notOk = function(value, message) {
  if (!!value) assert.fail(value, true, message, "!=", assert.notOk);
};

assert.isDefined = function(object, message) {
  if (object == undefined) assert.fail(object, undefined, message, "should not be", assert.isDefined);
};
assert.isUndefined = function(object, message) {
  if (object != undefined) assert.fail(object, undefined, message, "should be", assert.isDefined);
};

assert.hasProperty = function(object, property, message) {
  if (undefined === object[property]) {
    assert.fail(object[property], 'defined', message, "should be", assert.hasProperty);
  }
};
assert.hasNoProperty = function(object, property, message) {
  if (undefined !== object[property]) {
    assert.fail(object[property], undefined, message, "should be", assert.hasProperty);
  }
};

assert.contains = function(array, object, message) {
  assert.isDefined(array);
  if (array.indexOf(object) == -1) {
    assert.fail(array, object, message, "should contain", assert.contains);
  }
};
assert.notContain = function(array, object, message) {
  assert.isDefined(array);
  if (array.indexOf(object) >= 0) {
    assert.fail(array, object, message, "should not contain", assert.notContain);
  }
};

assert.hasKeys = function(array, keys, message) {
  assert.isDefined(array);
  var actual = Object.keys(array);
  var ok = keys.every(function(key){
    return ~actual.indexOf(key);
  });
  if (!ok) {
    assert.fail(array, keys, message, "should contain keys", assert.hasKeys);
  }
};

assert.isInstanceOf = function(object, type, message) {
  if (!(object instanceof type)) {
    assert.fail(object, type, message, "should be an instance of", assert.isInstanceOf);
  }
};

assert.isEmpty = function(array, message) {
  assert.isDefined(array);
  if (array.length > 0) {
    assert.fail(array, 'empty array', message, "should be", assert.isEmpty);
  }
};

assert.isNotEmpty = function(array, message) {
  assert.isDefined(array);
  if (array.length == 0) {
    assert.fail(array, 'empty array', message, "should not be", assert.isNotEmpty);
  }
};



/**
 * Config debug helpers
 */
//var config = require('config');
//
//config.debug = function(message) {
//  if (settings.debug) {
//    util.debug(message);
//  }
//};

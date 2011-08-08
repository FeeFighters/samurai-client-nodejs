/**
 * # error
 *
 * Copyright (c)2011, by FeeFighters <samurai@feefighters.com>
 *
 * SamuraiError object used as the main error object throughout the Samurai 
 * implementation.
 *
 * @author FeeFighters <samurai@feefighters.com>
 * @license MIT (see LICENSE)
 */

var util = require('util');

/**
 * ## error.SamuraiError
 * *Samurai error object*
 * 
 * @constructor
 */
function SamuraiError(category, message, details) {
  Error.call(this);
  Error.captureStackTrace(this, this.constructor);
  this.category = category;
  this.message = message;
  this.details = details;
  this.name = this.constructor.name;
}

util.inherits(SamuraiError, Error);

SamuraiError.prototype.toString = function() {
  return this.category + ': ' + this.message + ': ' +
    util.inspect(this.details);
};

module.exports = SamuraiError;

/**
 * #config
 * 
 * Copyright (c)2011, by FeeFighters
 *
 * Configuration methods and settings for Samurai. All startup configuration
 * settings are set using the `config.configure()` and `config.option()`
 * methods. Most options can only be set once, and subsequent attempts to set
 * them will result in an error. To avoid this, pass the
 * `allowMultipleSetOption` option to `config.configure()` and set it to 
 * `true`. (The option has a long name to prevent accidental usage.)
 *
 * @author FeeFighters <samurai@feefighters.com>
 * @license MIT (see LICENSE)
 */

var config = exports;
var util = require('util');
var SamuraiError = require('./error');
var samurayKeyRe = /^[0-9a-f]{24}$/;
var isConfigured = false;

config.SAMURAI_VERSION = '0.1.5';

/**
 * ## settings
 * *Master configuration settings for Samurai*
 * 
 * The `settings` object contains all the core configuration options that 
 * affect the way certain things work (or not), and the Samurai gateway 
 * credentials. You should _not_ access this object directly. The correct way
 * to access and set the settings is through either ``configure()`` or 
 * ``option()`` methods.
 *
 * Settings are expected to contain following keys with their default values:
 *
 *  + _merchantKey_: Samurai gateway Merchant Key (default: `''`)
 *  + _merchantPassword_: Samurai gateway API Password (default: `''`)
 *  + _processorToken_: Processor (gateway) ID; be sure to set this to a sandbox
 *    ID for testing (default: `''`)
 *  + _currency_: Default currency for all transactions (can be overriden by
 *    specifying the appropriate options in transaction objects)
 *  + _allowedCurrencies_: Array containing the currencies that can be used
 *    in transactions. (default: ['USD'])
 *  + _sandbox_: All new payment methods will be sandbox payment methods 
 *    (default: false)
 *  + _enabled_: Whether to actually make requests to gateway (default: true)
 *  + _debug_: Whether to log to STDOUT; it is highly recommended that 
 *    you disable this in production, to remain PCI comliant, and to 
 *    avoid performance issues (default: true)
 *
 * Only `currency` option can be set multiple times. All other options can only
 * be set once using the ``config.configure()`` method.
 *
 * The ``apiVersion`` setting is present for conveinence and is should be 
 * treated as a constant (i.e., read-only).
 */
var settings = {};
settings.merchantKey = '';
settings.merchantPassword = '';
settings.processorToken = '';
settings.currency = 'USD';
settings.allowedCurrencies = ['USD'];
settings.sandbox = false;
settings.enabled = true; // Does not make any actual API calls if false
settings.debug = false; // Enables *blocking* debug output to STDOUT
settings.apiVersion = 1; // Don't change this... unless you need to
settings.allowMultipleSetOption = false;

/**
 * ## config.debug(message)
 * *Wrapper around `util.debug` to log items in debug mode*
 *
 * This method is typically used by Samurai implementation to output debug 
 * messages. There is no need to call this method outside of Samurai.
 *
 * Note that any debug messages output using this function will block 
 * execution temporarily. It is advised to disable debug setting in production 
 * to prevent this logger from running.
 * 
 * @param {Object} message Object to be output as a message
 * @private
 */
config.debug = debug = function(message) {
  if (settings.debug) {
    util.debug(message);
  }
};

/**
 * ## config.configure(opts)
 * *Set global Samurai configuration options*
 *
 * This method should be used before using any of the Samurai's functions. It
 * sets the options in the `settings` object, and performs basic validation 
 * of the options before doing so.
 *
 * Unless you also pass it the `allowMultipleSetOption` option with value set 
 * to `true`, you will only be able to call this method once. This is done to 
 * prevent accidental calls to this method to modify critical options that may
 * affect the security and/or correct operation of your system.
 *
 * This method depends on ``config.option()`` method to set the individual 
 * options.
 *
 * If an invalid option is passed, it will throw an error.
 *
 * @param {Object} Configuration options
 */
config.configure = function(opts) {
  debug('Configuring Samurai with: \n' + util.inspect(opts));
  if (!opts.merchantKey || !opts.merchantPassword || !opts.processorToken) {
    throw new SamuraiError('system', 'Incomplete Samurai API credentials', opts);
  }
  Object.keys(opts).forEach(function(key) {
    config.option(key, opts[key]);
  });
  isConfigured = true;
};

/**
 * ## config.option(name, [value])
 * *Returns or sets a single configuration option*
 *
 * If value is not provided this method returns the value of the named
 * configuration option key. Otherwise, it sets the value and returns it.
 *
 * Setting values can only be set once for most options. An error will be 
 * thrown if you try to set an option more than once. This restriction exist
 * to prevent accidental and/or malicious manipulation of critical Samurai 
 * configuration options.
 *
 * During testing, you may set the `allowMultipleSetOption` to `true` in order
 * to enable multiple setting of protected options. Note that once this option
 * is set to `false` it can no longer be set to true.
 *
 * Samurai API credentials are additionally checked for consistency. If they 
 * do not appear to be valid keys, an error will be thrown.
 *
 * @param {String} option Name of the option key
 * @param {Object} value New value of the option
 * @returns {Object} Value of the `option` key
 */
config.option = function(option, value) {
  if (typeof value !== 'undefined') {
    if (option != 'debug')
      debug('Setting Samurai key `' + option + '` to `' + value.toString() + '`');
    
    // Do not allow an option to be set twice unless it's `currency`
    if (isConfigured && 
        !settings.allowMultipleSetOption && 
        option !== 'currency') {
      throw new SamuraiError(
        'system', 
        'Option ' + option + ' is already locked', 
        option);
    }

    switch (option) {
    case 'merchantKey':
    case 'merchantPassword':
    case 'processorToken':
      // Throw if doesn't look like valid key
      if (!samurayKeyRe.exec(value)) {
        throw new SamuraiError('system', 'Invalid setting', option);
      }
      settings[option] = value;
      break;
    case 'currency':
      settings[option] = value;
      break;
    case 'sandbox':
    case 'enabled':
    case 'debug':
    case 'allowMultipleSetOption':
      settings[option] = Boolean(value);
      break;
    case 'allowedCurrencies':
      if (!Array.isArray(value)) {
        throw new SamuraiError('system', 'Allowed currencies must be an array', null);
      }
      if (value.indexOf(settings.currency) < 0) {
        value.push(settings.currency);
      }
      settings.allowedCurrencies = value;
      break;
    default:
      // Do not allow unknown options to be set
      throw new SamuraiError('system', 'Unrecognized configuration option', option);
    }
  }
  return settings[option];
};


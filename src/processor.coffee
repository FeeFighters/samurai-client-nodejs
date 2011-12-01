{extend}                 = require './helpers'
{get, post, put, config} = require './connection'
Transaction              = require './transaction'
util = require 'util'

class Processor
  # -- Class Methods --

  # Returns the default processor specified by `processor_token` if you passed it into `Samurai.setup`.
  @theProcessor: ->
    theProcessor = new Processor(config.processor_token)
    @theProcessor = -> theProcessor
    theProcessor

  # Convenience method for creating a new purchase with the default processor.
  @purchase: -> @theProcessor().purchase.apply @theProcessor(), arguments
  
  # Convenience method for creating a new authorization with the default processor.
  @authorize: -> @theProcessor().authorize.apply @theProcessor(), arguments

  # Returns a `Processor` object for the specified `processorToken`.
  @find: (@processorToken) ->
    new Processor(@processorToken)

  constructor: (@processorToken) ->

  # -- Methods --

  # Convenience method to authorize and capture a payment_method for a particular amount in one transaction.
  # Parameters:
  #
  # * `paymentMethodToken`: token identifying the payment method to authorize
  # * `amount`: amount to authorize
  # * `options`: an optional has of additional values to pass in accepted values are:
  #   * `descriptor`: descriptor for the transaction
  #   * `custom`: custom data, this data does not get passed to the processor, it is stored within `api.samurai.feefighters.com` only
  #   * `customer_reference`: an identifier for the customer, this will appear in the processor if supported
  #   * `billing_reference`: an identifier for the purchase, this will appear in the processor if supported
  #
  # Returns a Samurai.Transaction containing the processor's response.
  purchase: (paymentMethodToken, amount, options = {}, callback) ->
    extend options, payment_method_token: paymentMethodToken, amount: amount
    post @pathFor('purchase'), @prepareTransactionData(options), @createResponseHandler(callback)

  # Authorize a payment_method for a particular amount.
  # Parameters:
  #
  # * `paymentMethodToken`: token identifying the payment method to authorize
  # * `amount`: amount to authorize
  #
  # * options: an optional has of additional values to pass in accepted values are:
  #   * `descriptor`: descriptor for the transaction
  #   * `custom`: custom data, this data does not get passed to the processor, it is stored within api.samurai.feefighters.com only
  #   * `customer_reference`: an identifier for the customer, this will appear in the processor if supported
  #   * `billing_reference`: an identifier for the purchase, this will appear in the processor if supported
  #
  # Returns a Samurai.Transaction containing the processor's response.
  authorize: (paymentMethodToken, amount, options = {}, callback) ->
    extend options, payment_method_token: paymentMethodToken, amount: amount
    post @pathFor('authorize'), @prepareTransactionData(options), @createResponseHandler(callback)

  # -- Helpers --

  # Creates a new response handler that returns the `Transaction`
  # object, associated with the request.
  createResponseHandler: (callback) ->
    transaction = new Transaction()
    transaction.createResponseHandler(callback)

  # Returns the API endpoint that should be used for `method`.
  pathFor: (method) ->
    root = 'processors/' + @processorToken + '/'

    switch method
      when 'purchase'
        root + 'purchase.xml'
      when 'authorize'
        root + 'authorize.xml'

  # Wraps transaction data in an additional transaction object,
  # according to spec.
  prepareTransactionData: (options) ->
    return transaction: options
  
  # -- Accessors --
  
module.exports = Processor

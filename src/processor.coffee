{extend}                 = require './helpers'
{get, post, put, config} = require './connection'
Transaction              = require './transaction'

class Processor
  # -- Class Methods --

  # Returns the default processor specified by processor_token if you passed it into Samurai.setupSite.
  @theProcessor: ->
    theProcessor = new Processor(config.processor_token)
    @theProcessor = -> theProcessor
    theProcessor

  @purchase: -> @theProcessor().purchase.apply @theProcessor(), arguments
  @authorize: -> @theProcessor().authorize.apply @theProcessor(), arguments

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
  createResponseHandler: (callback) ->
    (err, response) =>
      transaction = new Transaction()
      if err
        transaction.attributes?.processor_response?.success = false
      else
        transaction.updateAttributes(response.transaction)
      transaction.processResponseMessages(response)

      callback?(err, transaction)

  pathFor: (method) ->
    root = 'processors/' + @processorToken + '/'

    switch method
      when 'purchase'
        root + 'purchase.xml'
      when 'authorize'
        root + 'authorize.xml'

  prepareTransactionData: (options) ->
    return transaction: options
  
  # -- Accessors --
  
module.exports = Processor

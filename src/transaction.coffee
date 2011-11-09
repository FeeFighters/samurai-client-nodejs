{extend}         = require './helpers'
{get, post, put} = require './connection'
Message          = require './message'

# This class represents a Samurai Transaction
# It can be used to query Transactions & capture/void/credit/reverse
class Transaction
  KNOWN_ATTRIBUTES = [
    'amount',             'type',              'payment_method_token',
    'currency_code',      'descriptor',        'custom',
    'customer_reference', 'billing_reference', 'processor_response'
  ]

  # -- Class Methods --
  @find: (referenceId, callback) ->
    transaction = new Transaction(transaction_token: referenceId)
    get transaction.pathFor('show'), null, (err, response) ->
      transaction.updateAttributes(response.transaction)
      callback?(err, transaction)

  constructor: (@attributes={}) ->
    @errors = {}
    @messages = {}

  # -- Methods --

  # Captures an authorization. Optionally specify an `amount` to do a partial capture of the initial
  # authorization. The default is to capture the full amount of the authorization.
  capture: (amount, options={}, callback) ->
    if typeof amount is 'function'
      callback = amount
      amount = @attributes.amount
    else
      amount ?= @attributes.amount

    if typeof options is 'function'
      callback = options
      options = {}

    extend options, amount: amount
    post @pathFor('capture'), options, @createResponseHandler(callback)

  # Void this transaction. If the transaction has not yet been captured and settled it can be voided to 
  # prevent any funds from transferring.
  void: (options={}, callback) ->
    if typeof options is 'function'
      callback = options
      options = {}

    post @pathFor('void'), options, @createResponseHandler(callback)

  # Create a credit or refund against the original transaction.
  # Optionally accepts an `amount` to credit, the default is to credit the full
  # value of the original amount
  credit: (amount, options={}, callback) ->
    if typeof amount is 'function'
      callback = amount
      amount = @attributes.amount
    else
      amount ?= @attributes.amount

    if typeof options is 'function'
      callback = options
      options = {}

    extend options, amount: amount
    post @pathFor('credit'), options, @createResponseHandler(callback)

  # Reverse this transaction.  First, tries a void.
  # If a void is unsuccessful, (because the transaction has already settled) perform a credit for the full amount.
  reverse: (amount, options={}, callback) ->
    if typeof amount is 'function'
      callback = amount
      amount = @attributes.amount
    else
      amount ?= @attributes.amount

    if typeof options is 'function'
      callback = options
      options = {}

    extend options, amount: amount
    post @pathFor('reverse'), options, @createResponseHandler(callback)

  # -- Helpers --
  isSuccess: ->
    @attributes.processor_response?.success

  isFailed: ->
    return !@isSuccess()

  createResponseHandler: (callback) ->
    (err, response) =>
      if err
        @attributes.processor_response?.success = false
      else
        @updateAttributes(response.transaction) if response?.transaction?

      @processResponseMessages(response)

      callback?(err, this)

  pathFor: (method) ->
    root = 'transactions'

    switch method
      when 'show'
        root + '/' + @token() + '.xml'
      else
        root + '/' + @token() + '/' + method + '.xml'

  updateAttributes: (attributes) ->
    # sometimes the returned transaction would not have all of the
    # original transaction's data, so this makes sure we don't
    # overwrite data that we already have with blank values
    for attr, value of attributes
      unless attr of @attributes and value is ''
        @attributes[attr] = value

    @attributes

  extractMessagesFromResponse: (response) ->
    messages = []
    extr = (hash) ->
      for own key, value of hash
        if key is 'messages'
          messages = messages.concat(value)
        else
          extr(value) if typeof value is 'object'

    extr(response)
    # sometimes a message is returned as a shallow object in an array of messages,
    # sometimes it's inside an additional `message` object wrapper. This expression
    # makes sure the two are the same.
    messages = for m in messages
      if m.message then m.message else m

  processResponseMessages: (response) ->
    # find messages array
    messages = @extractMessagesFromResponse(response)
    @messages = {}
    @errors = {}
    
    for message in messages
      m = new Message(message.subclass, message.context, message.key, message.$t)
      message.context = 'system.general' if message.context is ''

      if message.subclass is 'error'
        if message.context of @errors
          @errors[message.context].push m
        else
          @errors[message.context] = [m]
      else
        if message.context of @messages
          @messages[message.context].push m
        else
          @messages[message.context] = [m]

  # -- Accessors --
  token: -> @attributes.transaction_token
  
module.exports = Transaction

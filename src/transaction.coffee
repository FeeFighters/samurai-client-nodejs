Message = require './message'

{ extend
, camelize
} = require './helpers'

{ get
, post
, put
} = require './connection'

# This class represents a Samurai Transaction
# It can be used to query Transactions & capture/void/credit/reverse
class Transaction
  KNOWN_ATTRIBUTES =
    [  'amount'
    ,  'type'
    ,  'payment_method_token'
    ,  'currency_code'
    ,  'descriptor'
    ,  'custom'
    ,  'customer_reference'
    ,  'billing_reference'
    ]

  # -- Class Methods --

  # Find the transaction, identified by `referenceId` and then passes it
  # as a second argument to `callback`. Note that the reference id of a
  # transaction isn't the same as the transaction token. When trying to
  # fetch a transaction, always use its reference id.
  @find: (referenceId, callback) ->
    transaction = new Transaction(reference_id: referenceId)
    get transaction.pathFor('show'), null, (err, response) ->
      transaction.updateAttributes(response.transaction)
      callback?(err, transaction)

  constructor: (@attributes={}) ->
    @errors = {}
    @messages = {}
    @createAttrAliases()

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
  # The `options` parameter is optional and can be replaced by the
  # `callback` parameter. For example:
  #   
  #   myTransaction.void(null, myCallback);
  #
  # can be written as:
  #
  #   myTransaction.void(myCallback);
  #
  void: (options={}, callback) ->
    if typeof options is 'function'
      callback = options
      options = {}

    post @pathFor('void'), options, @createResponseHandler(callback)

  # Create a credit or refund against the original transaction.
  # Optionally accepts an `amount` to credit, the default is to credit the full
  # value of the original amount.
  # The `amount` and `options` parameters are optional. By the default,
  # the `amount` is the full amount specified in the original
  # transaction. If you choose to skip one of these parameters, you can
  # put the `callback` parameter in their place. For example:
  #
  #   myTransaction.credit(null, null, myCallback);
  #
  # could be written as:
  #
  #   myTransaction.credit(myCallback);
  #
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
  # The `amount` and `options` parameters are optional. By the default,
  # the `amount` is the full amount specified in the original
  # transaction. If you choose to skip one of these parameters, you can
  # put the `callback` parameter in their place. For example:
  #
  #   myTransaction.reverse(null, null, myCallback);
  #
  # could be written as:
  #
  #   myTransaction.reverse(myCallback);
  #
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

  # Creates a response handler that parses the Samurai response for
  # messages (info or error) and updates the current transaction's
  # information. Then, the response handler passes the HTTP error object
  # and the current transaction object to the `callback`.
  createResponseHandler: (callback) ->
    (err, response) =>
      if err
        @attributes.processor_response?.success = false
      else
        @updateAttributes(response.transaction) if response?.transaction?

      @processResponseMessages(response)

      callback?(err, this)

  # Returns the API endpoint that should be used for `method`.
  pathFor: (method) ->
    root = 'transactions'

    switch method
      when 'show'
        root + '/' + @attributes.reference_id + '.xml'
      else
        root + '/' + @token + '/' + method + '.xml'

  # Updates the `attributes` object with newly returned information.
  updateAttributes: (attributes) ->
    # sometimes the returned transaction would not have all of the
    # original transaction's data, so this makes sure we don't
    # overwrite data that we already have with blank values
    for attr, value of attributes
      unless attr of @attributes and value is ''
        @attributes[attr] = value

    # Defined accessors for camelized versions of attributes.
    # E.g.: `obj.attributes.first_name` can be accessed from `obj.firstName`.
    @defineAttrAccessor(prop) for prop of @attributes when prop not of this

  # Defines an accessor for the property `prop` of the internal
  # `attributes` object. Setter are only defined for properties that are
  # part of the `KNOWN_ATTRIBUTES` array.
  defineAttrAccessor: (prop) ->
    @defineAttrGetter(prop) unless this.__lookupGetter__(camelize(prop))
    @defineAttrSetter(prop) unless this.__lookupSetter__(camelize(prop)) or KNOWN_ATTRIBUTES.indexOf(prop) is -1

  defineAttrGetter: (prop) ->
    this.__defineGetter__ camelize(prop), -> @attributes[prop]

  defineAttrSetter: (prop) ->
    this.__defineSetter__ camelize(prop), (value) -> @attributes[prop] = value

  # Finds all messages returned in a Samurai response, regardless of
  # what part of the response they were in.
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

  # Finds message blocks in the Samurai response, creates a `Message`
  # object for each one and stores them in either the `messages` or the
  # `errors` object, depending on the message type.
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
  createAttrAliases: ->
    this.__defineGetter__ 'token', -> @attributes.transaction_token
  
module.exports = Transaction

{extend}         = require './helpers'
{get, post, put} = require './connection'
Message          = require './message'

class PaymentMethod
  KNOWN_ATTRIBUTES = [
    'first_name',
    'last_name',
    'address_1',
    'address_2',
    'city',
    'state',
    'zip',
    'card_number',
    'cvv',
    'expiry_month',
    'expiry_year',
    'custom'
  ]

  # -- Class Methods --
  @create: (attributes = {}, callback) ->
    paymentMethod = new PaymentMethod(attributes)
    paymentMethod.save(callback)
    paymentMethod

  @find: (token, callback) ->
    paymentMethod = new PaymentMethod(payment_method_token: token)
    get paymentMethod.pathFor('show'), null, (err, response) ->
      paymentMethod.updateAttributes(response.payment_method)
      callback?(err, paymentMethod)

  constructor: (@attributes = {}) ->
    @isNew = if @attributes.payment_method_token? then false else true
    @errors = {}
    @messages = {}

  # -- Methods --

  # Retains the payment method on `api.samurai.feefighters.com`. Retain a payment method if
  # it will not be used immediately. 
  retain: (callback) ->
    post @pathFor('retain'), null, @createResponseHandler(callback)

  # Redacts sensitive information from the payment method, rendering it unusable.
  redact: (callback) ->
    post @pathFor('redact'), null, @createResponseHandler(callback)

  save: (callback) ->
    if @isNew
      post @pathFor('create'), { payment_method: @sanitizedAttributes() }, @createResponseHandler((err, pm) => @isNew = false; callback?(err, pm))
    else
      put  @pathFor('update'), { payment_method: @sanitizedAttributes() }, @createResponseHandler(callback)

  # -- Helpers --
  sanitizedAttributes: ->
    attr = {}
    attr[key] = val for key, val of @attributes when KNOWN_ATTRIBUTES.indexOf(key) > -1
    attr

  createResponseHandler: (callback) ->
    (err, response) =>
      if err
        @attributes.success = false
      else
        @updateAttributes(response.payment_method) if response.payment_method?

      @processResponseMessages(response)

      callback?(err, this)

  pathFor: (method) ->
    root = 'payment_methods'
    switch method
      when 'create'
        root + '.json'
      when 'update'
        root + '/' + @token() + '.json'
      when 'show'
        root + '/' + @token() + '.xml'
      else
        root + '/' + @token() + '/' + method + '.xml'

  updateAttributes: (attributes) ->
    extend(@attributes, attributes)

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

  # Alias for `attributes.payment_method_token`
  token: -> @attributes.payment_method_token

  # Retrieves JSON formatted custom data that is encoded in the custom_data attribute
  customJSONData: ->
    data = {}
    if @attributes.custom?
      try
        data = JSON.parse(@attributes.custom)
      catch error
        data = {}
    data

module.exports =
  create: PaymentMethod.create
  find:   PaymentMethod.find

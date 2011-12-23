Message  = require './message'

{ extend
, camelize
, isEmptyObject
} = require './helpers'

{ get
, post
, put
, config
} = require './connection'

# The PaymentMethod class lets you create, update, retain and redact 
# payment methods.
class PaymentMethod
  KNOWN_ATTRIBUTES =
    [  'first_name'
    ,  'last_name'
    ,  'address_1'
    ,  'address_2'
    ,  'city'
    ,  'state'
    ,  'zip'
    ,  'card_number'
    ,  'cvv'
    ,  'expiry_month'
    ,  'expiry_year'
    ,  'custom'
    ,  'sandbox'
    ]

  # -- Class Methods --
  #
  # Creates a new payment method and passes it to the callback function.
  # Parameters:
  #   * `attributes`: An object containing the personal and
  #   credit card information you want stored with this new payment
  #   method.
  #   * `callback`: A function that accepts two parameters: (err,
  #   paymentMethod). The `err` parameter contains the HTTP error that
  #   occurred while attempting to create the payment method. The second
  #   `paymentMethod` passes the same object that will be returned from
  #   `PaymentMethod.create()` and is there just for convenience.
  @create: (attributes = {}, callback) ->
    paymentMethod = new PaymentMethod(attributes)
    paymentMethod.save(callback)
    paymentMethod

  # Retrieves the payment method identified by `token`.
  @find: (token, callback) ->
    paymentMethod = new PaymentMethod(payment_method_token: token)
    get paymentMethod.pathFor('show'), null, paymentMethod.createResponseHandler(callback)
    paymentMethod

  # Creates a new payment method object, but does not save it to the
  # Samurai servers. Use the `save()` method on the returned payment method
  # object to save it.
  constructor: (@attributes = {}) ->
    @attributes = extend({}, @attributes)
    extend(@attributes, sandbox: true) if config.sandbox
      
    @isNew = if @attributes.payment_method_token? then false else true
    @errors = {}
    @messages = {}
    @createAttrAliases()

  # -- Methods --

  # Retains the payment method on `api.samurai.feefighters.com`. Retain a payment method if
  # it will not be used immediately. 
  retain: (callback) ->
    post @pathFor('retain'), null, @createResponseHandler(callback)

  # Redacts sensitive information from the payment method, rendering it unusable.
  redact: (callback) ->
    post @pathFor('redact'), null, @createResponseHandler(callback)

  # Saves the payment method to the Samurai servers if this is a new
  # payment method, or updates the information for an existing payment
  # method.
  save: (callback) ->
    if @isNew
      post @pathFor('create'), { payment_method: @sanitizedAttributes() }, @createResponseHandler((err, pm) => @isNew = false; callback?(err, pm))
    else
      put  @pathFor('update'), { payment_method: @sanitizedAttributes() }, @createResponseHandler(callback)

  # -- Helpers --
  hasErrors: ->
    !isEmptyObject(@errors)
  
  # Makes sure that the payment method attributes we send to the Samurai API are part
  # of the KNOWN_ATTRIBUTES array.
  sanitizedAttributes: ->
    attr = {}
    attr[key] = val for key, val of @attributes when KNOWN_ATTRIBUTES.indexOf(key) > -1
    attr

  # Creates a response handler that parses the Samurai response for
  # messages (info or error) and updates the current payment method's
  # information. Then, the response handler passes the HTTP error object
  # and the current payment method object to the `callback`.
  createResponseHandler: (callback) ->
    (err, response) =>
      if err
        @attributes.success = false
        @updateAttributes(response.error) if response.error?
      else
        @updateAttributes(response.payment_method) if response.payment_method?

      @processResponseMessages(response)

      callback?(err, this)

  # Returns the API endpoint that should be used for `method`.
  pathFor: (method) ->
    root = 'payment_methods'
    switch method
      when 'create'
        root + '.json'
      when 'update'
        root + '/' + @token + '.json'
      when 'show'
        root + '/' + @token + '.xml'
      else
        root + '/' + @token + '/' + method + '.xml'

  # Updates the `attributes` object with newly returned information.
  updateAttributes: (attributes) ->
    extend(@attributes, attributes)
    
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
    
    # Sort the messages so that more-critical/relevant ones appear first,
    # since only the first error is added to a field
    order = ['is_blank', 'not_numeric', 'too_short', 'too_long', 'failed_checksum']
    messages = messages.sort (a, b) ->
      a = order.indexOf(a.key)
      b = order.indexOf(b.key)
      a = 0 if a is -1
      b = 0 if b is -1

      if a < b then -1 else if a > b then 1 else 0

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
    # Alias for `attributes.payment_method_token`
    this.__defineGetter__ 'token', -> @attributes.payment_method_token

    # Retrieves JSON formatted custom data that is encoded in the custom_data attribute
    this.__defineGetter__ 'customJsonData', ->
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

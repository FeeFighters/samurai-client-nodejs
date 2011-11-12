vows            = require 'vows'
assert          = require 'assert'
{PaymentMethod} = require './support/test_helper'

vows
  .describe('PaymentMethod actions')
  .addBatch
    'when a new payment method is created':
      topic: ->
        PaymentMethod.create {
            first_name:   "sean",
            last_name:    "harper",
            city:         "Chicago",
            zip:          "53211",
            expiry_month: 03,
            cvv:          "123",
            card_number:  "4111111111111111",
            address_1:    "1240 W Monroe #1",
            address_2:    "",
            expiry_year:  "2015",
            state:        "IL",
            custom:
              id:         5,
              reference:  'foo'
          },
          this.callback

        return
          
      'it should contain a 24-character long string token': (err, paymentMethod) ->
        token = paymentMethod.token
        assert.isString token
        assert.equal token.length, 24

      'we should be able to read its properties as normal object properties': (err, paymentMethod) ->
        assert.equal paymentMethod.firstName, 'sean'
        assert.equal paymentMethod.lastName, 'harper'

      'we should be able to set its properties as normal object properties':
        topic: (paymentMethod) ->
          paymentMethod.firstName = 'John'
          paymentMethod.lastName = 'Smith'
          paymentMethod
        
        'and the corresponding entries in the attributes object should update': (paymentMethod) ->
          assert.equal paymentMethod.firstName, 'John'
          assert.equal paymentMethod.lastName, 'Smith'

      'and we retain it':
        topic: (paymentMethod) ->
          paymentMethod.retain this.callback
          return

        'it should be marked as retained': (err, paymentMethod) ->
          assert.equal paymentMethod.attributes.is_retained, true

      'and we redact it':
        topic: (paymentMethod) ->
          paymentMethod.redact this.callback
          return

        'it should be marked as redacted': (err, paymentMethod) ->
          assert.equal paymentMethod.attributes.is_redacted, true

      'and we edit its attributes':
        topic: (paymentMethod) ->
          paymentMethod.attributes.first_name = 'John'
          paymentMethod.attributes.last_name = 'Smith'
          paymentMethod.save(this.callback)
          return

        'it should save the new values for these attributes': (err, paymentMethod) ->
          assert.equal paymentMethod.attributes.first_name, 'John'
          assert.equal paymentMethod.attributes.last_name, 'Smith'

      'and we then try to find() it on the server':
        topic: (paymentMethod) ->
          PaymentMethod.find(paymentMethod.token, this.callback)
          return

        'the server should return the same payment method': (err, paymentMethod) ->
          assert.isNotNull paymentMethod.token

        'the payment method should hold unserialized custom data': (err, paymentMethod) ->
          assert.deepEqual paymentMethod.customJsonData, { id: 5, reference: 'foo' }

  .export(module)

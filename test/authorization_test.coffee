vows                       = require 'vows'
assert                     = require 'assert'
{PaymentMethod, Processor, Transaction, createTestPaymentMethod} = require './support/test_helper'

createTestAuthorization = (callback) ->
  createTestPaymentMethod (token) ->
    Processor.authorize(
      token,
      1.0,
      billing_reference: Math.round(Math.random()*1000),
      callback)

vows
  .describe('Authorizations')
  .addBatch
    'should create a new authorization transaction':
      topic: ->
        createTestAuthorization(this.callback)
        return

      'and the processor response should be successful': (err, transaction) ->
        assert.equal transaction.isSuccess(), true

      'and when we try to find that transaction':
        topic: (original) ->
          Transaction.find(original.attributes.reference_id, (err, found) =>
            this.callback(found, original)
          )
          return

        'the server should return it': (found, original) ->
          assert.equal found.attributes.reference_id, original.attributes.reference_id

      'and when we capture it with a specific amount':
        topic: (transaction) ->
          transaction.capture(1.0, this.callback)
          return

        'the capture should be successful': (err, transaction) ->
          assert.equal transaction.isSuccess(), true

      'and when we capture it without a specific amount':
        topic: ->
          createTestAuthorization (err, transaction) =>
            transaction.capture(null, this.callback)
          return

        'the capture should be for the full amount': (err, transaction) ->
          assert.equal transaction.isSuccess(), true
          assert.equal transaction.attributes.amount, '1.0'

      'and when we partially capture it':
        topic: ->
          createTestAuthorization (err, transaction) =>
            transaction.capture(0.5, this.callback)
          return

        'the capture should be for the specified amount': (err, transaction) ->
          assert.equal transaction.isSuccess(), true
          assert.equal transaction.attributes.amount, '0.5'

      'and when we credit it without a specific amount':
        topic: ->
          createTestAuthorization (err, transaction) =>
            transaction.capture(null, (err, transaction) =>
              transaction.credit(null, this.callback)
            )
          return

        'the credit should be for the full amount': (err, transaction) ->
          assert.equal transaction.isSuccess(), true
          assert.equal transaction.attributes.amount, '1.0'

      'and when we partially credit it':
        topic: ->
          createTestAuthorization (err, transaction) =>
            transaction.capture(null, (err, transaction) =>
              transaction.credit(0.5, this.callback)
            )
          return

        'the credit should be for the specified amount': (err, transaction) ->
          assert.equal transaction.isSuccess(), true
          assert.equal transaction.attributes.amount, '0.5'

      'and when we void it':
        topic: ->
          createTestAuthorization (err, transaction) =>
            transaction.void(this.callback)
          return

        'the processor response should be successful': (err, transaction) ->
          assert.equal transaction.isSuccess(), true

  .export(module)
            

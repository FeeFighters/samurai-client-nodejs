vows   = require 'vows'
assert = require 'assert'
util   = require 'util'
{ PaymentMethod
, Processor
, Transaction
, Connection
, createTestPaymentMethod
} = require './support/test_helper'

createTestPurchase = (amount, callback) ->
  createTestPaymentMethod (token) ->
    Processor.purchase(
      token,
      amount,
      billing_reference: Math.round(Math.random()*1000),
      callback)

vows
  .describe('Processing purchases')
  .addBatch
    'When a successful purchase is created':
      topic: ->
        createTestPurchase 1.0, this.callback
        return

      'the processor response should be successful': (err, transaction) ->
        assert.equal transaction.isSuccess(), true

      'we should be able to read the AVS result code ': (err, transaction) ->
        assert.equal transaction.avsResultCode, 'Y'

      'we should be able to read the CVV result code ': (err, transaction) ->
        assert.isNotNull transaction.cvvResultCode

    'When a recent transaction is voided':
      topic: ->
        createTestPurchase 1.0, (err, transaction) =>
          transaction.void(this.callback)
        return

      'the processor response should be successful': (err, transaction) ->
        assert.equal transaction.isSuccess(), true

    'When a recent transaction is credited':
      topic: ->
        createTestPurchase 1.0, (err, transaction) =>
          transaction.credit(this.callback)
        return

      'the processor response should be successful': (err, transaction) ->
        assert.equal transaction.isSuccess(), true

    'When a recent transaction is reversed':
      topic: ->
        createTestPurchase 1.0, (err, transaction) =>
          transaction.reverse(this.callback)
        return

      'the processor response should be successful': (err, transaction) ->
        assert.equal transaction.isSuccess(), true

    'When a purchase that should be declined is created':
      topic: ->
        createTestPurchase 1.02, this.callback
        return

      'the processor response should not be successful': (err, transaction) ->
        assert.equal transaction.isSuccess(), false
        assert.equal transaction.errors['processor.transaction'][0].description(), 'The card was declined.'

  .export(module)

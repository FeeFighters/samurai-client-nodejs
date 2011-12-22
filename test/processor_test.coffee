vows                       = require 'vows'
assert                     = require 'assert'
{PaymentMethod, Processor, Transaction, Connection, createTestPaymentMethod} = require './support/test_helper'

vows
  .describe('Processor actions')
  .addBatch
    'when we call the theProcessor class method':
      topic: Processor.theProcessor()

      'it should return the default processor': (processor) ->
        assert.isNotNull processor
        assert.equal processor.processorToken, Connection.config.processor_token

      'and we create a new purchase with tracking data':
        topic: (processor) ->
          createTestPaymentMethod (token) =>
            processor.purchase(token,
              1.0,
              {
                description: 'A test purchase',
                custom: 'optional custom data',
                billing_reference: 'ABC123',
                customer_reference: 'Customer (123)'
              },
              this.callback
            )
          return

        'the processor response should be successful': (err, transaction) ->
          assert.equal transaction.isSuccess(), true

        'and then authorize with the same payment method token and amount':
          topic: (transaction, processor) ->
            processor.authorize(transaction.attributes.payment_method.payment_method_token, 1.0, null, this.callback)
            return

          'the authorization should be non-new': (err, transaction) ->
            assert.equal transaction.isSuccess(), true

  .export(module)

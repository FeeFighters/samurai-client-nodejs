vows    = require 'vows'
assert  = require 'assert'
Message = require '../lib/message'

descriptionShouldBe = (description) ->
  return (message) ->
    assert.equal message.description(), description

vows
  .describe('Messages')
  .addBatch
    'Processor context -':
      'transaction/success':
        topic: new Message('info', 'processor.transaction', 'success')
        'should display processor_transaction_success': descriptionShouldBe('The transaction was successful.')

      'transaction/declined':
        topic: new Message('error', 'processor.transaction', 'declined')
        'should display processor_transaction_declined': descriptionShouldBe('The card was declined.')

      'issuer/call':
        topic: new Message('error', 'processor.issuer', 'call')
        'should display processor_issuer_call': descriptionShouldBe('Call the card issuer for further instructions.')

      'issuer/unavailable':
        topic: new Message('error', 'processor.issuer', 'unavailable')
        'should display processor_issuer_unavailable': descriptionShouldBe('The authorization did not respond within the alloted time.')

      'transaction/declined_insufficient_funds':
        topic: new Message('error', 'processor.transaction', 'declined_insufficient_funds')
        'should display processor_transaction_declined_insufficient_funds': descriptionShouldBe('The transaction was declined due to insufficient funds.')

    'Input context -':
      'card_number/invalid':
        topic: new Message('error', 'input.card_number', 'invalid')
        'should display input_card_number_invalid': descriptionShouldBe('The card number was invalid.')

      'expiry_month/invalid':
        topic: new Message('error', 'input.expiry_month', 'invalid')
        'should display input_expiry_month_invalid': descriptionShouldBe('The expiration date month was invalid, or prior to today.')

      'expiry_year/invalid':
        topic: new Message('error', 'input.expiry_year', 'invalid')
        'should display input_expiry_year_invalid': descriptionShouldBe('The expiration date year was invalid, or prior to today.')

      'amount/invalid':
        topic: new Message('error', 'input.amount', 'invalid')
        'should display input_amount_invalid': descriptionShouldBe('The transaction amount was invalid.')

  .export(module)

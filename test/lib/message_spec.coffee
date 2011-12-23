require '../spec_helper'
should = require 'should'
Message = require '../../lib/message'

describe 'message responses', ->

  it 'should display processor_transaction_success', ->
    message = new Message('info', 'processor.transaction', 'success')
    message.description().should.equal 'The transaction was successful.'

  it 'should display processor_transaction_declined', ->
    message = new Message('error', 'processor.transaction', 'declined')
    message.description().should.equal 'The card was declined.'
    
  it 'should display processor_issuer_call', ->
    message = new Message('error', 'processor.issuer', 'call')
    message.description().should.equal 'Call the card issuer for further instructions.'

  it 'should display processor_issuer_unavailable', ->
    message = new Message('error', 'processor.issuer', 'unavailable')
    message.description().should.equal 'The authorization did not respond within the alloted time.'
    
  it 'should display input_card_number_invalid', ->
    message = new Message('error', 'input.card_number', 'invalid')
    message.description().should.equal 'The card number was invalid.'

  it 'should display input_expiry_month_invalid', ->
    message = new Message('error', 'input.expiry_month', 'invalid')
    message.description().should.equal 'The expiration date month was invalid, or prior to today.'

  it 'should display input_expiry_year_invalid', ->
    message = new Message('error', 'input.expiry_year', 'invalid')
    message.description().should.equal 'The expiration date year was invalid, or prior to today.'

  it 'should display input_amount_invalid', ->
    message = new Message('error', 'input.amount', 'invalid')
    message.description().should.equal 'The transaction amount was invalid.'

  it 'should display processor_transaction_declined_insufficient_funds', ->
    message = new Message('error', 'processor.transaction', 'declined_insufficient_funds')
    message.description().should.equal 'The transaction was declined due to insufficient funds.'
  

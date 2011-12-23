{PaymentMethod, Processor, Transaction, Connection, createTestPaymentMethod} = require '../spec_helper'
should = require 'should'
util = require 'util'

describe "Transaction", ->
  rand = 1
  paymentMethodToken = false

  before (done) ->
    rand = Math.floor(Math.random()*1000)
    createTestPaymentMethod (token) ->
      paymentMethodToken = token
      done()

  describe 'capture', ->
    describe 'success', ->
      auth = false

      before (done) ->
        Processor.authorize paymentMethodToken, 100.0, (err, a) ->
          auth = a
          done()

      it 'should be successful', (done) ->
        auth.capture (err, capture) ->
          capture.success.should.be.true
          done()

      it 'should be successful for full amount', (done) ->
        auth.capture 100.0, (err, capture) ->
          capture.success.should.be.true
          done()

      it 'should be successful for partial amount', (done) ->
        auth.capture 50.0, (err, capture) ->
          capture.success.should.be.true
          done()

    describe 'failures', ->
      it 'should return processor.transaction - invalid with declined auth', (done) ->
        Processor.authorize paymentMethodToken, 100.02, (err, auth) ->
          auth.capture (err, capture) ->
            capture.success.should.be.false
            capture.errors['processor.transaction'][0].description().should.equal 'This transaction type is not allowed.'
            done()
        
      it 'should return processor.transaction - declined', (done) ->
        Processor.authorize paymentMethodToken, 100.00, (err, auth) ->
          auth.capture 100.02, (err, capture) ->
            capture.success.should.be.false
            capture.errors['processor.transaction'][0].description().should.equal 'The card was declined.'
            done()

      it 'should return input.amount - invalid', (done) ->
        Processor.authorize paymentMethodToken, 100.00, (err, auth) ->
          auth.capture 100.10, (err, capture) ->
            capture.success.should.be.false
            capture.errors['input.amount'][0].description().should.equal 'The transaction amount was invalid.'
            done()

  describe 'reverse', ->
    describe 'on capture', ->
      purchase = false

      before (done) ->
        Processor.purchase paymentMethodToken, 100.0, (err, p) ->
          purchase = p
          done()

      it 'should be successful', (done) ->
        purchase.reverse (err, reverse) ->
          reverse.success.should.be.true
          done()

      it 'should be successful for full amount', (done) ->
        purchase.reverse 100.0, (err, reverse) ->
          reverse.success.should.be.true
          done()

      it 'should be successful for partial amount', (done) ->
        purchase.reverse 50.0, (err, reverse) ->
          reverse.success.should.be.true
          done()

    describe 'on authorize', ->
      authorize = false

      before (done) ->
        Processor.authorize paymentMethodToken, 100.0, (err, a) ->
          authorize = a
          done()

      it 'should be successful', (done) ->
        authorize.reverse (err, reverse) ->
          reverse.success.should.be.true
          done()

    describe 'failures', ->
      it 'should return input.amount - invalid', (done) ->
        Processor.purchase paymentMethodToken, 100.00, (err, purchase) ->
          purchase.reverse 100.10, (err, reverse) ->
            reverse.success.should.be.false
            reverse.errors['input.amount'][0].description().should.equal 'The transaction amount was invalid.'
            done()

  describe 'credit', ->
    describe 'on capture', ->
      purchase = false

      before (done) ->
        Processor.purchase paymentMethodToken, 100.0, (err, p) ->
          purchase = p
          done()

      it 'should be successful', (done) ->
        purchase.credit (err, credit) ->
          credit.success.should.be.true
          done()

      it 'should be successful for full amount', (done) ->
        purchase.credit 100.0, (err, credit) ->
          credit.success.should.be.true
          done()
        
      it 'should be successful for partial amount', (done) ->
        purchase.credit 50.0, (err, credit) ->
          credit.success.should.be.true
          done()

    describe 'on authorize', ->
      authorize = false

      before (done) ->
        Processor.authorize paymentMethodToken, 100.0, (err, a) ->
          authorize = a
          done()

      it 'should be successful', (done) ->
        authorize.credit (err, credit) ->
          credit.success.should.be.true
          done()

    describe 'failures', ->
      it 'should return input.amount - invalid', (done) ->
        Processor.purchase paymentMethodToken, 100.00, (err, purchase) ->
          purchase.credit 100.10, (err, credit) ->
            credit.success.should.be.false
            credit.errors['input.amount'][0].description().should.equal 'The transaction amount was invalid.'
            done()

  describe 'void', ->
    describe 'on authorized', ->
      authorize = false

      before (done) ->
        Processor.authorize paymentMethodToken, 100.0, (err, a) ->
          authorize = a
          done()

      it 'should be successful', (done) ->
        authorize.void (err, voidTransaction) ->
          voidTransaction.success.should.be.true
          done()

    describe 'on captured', ->
      purchase = false

      before (done) ->
        Processor.purchase paymentMethodToken, 100.0, (err, p) ->
          purchase = p
          done()

      it 'should be successful', ->
        purchase.void (err, voidTransaction) ->
          voidTransaction.success.should.be.true
          done()


{PaymentMethod, Processor, Transaction, Connection, createTestPaymentMethod} = require '../spec_helper'
should = require 'should'
util = require 'util'

describe 'Processor', ->
  rand = 1
  paymentMethodToken = false

  beforeEach (done) ->
    rand = Math.floor(Math.random()*1000)
    createTestPaymentMethod (token) ->
      paymentMethodToken = token
      done()

  describe 'the_processor', ->
    it "should return the default processor", ->
      processor = Processor.theProcessor()
      should.exist(processor)
      processor.token.should.equal Connection.config.processor_token

  describe 'new processor', ->
    it "should return a processor", ->
      processor = new Processor('abc123')
      should.exist(processor)
      processor.token.should.equal 'abc123'

  describe 'purchase', ->
    it 'should be successful', (done) ->
      Processor.purchase(paymentMethodToken, 100.0,
        {
          description: "description",
          descriptor_name: "descriptor_name",
          descriptor_phone: "descriptor_phone",
          custom: "custom_data",
          billing_reference: "ABC123#{rand}",
          customer_reference: "Customer (123)",
        },
        (err, purchase) ->
          purchase.success.should.be.true
          purchase.description.should.equal 'description'
          purchase.descriptorName.should.equal 'descriptor_name'
          purchase.descriptorPhone.should.equal 'descriptor_phone'
          purchase.custom.should.equal 'custom_data'
          purchase.billingReference.should.equal "ABC123#{rand}"
          purchase.customerReference.should.equal "Customer (123)"
          done()
      )

    describe 'failures', ->
      it 'should return processor.transaction - declined', (done) ->
        Processor.purchase paymentMethodToken, 1.02, billing_reference: rand, (err, purchase) ->
          purchase.success.should.be.false
          purchase.errors['processor.transaction'][0].description().should.equal 'The card was declined.'
          done()

      it 'should return input.amount - invalid', (done) ->
        Processor.purchase paymentMethodToken, 1.10, billing_reference: rand, (err, purchase) ->
          purchase.success.should.be.false
          purchase.errors['input.amount'][0].description().should.equal 'The transaction amount was invalid.'
          done()

    describe 'cvv responses', ->
      it 'should return processor.cvv_result_code = M', (done) ->
        overrides = 'credit_card[cvv]': '111'
        createTestPaymentMethod(
          (token) ->
            Processor.purchase token, 1.00, billing_reference: rand, (err, purchase) ->
              purchase.success.should.be.true
              purchase.processorResponse.cvv_result_code.should.equal 'M'
              done()
          overrides)

      it 'should return processor.cvv_result_code = N', (done) ->
        overrides = 'credit_card[cvv]': '222'
        createTestPaymentMethod(
          (token) ->
            Processor.purchase token, 1.00, billing_reference: rand, (err, purchase) ->
              purchase.success.should.be.true
              purchase.processorResponse.cvv_result_code.should.equal 'N'
              done()
          overrides)

    describe 'avs responses', ->
      it 'should return processor.avs_result_code = Y', (done) ->
        overrides =
          'credit_card[address_1]':  '1000 1st Av',
          'credit_card[address_2]':  '',
          'credit_card[zip]':        '10101'

        createTestPaymentMethod(
          (token) ->
            Processor.purchase token, 1.00, billing_reference: rand, (err, purchase) ->
              purchase.success.should.be.true
              purchase.processorResponse.avs_result_code.should.equal 'Y'
              done()
          overrides)

      it 'should return processor.avs_result_code = Z', (done) ->
        overrides =
          'credit_card[address_1]': '',
          'credit_card[address_2]': '',
          'credit_card[zip]':       '10101'

        createTestPaymentMethod(
          (token) ->
            Processor.purchase token, 1.00, billing_reference: rand, (err, purchase) ->
              purchase.success.should.be.true
              purchase.processorResponse.avs_result_code.should.equal 'Z'
              done()
          overrides)

      it 'should return processor.avs_result_code = N', (done) ->
        overrides =
          'credit_card[address_1]': '123 Main St',
          'credit_card[address_2]': '',
          'credit_card[zip]':       '60610'

        createTestPaymentMethod(
          (token) ->
            Processor.purchase token, 1.00, billing_reference: rand, (err, purchase) ->
              purchase.success.should.be.true
              purchase.processorResponse.avs_result_code.should.equal 'N'
              done()
          overrides)

  describe 'authorize', ->
    it 'should be successful', (done) ->
      Processor.authorize(paymentMethodToken, 100.0,
        {
          description: "description",
          descriptor_name: "descriptor_name",
          descriptor_phone: "descriptor_phone",
          custom: "custom_data",
          billing_reference: "ABC123#{rand}",
          customer_reference: "Customer (123)",
        },
        (err, purchase) ->
          purchase.success.should.be.true
          purchase.description.should.equal 'description'
          purchase.descriptorName.should.equal 'descriptor_name'
          purchase.descriptorPhone.should.equal 'descriptor_phone'
          purchase.custom.should.equal 'custom_data'
          purchase.billingReference.should.equal "ABC123#{rand}"
          purchase.customerReference.should.equal "Customer (123)"
          done()
      )

    describe 'failures', ->
      it 'should return processor.transaction - declined', (done) ->
        Processor.authorize paymentMethodToken, 1.02, billing_reference: rand, (err, authorize) ->
          authorize.success.should.be.false
          authorize.errors['processor.transaction'][0].description().should.equal 'The card was declined.'
          done()

      it 'should return input.amount - invalid', (done) ->
        Processor.authorize paymentMethodToken, 1.10, billing_reference: rand, (err, authorize) ->
          authorize.success.should.be.false
          authorize.errors['input.amount'][0].description().should.equal 'The transaction amount was invalid.'
          done()

    describe 'cvv responses', ->
      it 'should return processor.cvv_result_code = M', (done) ->
        overrides = 'credit_card[cvv]': '111'

        createTestPaymentMethod(
          (token) ->
            Processor.authorize token, 1.00, billing_reference: rand, (err, purchase) ->
              purchase.success.should.be.true
              purchase.processorResponse.cvv_result_code.should.equal 'M'
              done()
          overrides)

      it 'should return processor.cvv_result_code = N', (done) ->
        overrides = 'credit_card[cvv]': '222'

        createTestPaymentMethod(
          (token) ->
            Processor.authorize token, 1.00, billing_reference: rand, (err, purchase) ->
              purchase.success.should.be.true
              purchase.processorResponse.cvv_result_code.should.equal 'N'
              done()
          overrides)

    describe 'avs responses', ->
      it 'should return processor.avs_result_code = Y', (done) ->
        overrides =
          'credit_card[address_1]': '1000 1st Av',
          'credit_card[address_2]': '',
          'credit_card[zip]':       '10101'

        createTestPaymentMethod(
          (token) ->
            Processor.authorize token, 1.00, billing_reference: rand, (err, purchase) ->
              purchase.success.should.be.true
              purchase.processorResponse.avs_result_code.should.equal 'Y'
              done()
          overrides)

      it 'should return processor.avs_result_code = Z', (done) ->
        overrides =
          'credit_card[address_1]': '',
          'credit_card[address_2]': '',
          'credit_card[zip]':       '10101'

        createTestPaymentMethod(
          (token) ->
            Processor.authorize token, 1.00, billing_reference: rand, (err, purchase) ->
              purchase.success.should.be.true
              purchase.processorResponse.avs_result_code.should.equal 'Z'
              done()
          overrides)

      it 'should return processor.avs_result_code = N', (done) ->
        overrides =
          'credit_card[address_1]':  '123 Main St',
          'credit_card[address_2]':  '',
          'credit_card[zip]':        '60610'

        createTestPaymentMethod(
          (token) ->
            Processor.authorize token, 1.00, billing_reference: rand, (err, purchase) ->
              purchase.success.should.be.true
              purchase.processorResponse.avs_result_code.should.equal 'N'
              done()
          overrides)

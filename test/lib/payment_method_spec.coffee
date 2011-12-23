{PaymentMethod, createTestPaymentMethod} = require '../spec_helper'
{merge} = require '../../lib/helpers'
should = require 'should'
util = require 'util'

describe 'PaymentMethod', ->
  params = {}

  before ->
    params =
      first_name:    'FirstName',
      last_name:     'LastName',
      address_1:     '123 Main St.',
      address_2:     'Apt #3',
      city:          'Chicago',
      state:         'IL',
      zip:           '10101',
      card_number:   '4111-1111-1111-1111',
      cvv:           '123',
      expiry_month:  '03',
      expiry_year:   '2015'

  describe 'S2S #create', ->
    it 'should be successful', (done) ->
      pm = PaymentMethod.create params, ->
        PaymentMethod.find pm.token, (err, pm) ->
          pm.isSensitiveDataValid.should.be.true
          pm.isExpirationValid.should.be.true
          pm.firstName.should.equal      params.first_name
          pm.lastName.should.equal       params.last_name
          pm.address1.should.equal       params.address_1
          pm.address2.should.equal       params.address_2
          pm.city.should.equal           params.city
          pm.state.should.equal          params.state
          pm.zip.should.equal            params.zip
          pm.lastFourDigits.should.equal params.card_number.substr(-4)
          pm.expiryMonth.should.equal    parseInt(params.expiry_month, 10)
          pm.expiryYear.should.equal     parseInt(params.expiry_year, 10)
          done()
    
    describe 'fail on input.card_number', ->
      it 'should return is_blank', (done) ->
        pm = PaymentMethod.create merge(params, card_number: ''), (err, pm) ->
          pm.isSensitiveDataValid.should.be.false
          pm.errors['input.card_number'][0].description().should.equal 'The card number was blank.'
          done()
      
      it 'should return too_short', (done) ->
        pm = PaymentMethod.create merge(params, card_number: '4111-1'), (err, pm) ->
          pm.isSensitiveDataValid.should.be.false
          pm.errors['input.card_number'][0].description().should.equal 'The card number was too short.'
          done()
      
      it 'should return too_long', (done) ->
        pm = PaymentMethod.create merge(params, card_number: '4111-1111-1111-1111-11'), ->
          pm.isSensitiveDataValid.should.be.false
          pm.errors['input.card_number'][0].description().should.equal 'The card number was too long.'
          done()
      
      it 'should return failed_checksum', (done) ->
        pm = PaymentMethod.create merge(params, card_number: '4111-1111-1111-1234'), ->
          pm.isSensitiveDataValid.should.be.false
          pm.errors['input.card_number'][0].description().should.equal 'The card number was invalid.'
          done()
      
    describe 'fail on input.cvv', ->
      it 'should return too_short', (done) ->
        pm = PaymentMethod.create merge(params, cvv: '1'), (err, pm) ->
          pm.isSensitiveDataValid.should.be.false
          pm.errors['input.cvv'][0].description().should.equal 'The CVV was too short.'
          done()
      
      it 'should return too_long', (done) ->
        pm = PaymentMethod.create merge(params, cvv: '111111'), (err, pm) ->
          pm.isSensitiveDataValid.should.be.false
          pm.errors['input.cvv'][0].description().should.equal 'The CVV was too long.'
          done()
      
      it 'should return not_numeric', (done) ->
        pm = PaymentMethod.create merge(params, cvv: 'abcd1'), (err, pm) ->
          pm.isSensitiveDataValid.should.be.false
          pm.errors['input.cvv'][0].description().should.equal 'The CVV was invalid.'
          done()
    
    describe 'fail on input.expiry_month', ->
      it 'should return is_blank', (done) ->
        pm = PaymentMethod.create merge(params, expiry_month: ''), (err, pm) ->
          pm.isSensitiveDataValid.should.be.true
          pm.isExpirationValid.should.be.false
          pm.errors['input.expiry_month'][0].description().should.equal 'The expiration month was blank.'
          done()
      
      it 'should return is_invalid', (done) ->
        pm = PaymentMethod.create merge(params, expiry_month: 'abcd'), (err, pm) ->
          pm.isSensitiveDataValid.should.be.true
          pm.isExpirationValid.should.be.false
          pm.errors['input.expiry_month'][0].description().should.equal 'The expiration month was invalid.'
          done()
    
    describe 'fail on input.expiry_year', ->
      it 'should return is_blank', (done) ->
        pm = PaymentMethod.create merge(params, expiry_year: ''), (err, pm) ->
          pm.isSensitiveDataValid.should.be.true
          pm.isExpirationValid.should.be.false
          pm.errors['input.expiry_year'][0].description().should.equal 'The expiration year was blank.'
          done()
      
      it 'should return is_invalid', (done) ->
        pm = PaymentMethod.create merge(params, expiry_year: 'abcd'), (err, pm) ->
          pm.isSensitiveDataValid.should.be.true
          pm.isExpirationValid.should.be.false
          pm.errors['input.expiry_year'][0].description().should.equal 'The expiration year was invalid.'
          done()
      
  describe 'S2S #update', ->
    params = {}
    pm = false

    before (done) ->
      params =
        first_name:    "FirstNameX",
        last_name:     "LastNameX",
        address_1:     "123 Main St.X",
        address_2:     "Apt #3X",
        city:          "ChicagoX",
        state:         "IL",
        zip:           "10101",
        card_number:   "5454-5454-5454-5454",
        cvv:           "456",
        expiry_month:  '05',
        expiry_year:   "2016"

      createTestPaymentMethod (token) ->
        PaymentMethod.find token, (err, paymentMethod) ->
          pm = paymentMethod
          done()
    
    it 'should be successful', (done) ->
      pm.updateAttributes params
      pm.save ->
        PaymentMethod.find pm.token, (err, pm) ->
          pm.isSensitiveDataValid.should.be.true
          pm.isExpirationValid.should.be.true
          pm.firstName.should.equal      params.first_name
          pm.lastName.should.equal       params.last_name
          pm.address1.should.equal       params.address_1
          pm.address2.should.equal       params.address_2
          pm.city.should.equal           params.city
          pm.state.should.equal          params.state
          pm.zip.should.equal            params.zip
          pm.lastFourDigits.should.equal params.card_number.substr(-4)
          pm.expiryMonth.should.equal    parseInt(params.expiry_month, 10)
          pm.expiryYear.should.equal     parseInt(params.expiry_year, 10)
          done()
      
    
    it 'should be successful preserving sensitive data', (done) ->
      _params = merge(params, {
        card_number: '****************',
        cvv: '***'
      })

      pm.updateAttributes _params
      pm.save ->
        PaymentMethod.find pm.token, (err, pm) ->
          pm.isSensitiveDataValid.should.be.true
          pm.isExpirationValid.should.be.true
          pm.firstName.should.equal       params.first_name
          pm.lastName.should.equal        params.last_name
          pm.address1.should.equal        params.address_1
          pm.address2.should.equal        params.address_2
          pm.city.should.equal            params.city
          pm.state.should.equal           params.state
          pm.zip.should.equal             params.zip
          pm.lastFourDigits.should.equal  params.card_number.substr(-4)
          pm.expiryMonth.should.equal     parseInt(params.expiry_month, 10)
          pm.expiryYear.should.equal      parseInt(params.expiry_year, 10)
          done()
      
    describe 'fail on input.card_number', ->
      it 'should return too_short', (done) ->
        pm.updateAttributes merge(params, card_number: '4111-1')
        pm.save ->
          pm.isSensitiveDataValid.should.be.false
          pm.errors['input.card_number'][0].description().should.equal 'The card number was too short.'
          done()
      
      it 'should return too_long', (done) ->
        pm.updateAttributes merge(params, card_number: '4111-1111-1111-1111-11')
        pm.save ->
          pm.isSensitiveDataValid.should.be.false
          pm.errors['input.card_number'][0].description().should.equal 'The card number was too long.'
          done()
      
      it 'should return failed_checksum', (done) ->
        pm.updateAttributes merge(params, card_number: '4111-1111-1111-1234')
        pm.save ->
          pm.isSensitiveDataValid.should.be.false
          pm.errors['input.card_number'][0].description().should.equal 'The card number was invalid.'
          done()
    
    describe 'fail on input.cvv', ->
      it 'should return too_short', (done) ->
        pm.updateAttributes merge(params, cvv: '1')
        pm.save ->
          pm.isSensitiveDataValid.should.be.false
          pm.errors['input.cvv'][0].description().should.equal 'The CVV was too short.'
          done()
      
      it 'should return too_long', (done) ->
        pm.updateAttributes merge(params, cvv: '111111')
        pm.save ->
          pm.isSensitiveDataValid.should.be.false
          pm.errors['input.cvv'][0].description().should.equal 'The CVV was too long.'
          done()
    
    describe 'fail on input.expiry_month', ->
      it 'should return is_blank', (done) ->
        pm.updateAttributes merge(params, expiry_month: '')
        pm.save ->
          pm.isSensitiveDataValid.should.be.true
          pm.isExpirationValid.should.be.false
          pm.errors['input.expiry_month'][0].description().should.equal 'The expiration month was blank.'
          done()
      
      it 'should return is_invalid', (done) ->
        pm.updateAttributes merge(params, expiry_month: 'abcd')
        pm.save ->
          pm.isSensitiveDataValid.should.be.true
          pm.isExpirationValid.should.be.false
          pm.errors['input.expiry_month'][0].description().should.equal 'The expiration month was invalid.'
          done()
    
    describe 'fail on input.expiry_year', ->
      it 'should return is_blank', (done) ->
        pm.updateAttributes merge(params, expiry_year: '')
        pm.save ->
          pm.isSensitiveDataValid.should.be.true
          pm.isExpirationValid.should.be.false
          pm.errors['input.expiry_year'][0].description().should.equal 'The expiration year was blank.'
          done()
      
      it 'should return is_invalid', (done) ->
        pm.updateAttributes merge(params, expiry_year: 'abcd')
        pm.save ->
          pm.isSensitiveDataValid.should.be.true
          pm.isExpirationValid.should.be.false
          pm.errors['input.expiry_year'][0].description().should.equal 'The expiration year was invalid.'
          done()

  describe '#find', ->
    token = false

    before (done) ->
      PaymentMethod.create params, (err, pm) ->
        token = pm.token
        done()
    
    it 'should be successful', (done) ->
      PaymentMethod.find token, (err, pm) ->
        pm.isSensitiveDataValid.should.be.true
        pm.isExpirationValid.should.be.true
        pm.firstName.should.equal      params.first_name
        pm.lastName.should.equal       params.last_name
        pm.address1.should.equal       params.address_1
        pm.address2.should.equal       params.address_2
        pm.city.should.equal           params.city
        pm.state.should.equal          params.state
        pm.zip.should.equal            params.zip
        pm.lastFourDigits.should.equal params.card_number.substr(-4)
        pm.expiryMonth.should.equal    parseInt(params.expiry_month, 10)
        pm.expiryYear.should.equal     parseInt(params.expiry_year, 10)
        done()
    
    it 'should fail on an invalid token', (done) ->
      PaymentMethod.find 'abc123', (err, pm) ->
        pm.errors['system.general'][0].description().should.equal "Couldn't find PaymentMethod with token = abc123"
        done()
    

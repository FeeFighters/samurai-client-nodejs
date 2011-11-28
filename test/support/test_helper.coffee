https = require 'https'
querystring = require 'querystring'
samurai = require('../..')

samurai.setup
  sandbox:           true
  site:              process.env['SITE']              || 'https://api.samurai.feefighters.com/v1/',
  merchant_key:      process.env['MERCHANT_KEY']      || 'a1ebafb6da5238fb8a3ac9f6',
  merchant_password: process.env['MERCHANT_PASSWORD'] || 'ae1aa640f6b735c4730fbb56',
  processor_token:   process.env['PROCESSOR_TOKEN']   || '5a0e1ca1e5a11a2997bbf912'

module.exports = samurai
module.exports.createTestPaymentMethod = (callback) ->
  options =
    host: 'api.samurai.feefighters.com',
    port: 443,
    path: '/v1/payment_methods',
    method: 'POST',
    headers:
      'Accept':        'application/json',
      'Content-Type':  'application/x-www-form-urlencoded',

  data = querystring.stringify
    'redirect_url':               'http://yourdomain.com/anywhere',
    'merchant_key':               samurai.Connection.config.merchant_key,
    'sandbox':                    true,
    'custom':                     'custom',
    'credit_card[first_name]':    'John',
    'credit_card[last_name]':     'Smith',
    'credit_card[address_1]':     '1000 1st Av',
    'credit_card[address_2]':     '',
    'credit_card[city]':          'Chicago',
    'credit_card[state]':         'IL',
    'credit_card[zip]':           '10101',
    'credit_card[card_number]':   '4111111111111111',
    'credit_card[cvv]':           '111',
    'credit_card[expiry_month]':  '05',
    'credit_card[expiry_year]':   '2014'

  req = https.request(
    options,
    (res) ->
      token = res.headers['location'].match(/payment_method_token=(.*)/)[1]
      callback?(token)
  )
  req.write(data)
  req.end()

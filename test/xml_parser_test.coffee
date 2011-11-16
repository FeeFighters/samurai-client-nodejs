vows = require 'vows'
assert = require 'assert'
xml = require '../lib/xml_parser'

sampleSamuraiXML = """
<payment_method>
  <payment_method_token>2a492618486f55b73d06ed8b</payment_method_token>
  <created_at type="datetime">2011-11-06 15:05:43 UTC</created_at>
  <updated_at type="datetime">2011-11-06 15:05:43 UTC</updated_at>
  <custom></custom>
  <is_retained type="boolean">true</is_retained>
  <is_redacted type="boolean">false</is_redacted>
  <is_sensitive_data_valid type="boolean">true</is_sensitive_data_valid>
  <is_expiration_valid type="boolean">true</is_expiration_valid>
  <processor_response>
    <success type="boolean">false</success>
    <messages type="array">
      <message class="error" context="processor.avs" key="country_not_supported" />
      <message class="error" context="input.cvv" key="too_short" />
    </messages>
  </processor_response>
  <messages type="array"></messages>
  <last_four_digits>1111</last_four_digits>
  <card_type></card_type>
  <first_name>sean</first_name>
  <last_name>harper</last_name>
  <expiry_month type="integer">3</expiry_month>
  <expiry_year type="integer">2015</expiry_year>
  <address_1>1240 W Monroe #1</address_1>
  <address_2></address_2>
  <city>Chicago</city>
  <state>IL</state>
  <zip>53211</zip>
  <country></country>
</payment_method>"""

sampleSamuraiJSON =
  payment_method:
    payment_method_token: '2a492618486f55b73d06ed8b',
    created_at: '2011-11-06T15:05:43.000Z',
    updated_at: '2011-11-06T15:05:43.000Z',
    custom: '',
    is_retained: true,
    is_redacted: false,
    is_sensitive_data_valid: true,
    is_expiration_valid: true,
    processor_response:
      success: false,
      messages: [
        { 'class': 'error', context: 'processor.avs', key: 'country_not_supported' },
        { 'class': 'error', context: 'input.cvv', key: 'too_short' }
      ],
    messages: [],
    last_four_digits: '1111',
    card_type: '',
    first_name: 'sean',
    last_name: 'harper',
    expiry_month: 3,
    expiry_year: 2015,
    address_1: '1240 W Monroe #1',
    address_2: '',
    city: 'Chicago',
    state: 'IL',
    zip: '53211',
    country: ''
  
vows
  .describe('XmlParser')
  .addBatch
    'when parsing a sample samurai XML response':
      topic: ->
        JSON.stringify xml.parse(sampleSamuraiXML)

      'the result will be equivalent to the same JSON response': (topic) ->
        assert.equal topic, JSON.stringify(sampleSamuraiJSON)
  .export(module)

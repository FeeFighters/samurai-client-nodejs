# The `Message` class represents a single <message>, returned in a
# Samurai response. Messages typically have a `subclass`, `context` and `key`
# and optionally provide the text of the message.
module.exports = class Message
  DEFAULT_RESPONSE_MAPPINGS =
    # Transaction Responses
    { 'info processor.transaction success'      : 'The transaction was successful.'
    , 'error processor.transaction declined'    : 'The card was declined.'
    , 'error processor.issuer call'             : 'Call the card issuer for further instructions.'
    , 'error processor.issuer unavailable'      : 'The authorization did not respond within the alloted time.'
    , 'error input.card_number invalid'         : 'The card number was invalid.'
    , 'error input.expiry_month invalid'        : 'The expiration date month was invalid, or prior to today.'
    , 'error input.expiry_year invalid'         : 'The expiration date year was invalid, or prior to today.'
    , 'error processor.pin invalid'             : 'The PIN number is incorrect.'
    , 'error input.amount invalid'              : 'The transaction amount was invalid.'
    , 'error processor.transaction declined_insufficient_funds' : 'The transaction was declined due to insufficient funds.'
    , 'error processor.network_gateway merchant_invalid'        : 'The Merchant Number is incorrect.'
    , 'error input.merchant_login invalid'      : 'The merchant ID is not valid or active.'
    , 'error input.store_number invalid'        : 'Invalid Store Number.'
    , 'error processor.bank_info invalid'       : 'Invalid banking information.'
    , 'error processor.transaction not_allowed' : 'Merchant can not accept this card.'
    , 'error processor.transaction type_invalid'    : 'Requested transaction type is not allowed for this card/merchant.'
    , 'error processor.transaction method_invalid'  : 'The requested transaction could not be performed for this merchant.'
    , 'error input.amount exceeds_limit'            : 'The maximum transaction amount was exceeded.'
    , 'error input.cvv invalid'                     : 'The CVV data entered is not correct.'
    , 'error processor.network_gateway communication_error'     : 'There was a fatal communication error.'
    , 'error processor.network_gateway unresponsive'            : 'The processing network is temporarily unavailable.'
    , 'error processor.network_gateway merchant_invalid'        : 'The merchant number is not on file.'

    # AVS Responses
    , 'info processor.avs_result_code 0'  : 'No response.'
    , 'info processor.avs_result_code Y'  : 'The address and 5-digit ZIP match.'
    , 'info processor.avs_result_code Z'  : 'The 5-digit ZIP matches, the address does not.'
    , 'info processor.avs_result_code X'  : 'The address and 9-digit ZIP match.'
    , 'info processor.avs_result_code A'  : 'The address matches, the ZIP does not.'
    , 'info processor.avs_result_code E'  : 'There was an AVS error, or the data was illegible.'
    , 'info processor.avs_result_code R'  : 'The AVS request timed out.'
    , 'info processor.avs_result_code S'  : 'The issuer does not support AVS.'
    , 'info processor.avs_result_code F'  : 'The street addresses and postal codes match.'
    , 'info processor.avs_result_code N'  : 'The address and ZIP do not match.'

    # CVV Responses
    , 'error input.cvv declined' : 'The CVV code was not correct.'
    , 'error input.cvv declined' : 'The CVV code was invalid.'
    }

  constructor: (@subclass, @context, @key, @text) ->
    @text ?= ''

  # Tries to return the description for the context/key combo of the
  # current message. If an appropriate mapping can't be found, return
  # the `text` attribute (which could be blank).
  description: ->
    key = [@subclass, @context, @key].join(' ')
    DEFAULT_RESPONSE_MAPPINGS[key] or @text

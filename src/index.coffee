Connection     = require './connection'
PaymentMethod  = require './payment_method'
Transaction    = require './transaction'
Processor      = require './processor'
Message        = require './message'
Views          = require './views'

# Exposes all main classes and the `setup` function.
module.exports =
  Connection:         Connection
  PaymentMethod:      PaymentMethod
  Transaction:        Transaction
  Processor:          Processor
  Message:            Message
  setup:              Connection.setup
  renderErrors:       Views.renderErrors
  renderPaymentForm:  Views.renderPaymentForm

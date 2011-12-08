eco      = require 'eco'
fs       = require 'fs'
{config} = require './connection'
{extend} = require './helpers'

VIEW_PATH = __dirname + '/../views'

Views = do ->
  render = (view, vars = {}) ->
    extend vars, config: config
    template = fs.readFileSync VIEW_PATH + view + '.eco', 'utf-8'
    eco.render template, vars

	# Checks a payment method or transaction object for errors and 
	# generates an HTML list with the descriptions of those errors.
	#
	# Parameters:
	# 
  # The `vars` object gets passed as context to the template when 
  # it is rendered. To make sure you get the expected output, pass 
  # the following parameters as properties:
	#
	# - `paymentMethod`: An instance of PaymentMethod that could 
	#		contain errors. (optional)
	# - `transaction`: An instance of Transaction that could 
	#		contain errors. (optional)
	#
  renderErrors = (vars = {}) ->
    render '/application/_errors', vars

	# Renders a standard Samurai payment form, similar to the one you'd 
	# get with Samurai.js.
	#
	# Parameters:
	#
  # The `vars` object gets passed as context to the template when 
  # it is rendered. To make sure you get the expected output, pass 
  # the following parameters as properties:
	#
	# - `redirectUrl`: This parameter tells Samurai where to redirect the 
	#		user's browser after a payment_method_token has been generated. 
	# 		This URL will get `?payment_method_token=[the token]` appended to 
	# 		the end of it. (required)
	# - `paymentMethod`: An instance of PaymentMethod, which will 
	#		be used to fill in existing payment information (e.g. when you 
	# 		present the form after a validation error). (optional)
	# - `ajax`: When this option is set to `true`, a `data-samurai-ajax` 
	#		attribute will be added to the form, so it can be used with 
	#		Samurai.js. (optional)
	# - `classes`: Use this parameter to add additional class names on 
	#		the <form> tag. (optional)
	#
  renderPaymentForm = (vars = {}) ->
    render '/application/_payment_form', vars

  {renderErrors, renderPaymentForm}

module.exports = Views

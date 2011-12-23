(function() {
  var VIEW_PATH, Views, config, eco, extend, fs;

  eco = require('eco');

  fs = require('fs');

  config = require('./connection').config;

  extend = require('./helpers').extend;

  VIEW_PATH = __dirname + '/../views';

  Views = (function() {
    var render, renderErrors, renderPaymentForm;
    render = function(view, vars) {
      var template;
      if (vars == null) vars = {};
      extend(vars, {
        config: config
      });
      template = fs.readFileSync(VIEW_PATH + view + '.eco', 'utf-8');
      return eco.render(template, vars);
    };
    renderErrors = function(vars) {
      if (vars == null) vars = {};
      return render('/application/_errors', vars);
    };
    renderPaymentForm = function(vars) {
      if (vars == null) vars = {};
      return render('/application/_payment_form', vars);
    };
    return {
      renderErrors: renderErrors,
      renderPaymentForm: renderPaymentForm
    };
  })();

  module.exports = Views;

}).call(this);

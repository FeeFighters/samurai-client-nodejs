Samurai
=======

If you are an online merchant and using FeeFighters' Samurai gateway, this node.js module will
make your life easy. Integrate with the samurai.feefighters.com portal and
process transactions.


Installation
------------

Install Samurai just like any other node module, using `npm`:

    npm install samurai

Then require the `samurai` module into your app:

    var Samurai = require('samurai')


Configuration
-------------

Use the `Samurai.setup` method to get the Samurai module ready for
action. You should pass an object, containing your merchant credentials
as a parameter. Here's an example:

    Samurai.setup({
      merchant_key:       'your_merchant_key',
      merchant_password:  'your_merchant_password',
      processor_token:    'your_default_processor_token'
    });

The `processor_token` param is optional. If you set it,
`Samurai.Processor.the_processor` will return the processor with this token. You
can always call `Samurai.Processor.find('an_arbitrary_processor_token')` to
retrieve any of your processors.


Samurai API Reference
---------------------

See the [API Reference](https://samurai.feefighters.com/developers/api-reference/nodejs) for a full explanation of how this gem works with the Samurai API.

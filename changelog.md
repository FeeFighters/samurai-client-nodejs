## Changelog

### 0.1.5 (latest)

 + Transactions will now return AVS results as info messages. The actual
   messages returend by Samurai will have the AVS result code prepended.

### 0.1.4

 + Fixed bad API URL in transaction module

### 0.1.3

 + Changed API URL for Ashigaru

### 0.1.2

 + Prevent Samurai from crashing when Samurai responds with HTTP 500.

### 0.1.1

 + Payment token (card object) is no longer required for processing
   transactions that do not use them (credit, void).

### 0.1.0

 + Fixed issue where `_check` token verification would fail for credit and
   void transaction because Samurai does not honor custom data for those
   transaction types.

### 0.0.9

 + samurai/developers/api_reference#processing-payments-complex

### 0.0.8

 + Rebranded to Herd Hound

### 0.0.7

 + Resolved issue with `success` flag in transaction responses.
 + Ashigaru now supports `sandbox` parameter for creating sandbox payment
   methods.
 + Fixed failing tests which weren't updated to reflect the changes in 0.0.6
   API. The 0.0.6 version of tests are expected to fail (see issue #15), but
   that doesn't affect correct behavior of documented API.

### 0.0.6

 + Fixed `samurai.Card` constructor not handling custom data.
 + Removed `card.method.custom` which was returned after loading a payment
   method, and which always contained unused, empty object.
 + Fixed previously broken `checkamd` makefile target.
 + Fixed Ashigaru not properly handling custom field.
 + Made Ashigaru's timeout checking more robust.
 + Fixed Samurai crashing looking for messages in wrong places.

### 0.0.5

 + Prevents crash when invalid token is passed to samurai.Card constructor.
 + If a token is provided, but it's invalid, an error will be thrown. Previous
   behavior was that it is completely ignored if invalid.
 + `samurai.Card` constructor will throw a proper `SamuraiError` on errors,
   instead of generic `Error` object as in previous versions.

### 0.0.4

 + `allowedCurrencies` setting which limits the currencies that can be used
 + `transaciton.Transaction.process()` will check allowed currencies and block
   transactions that use disallowed currency.
 + `transaction.Transaction.process()` no longer throws exceptions. All errors
   are passed to the callback instead.
 + Ashigaru now supports the `custom` field.
 + `checkamd` make target now generates file with version number.

### 0.0.3

 + Tamper-proofed all properties set with accessors in `samurai.Card` and 
   `transaction.Transaction` objects.
 + Made `data` and `path` properties on `transaction.Transaction` objects 
   set-once properties similar to configuration locking.
 + Custom fields are implemented in both `samurai.Card` and
   `transaction.Transaction` objects. They can store any JSON-serializable
   object, and that will be stored in Samurai gateway, and restored later with
   methods like ``card.load()`` or when transaction is completed.
 + All transaction requests embed a SHA1 hexdigest of 100-character random
   string, which is checked when the response is received. All transactions
   will fail the integrity check if this hash doesn't match.
 + If methods like ``samurai.Card.load()`` are missing a token, the error will
   now _not_ be thrown, but passed to the callback instead, like all other
   methods.

### 0.0.2

 + `samurai` no longer has `settings` property. You should use
   `samurai.option()` to access options instead.
 + After calling `samurai.configure()` successfully for the first time,
   configuration will now be permanently locked until you restart the app.
   This is a _feature_ not a bug. It prevents malicious code from tricking your
   app into resetting some of the critical Samurai options.
 + Returns a proper 'Declined' error message when the card is declined.

### 0.0.1

The first release is a public preview release and it's not meant to be
production-ready. There are still quite a few things to implement, and error
handling is not very robust. Note that API might change as well. For starters,
you should not rely on any method that has the @private tag in the inline
comments (that do not appear in API documentation, that is), but the public
methods may change as well, as well as method signatures.

Although there _are_ unit tests, and Samurai's development is test-driven, the
tests do not currently provide complete coverage, and it is expected that some
functionality may break in production. Target for first production-ready Samurai
is v0.1.

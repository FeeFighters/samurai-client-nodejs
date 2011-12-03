## Changelog

### 0.2.2 (latest)

 + Added hasErrors() helper to Transaction and PaymentMethod classes.
 + Fixed an issue with Transaction and PaymentMethod forgetting to
   process response messages when the find() method was used.

### 0.2.1

 + Added avsResultCode and cvvResultCode properties to transaction
   objects for inspecting the returned AVS/CVV result code.

### 0.2.0

 + The node client has been rewritten from scratch.

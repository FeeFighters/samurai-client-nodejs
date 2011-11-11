# Copies the properties `properties` to a receiver object `object`.
extend = exports.extend = (object, properties) ->
  for key, val of properties
    object[key] = val
  object
   
# Returns a new object, containing the properties from `options` merged
# with the ones from `overrides`.
exports.merge = (options, overrides) ->
  extend (extend {}, options), overrides

# Flattens first level of nested objects for easier conversion to query strings.
# Nesting levels beyond the first one are stringified into JSON.
# e.g.:
# `{ credit_card: { first_name: 'John', last_name: 'Smith' } }`
# turns into:
# `{ 'credit_card[first_name]': 'John', 'credit_card[last_name]': 'Smith' }`
flattenObject = exports.flattenObject = (object) ->
  for key, val of object when typeof val is 'object' and val isnt null
    delete object[key]
    for key2, val2 of val
      object["#{key}[#{key2}]"] = if typeof val2 is 'object' then JSON.stringify(val2) else val2

  object

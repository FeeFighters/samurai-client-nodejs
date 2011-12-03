# Copies the properties `properties` to a receiver object `object`.
extend = exports.extend = (object, properties) ->
  for key, val of properties
    object[key] = val
  object
   
# Returns a new object, containing the properties from `options` merged
# with the ones from `overrides`.
merge = exports.merge = (options, overrides) ->
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

# Converts a string to camelCase notation.
# E.g.: 'camel_case_string' -> 'camelCasedString'
camelize = exports.camelize = (string) ->
  string.replace(/([\-\_][a-z0-9])/g, (match) -> match.toUpperCase().replace('-','').replace('_',''))

# Converts a string to underscore notation.
# E.g.: 'camelCasedString' -> 'camel_case_string'
underscore = exports.underscore = (string) ->
  string.replace(/([A-Z])/g, (match) -> "_" + match.toLowerCase())

# Returns true if an object is empty.
isEmptyObject = exports.isEmptyObject = (object) ->
  for own k, v of object
    return false
  return true

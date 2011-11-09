parser = require 'xml2json'
util = require 'util'

isEmptyObject = (object) ->
  for own k, v of object
    return false
  return true

normalize = (object) ->
  for own k, v of object
    if typeof v is 'object' and v not instanceof Array
      # Empty objects become empty strings.
      if isEmptyObject(v)
        object[k] = ''
      # Typed values are converted to the appropriate JS type.
      else if v.type?
        switch v.type
          when 'boolean'
            v = if v.$t is 'true' then true else false
          when 'datetime'
            v = new Date(Date.parse(v.$t))
          when 'integer'
            v = parseInt(v.$t, 10)
          when 'array'
            # Arrays will have only 1 key, which will point to the list
            # of values. Use that key to replace the contents of the
            # object with the contents of the array.
            delete v.type
            v = v[Object.keys(v)[0]] or []
          else
            v = v.$t
        object[k] = v
      else
        # Drill down nested objects.
        object[k] = normalize(v)
    else
      object[k] = v
  object

module.exports.parse = (string) ->
  normalize(JSON.parse(parser.toJson(string)))

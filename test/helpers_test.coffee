vows                    = require 'vows'
assert                  = require 'assert'
{extend, flattenObject} = require '../lib/helpers'

vows
  .describe('Helpers')
  .addBatch
    'when we extend an object foo with another object bar':
      topic: ->
        foo = { a: 1, b: 2, c: 3 }
        bar = { a: 4, d: 4, e: 5 }
        extend(foo, bar)
        foo

      'foo should include the properties of bar': (topic) ->
        assert.include topic, 'd'
        assert.include topic, 'e'
        assert.equal topic.d, 4
        assert.equal topic.e, 5

      'bar should overwrite the properties of foo that exist in both objects': (topic) ->
        assert.equal topic.a, 4

    'when we flatten an object':
      topic: ->
        foo = { foo: 'bar', credit_card: { first_name: 'John', last_name: 'Smith', custom: { id: 5 } } }
        flattenObject(foo)
        foo
      
      'first-level nested objects should have all their properties copied to the parent object': (topic) ->
        assert.include topic, 'credit_card[first_name]'
        assert.equal   topic['credit_card[first_name]'], 'John'
        assert.include topic, 'credit_card[last_name]'
        assert.equal   topic['credit_card[last_name]'],  'Smith'

      'and deeply nested objects should be converted to JSON': (topic) ->
        assert.equal topic['credit_card[custom]'], '{"id":5}'

  .export(module)

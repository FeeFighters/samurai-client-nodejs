should = require 'should'
{ extend
, flattenObject
, camelize
, underscore
} = require '../../lib/helpers'

describe 'Helpers', ->
  describe 'extend()', ->
    it 'should extend foo with the properties of bar', ->
      foo = { a: 1, b: 2, c: 3 }
      bar = { a: 4, d: 4, e: 5 }
      extend(foo, bar)
      foo.should.have.property('d', 4)
      foo.should.have.property('e', 5)

  describe 'flattenObject()', ->
    foo = {}

    before ->
      foo = { foo: 'bar', credit_card: { first_name: 'John', last_name: 'Smith', custom: { id: 5 } } }
      flattenObject(foo)

    it 'should copy all the properties of first-level nested objects to the parent object', ->
      foo.should.have.property 'credit_card[first_name]', 'John'
      foo.should.have.property 'credit_card[last_name]', 'Smith'

    it 'should convert deeply nested objects to JSON', ->
      foo['credit_card[custom]'].should.equal '{"id":5}'

  describe 'underscore()', ->
    it 'should convert a camelCased string to underscore notation', ->
      result = underscore 'camelCasedString'
      result.should.equal 'camel_cased_string'

  describe 'camelize()', ->
    it 'should convert an underscored string to camelCase notation', ->
      result = camelize 'camel_cased_string'
      result.should.equal 'camelCasedString'

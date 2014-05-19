Parser  = require '../../../src/finitio/syntax/parser'
BuiltinType = require '../../../src/finitio/type/builtin_type'
Heading     = require '../../../src/finitio/support/heading'
Attribute   = require '../../../src/finitio/support/attribute'
should      = require 'should'

describe "Parser#heading", ->

  subject = Parser.parse("foo: .String, bar: .Number", startRule: "heading")

  it 'should return a Heading', ->
    subject.should.be.an.instanceof(Heading)
    subject.size().should.equal(2)

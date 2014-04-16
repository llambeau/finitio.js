Attribute = require '../../../src/support/attribute'
Heading   = require '../../../src/support/heading'
should    = require 'should'
_         = require 'underscore'
{intType} = require '../../spec_helpers'

describe 'Heading#allowExtra', ->

  r = new Attribute('r', intType)

  heading = (attributes, options) ->
    new Heading(attributes, options)

  it 'is false by default', ->
    h = heading([r])
    h.allowExtra().should.be.false

  it 'can be set to true', ->
    h = heading([r], allowExtra: true)
    h.allowExtra().should.be.true

  it 'can be set to false explicitely', ->
    h = heading([r], allowExtra: false)
    h.allowExtra().should.be.false

UnionType = require '../../../../src/finitio/type/union_type'
should    = require 'should'
{intType,
floatType,
byteType}  = require '../../../spec_helpers'

describe "UnionType#equality", ->

  uType  = new UnionType([intType, floatType])
  uType2 = new UnionType([floatType, intType])
  uType3 = new UnionType([floatType, intType])
  uType4 = new UnionType([floatType, floatType])
  uType5 = new UnionType([floatType, intType, byteType])
  uType6 = new UnionType([intType])

  it 'should apply structural equality', ->
    uType.equals(uType2).should.equal(true)
    uType.equals(uType3).should.equal(true)
    uType2.equals(uType3).should.equal(true)

  it 'should apply distinguish different types', ->
    uType.equals(uType4).should.equal(false)
    uType.equals(uType5).should.equal(false)
    uType.equals(uType6).should.equal(false)
    uType.equals(intType).should.equal(false)

  it 'should be a total function, with null for non types', ->
    uType.equals(12).should.equal(false)

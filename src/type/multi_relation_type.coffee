Type            = require '../type'
CollectionType  = require '../support/collection_type'
MultiTupleType  = require '../type/multi_tuple_type'
Heading         = require '../support/heading'
DressHelper     = require '../support/dress_helper'
{ArgumentError} = require '../errors'
$u              = require '../support/utils'

class MultiRelationType extends Type

  constructor: (@heading, @name) ->
    super(@name)

    unless @heading instanceof Heading
      throw new ArgumentError("Heading expected, got", @heading)

  include: (value) ->
    value instanceof Array &&
      $u.every value, (tuple) =>
        @tupleType().include(tuple)

  tupleType: ->
    if @heading.multi()
      new MultiTupleType(@heading)
    else
      new TupleType(@heading)

  equals: (other) ->
    other instanceof MultiRelationType && @heading.equals(other.heading)

  # Apply the corresponding TupleType's `dress` to every element of `value`
  # (any enumerable). Return a Set of transformed tuples. Fail if anything
  # goes wrong transforming tuples or if duplicates are found.
  dress: (value, helper) ->
    helper ?= new DressHelper

    unless typeof(value) == "object" || typeof(value) == "array"
      helper.failed(this, value)

    # Up every tuple and keep results in a "Set"
    set = {}
    helper.iterate value, (tuple, index) =>
      tuple = @tupleType().dress(tuple, helper)
      ## TODO: what a terrible way of 'hashing'
      ## shall we invent a real 'Set' class and hash objects?
      key = JSON.stringify(tuple)
      helper.fail("Duplicate tuple") if set[key]?
      set[key] = tuple

    # Return built tuples
    $u.values(set)

  defaultName: ->
    "{{#{@heading.toName()}}}"

#
module.exports = MultiRelationType
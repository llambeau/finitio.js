Type           = require '../type'

## Support
Attribute      = require './attribute'
Heading        = require './heading'
Constraint     = require './constraint'
Contract       = require './contract'
$u             = require './utils'

## Types
TypeDef        = require '../type/type_def'
TypeRef      = require '../type/type_ref'
AnyType        = require '../type/any_type'
AdType         = require '../type/ad_type'
SeqType        = require '../type/seq_type'
SetType        = require '../type/set_type'
StructType     = require '../type/struct_type'
SubType        = require '../type/sub_type'
TupleType      = require '../type/tuple_type'
UnionType      = require '../type/union_type'
BuiltinType    = require '../type/builtin_type'
RelationType   = require '../type/relation_type'

# Typefactory
class TypeFactory

  @IDENTITY = (arg)-> arg

  @PUBLIC_DSL_METHODS: [
    'jsType',
    #
    'contract',
    'constraint',
    'attribute',
    'heading',
    #
    'typeDef',
    'typeRef',
    #
    'any',
    'builtin',
    'adt',
    'sub_type',
    'union',
    'seq',
    'set',
    'tuple',
    'relation',
    'struct',
    'type'
  ]

  @factory: (name, fn)->
    fallback = this.prototype[name]
    this.prototype[name] = ()->
      if fn.length == arguments.length
        fn.apply(this, arguments)
      else if typeof(fallback) == 'function'
        fallback.apply(this, arguments)
      else
        throw new Error("No such signature #{name}/#{arguments.length}")

  constructor: (world)->
    @world = {
      'Number':   Number,
      'String':   String,
      'Boolean':  Boolean,
      'Date':     Date,
      'Function': Function,
      'RegExp':   RegExp
    }
    $u.extend(@world, world)

  ################################################################## Factory

  type: (t, callback) ->
    if callback?
      return @sub_type(@type(t), callback)

    if t instanceof Type
      t

    else if isNativeType(t)
      new BuiltinType(t)

    else if isRegexp(t)
      @sub_type(String, t)

    else if t instanceof Array
      fail("Array of arity 1 expected, got", t) unless t.length == 1
      @seq(t[0])

    else if typeof(t) == "object"
      @tuple(t)

    else
      fail("Unable to factor a Finitio.Type from `#{t}`")

  ########################################################### Type Arguments

  jsType: (t) ->
    if typeof(t) == 'string'
      parts = t.split('.')
      $u.inject parts, @world, (memo, part)->
        memo[part] || throw new Error("Unknown type #{t} (#{part} not found)")

    else if isNativeType(t) || t instanceof Function
      t

    else
      fail("JS primitive expected, got `#{t}`")

  metadata: (arg) ->
    unless arg == undefined || arg == null || $u.isObject(arg)
      $u.argumentError("Invalid metadata:", arg)
    arg

  constraint: (name, nativ, metadata) ->
    return name if name instanceof Constraint

    if typeof(name) isnt "string"
      [name, nativ, metadata] = ['default', name, nativ]

    if typeof(nativ) == 'function'
      new Constraint.Native(name, nativ, metadata)
    else
      new Constraint.Regexp(name, nativ, metadata)

  constraints: (constraints, callback) ->
    constrs = []
    if callback?
      constrs.push @constraint('default', callback)

    if constraints?
      if constraints.constructor == Array
        $u.each constraints, (c) =>
          constrs.push(@constraint(c))
      else if constraints.constructor == RegExp
        constrs.push @constraint(constraints)
      else if typeof(constraints) is "object"
        $u.each constraints, (c, n) =>
          constrs.push(@constraint(n, c))
      else
        constrs.push @constraint(constraints)

    constrs

  attribute: (name, type, required, metadata) ->
    new Attribute(name, @type(type), required, metadata)

  attributes: (attributes) ->
    unless typeof attributes is "object"
      fail("Hash expected, got ", attributes)

    attr = []
    $u.each attributes, (type, name) =>
      attr.push @attribute(name, type)

    attr

  heading: (heading, opts) ->
    return heading if heading instanceof Heading
    return heading.heading if heading.heading?

    if heading.constructor == Array
      new Heading(heading, opts)
    else if typeof(heading) is "object"
      new Heading(@attributes(heading), opts)
    else
      fail("Heading expected, got", heading)

  # Handles the full-featured Contract signature
  @factory 'contract', (name, infoType, dresser, undresser, metadata)->
    new Contract(name, infoType, dresser, undresser, metadata)

  # Handles the no-metadata signature
  @factory 'contract', (name, infoType, dresser, undresser)->
    new Contract(name, infoType, dresser, undresser)

  # Handles the following cases:
  #
  #   Contract(name:String, infoType:Finitio.Type, external:JsType)
  #   Contract(name:String, infoType:Finitio.Type, internal:JsType)
  #   Contract(name:String, infoType:Finitio.Type, metadata:Metadata)
  #
  @factory 'contract', (name, infoType, handler)->
    if (handler.dress && handler.undress)
      new Contract(name, infoType, handler.dress, handler.undress)
    else if (typeof(handler) == 'function')
      dresser   = handler[name]
      undresser = (value)->
        value['to' + $u.capitalize(name)]();
      new Contract(name, infoType, dresser, undresser)
    else
      new Contract(name, infoType, TypeFactory.IDENTITY, TypeFactory.IDENTITY, handler)

  # Handles only a name and an info type (no converters, no metadata)
  @factory 'contract', (name, infoType)->
    new Contract(name, infoType, TypeFactory.IDENTITY, TypeFactory.IDENTITY)

  # Handles the following cases:
  #
  #    Contract(Contract)
  #    Contract({ name: .., infoType: ..., ... })
  #
  @factory 'contract', (a)->
    if a instanceof Contract
      return a
    else if (a.name && a.infoType)
      a.dresser   ?= TypeFactory.IDENTITY
      a.undresser ?= TypeFactory.IDENTITY
      new Contract(a.name, a.infoType, a.dresser, a.undresser, a.metadata)
    else
      fail("Unrecognized contract: #{a}")

  contracts: (cs)->
    if $u.isArray(cs)
      $u.map cs, (c)=>
        @contract(c)
    else
      $u.argumentError("Array expected, got:", cs)

  ########################################################## Type generators

  typeDef: (type, name, metadata) ->
    type     = @type(type)
    metadata = @metadata(metadata)

    new TypeDef(type, name, metadata)

  typeRef: (targetRef, metadata) ->
    metadata = @metadata(metadata)

    new TypeRef(targetRef, metadata)

  any: (metadata) ->
    metadata  = @metadata(metadata)

    new AnyType(metadata)

  builtin: (primitive, metadata) ->
    primitive = @jsType(primitive)
    metadata  = @metadata(metadata)

    new BuiltinType(primitive, metadata)

  adt: (primitive, contracts, metadata) ->
    primitive = @jsType(primitive) if primitive?
    contracts = @contracts(contracts)
    metadata  = @metadata(metadata)

    new AdType(primitive, contracts, metadata)

  #### Sub and union

  sub_type: (superType, constraints, metadata) ->
    superType   = @type(superType)
    constraints = @constraints(constraints)
    metadata    = @metadata(metadata)

    new SubType(superType, constraints, metadata)

  union: (candidates, metadata) ->
    candidates = $u.map candidates, (t) => @type(t)

    new UnionType(candidates, metadata)

  #### Collections

  seq: (elmType, metadata) ->
    elmType  = @type(elmType)
    metadata = @metadata(metadata)

    new SeqType(elmType, metadata)

  set: (elmType, metadata) ->
    elmType  = @type(elmType)
    metadata = @metadata(metadata)

    new SetType(elmType, metadata)

  struct: (componentTypes, metadata) ->
    componentTypes = $u.map(componentTypes, (t) => @type(t))
    metadata       = @metadata(metadata)

    new StructType(componentTypes, metadata)

 #### Tuples and relations

  tuple: (heading, metadata) ->
    heading  = @heading(heading)
    metadata = @metadata(metadata)

    new TupleType(heading, metadata)

  relation: (heading, metadata) ->
    heading  = @heading(heading)
    metadata = @metadata(metadata)

    new RelationType(heading, metadata)

# 'private' Utility functions
# (only in the scope of this module)

isNativeType = (t) ->
  return false unless t?
  match = $u.find [Number, Boolean, String], (primitive) ->
    t == primitive

  match?

isRegexp = (t) ->
  return false unless t?
  t.constructor == RegExp

fail = (msg, type) ->
  if type?
    throw new Error(msg, type)
  else
    throw new Error(msg)

#
module.exports = TypeFactory

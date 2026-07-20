local newString = require "main.string"
local newNumber = require "main.number"
local newBoolean = require "main.boolean"
local newFunction = require "main.function"
local newTable = require "main.table"
local newAny = require "main.any"
local newUnknown = require "main.unknown"
local newNever = require "main.never"

local newLiteral = require "main.literal"
local newEnum = require "main.enum"

local newObject = require "main.object"
local newArray = require "main.array"
local newRecord = require "main.record"
local newTuple = require "main.tuple"

local newUnion = require "main.union"
local newIntersection = require "main.intersection"
local newDiscriminatedUnion = require "main.discriminated_union"

local newLazy = require "main.lazy"
local coerce = require "main.coerce"

return {
  -- primitives
  string = newString,
  number = newNumber,
  boolean = newBoolean,
  func = newFunction,
  table = newTable,
  any = newAny,
  unknown = newUnknown,
  never = newNever,

  -- values (literal, enum)
  literal = newLiteral,
  enum = newEnum,

  -- composites
  object = newObject,
  array = newArray,
  record = newRecord,
  tuple = newTuple,

  -- logic
  union = newUnion,
  intersection = newIntersection,
  discriminatedUnion = newDiscriminatedUnion,

  lazy = newLazy,
  coerce = coerce,
}

local newString = require "main.string"
local newNumber = require "main.number"
local newBoolean = require "main.boolean"
local newFunction = require "main.function"
local newTable = require "main.table"

local newLiteral = require "main.literal"
local newEnum = require "main.enum"

local newObject = require "main.object"
local newArray = require "main.array"

local newUnion = require "main.union"
local newIntersection = require "main.intersection"

local newLazy = require "main.lazy"

return {
  -- primitives (string, number, boolean, function, table, any?, never?)
  string = newString,
  number = newNumber,
  boolean = newBoolean,
  func = newFunction,
  table = newTable,

  -- values (literal, enum)
  literal = newLiteral,
  enum = newEnum,

  -- composites (object, array, record, tuple)
  object = newObject,
  array = newArray,

  -- logic (union, intersection, lazy?)
  union = newUnion,
  intersection = newIntersection,

  lazy = newLazy,
}
local newString = require "main.string"
local newNumber = require "main.number"
local newBoolean = require "main.boolean"

local newLiteral = require "main.literal"
local newEnum = require "main.enum"

return {
  -- primitives (string, number, boolean, function, table, any?, never?)
  string = newString,
  number = newNumber,
  boolean = newBoolean,

  -- values (literal, enum)
  literal = newLiteral,
  enum = newEnum,

  -- composites (object, array, record, tuple)

  -- logic (union, intersection, lazy?)
}
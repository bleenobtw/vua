local newString = require "main.string"
local newNumber = require "main.number"
local newBoolean = require "main.boolean"

return {
  -- primitives (string, number, boolean, function, table, any?, never?)
  string = newString,
  number = newNumber
  boolean = newBoolean

  -- values (literal, enum)

  -- composites (object, array, record, tuple)

  -- logic (union, intersection, lazy?)
}
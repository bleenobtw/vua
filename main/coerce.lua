local newString = require "main.string"
local newNumber = require "main.number"
local newBoolean = require "main.boolean"

return {
  string = function()
    return newString():preprocess(function(value)
      if value == nil then return nil end
      return tostring(value)
    end)
  end,
  number = function()
    return newNumber():preprocess(function(value)
      if type(value) ~= "string" then return value end
      return tonumber(value) or value
    end)
  end,
  boolean = function()
    return newBoolean():preprocess(function(value)
      if value == "true" or value == 1 then return true end
      if value == "false" or value == 0 then return false end
      return value
    end)
  end,
}

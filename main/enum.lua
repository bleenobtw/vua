local base = require "main.base"
local _, newValidator = table.unpack(base)
local helpers = require "main.helpers"

return function(values)
  if type(values) ~= "table" then error("enum values must be a table", 2) end

  local length = helpers.arrayLength(values)
  if not length or length == 0 then error("enum values must be a non-empty dense array", 2) end

  local lookup = {}
  local labels = {}
  for i = 1, length do
    lookup[values[i]] = true
    labels[i] = tostring(values[i])
  end
  local joined = table.concat(labels, " | ")
  
  local self = newValidator(("enum(%s)"):format(joined), function(value, path)
    if not lookup[value] then
      return false, helpers.issue(path, "invalid_enum", ("expected one of [%s], got '%s'"):format(joined, tostring(value)), values, value)
    end
    return true, value
  end)
  self.__label = joined
  self.__values = values
  return self
end

local base = require "main.base"
local _, newValidator = table.unpack(base)
local helpers = require "main.helpers"

return function(values)
  local lookup = {}
  for _, value in ipairs(values) do lookup[value] = true end
  local joined = table.concat(values, " | ")
  
  local self = newValidator(("enum(%s)"):format(joined), function(value, path)
    if not lookup[value] then
      return false, ("[%s] expected one of [%s], got '%s'"):format(helpers.pathToString(path), joined, tostring(value))
    end
    return true, value
  end)
  self.__label = joined
  return self
end

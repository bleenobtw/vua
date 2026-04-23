local _, newValidator = table.unpack(require "main.base")
local helpers = require "main.helpers"

return function(expected)
  local label = tostring(expected)
  
  local self = newValidator(("literal(%s)"):format(label), function(value, path)
    if value ~= expected then
      return false, ("[%s] expected literal %s, got %s"):format(helpers.pathToString(path), label, tostring(value))
    end
    return true, value
  end)
  self.__label = label
  return self
end
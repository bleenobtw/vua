local base = require "main.base"
local _, newValidator = table.unpack(base)
local helpers = require "main.helpers"

return function(expected)
  local label = tostring(expected)
  local self = newValidator(("literal(%s)"):format(label), function(value, path)
    if value ~= expected then
      return false, helpers.issue(path, "invalid_literal", ("expected literal %s, got %s"):format(label, tostring(value)), expected, value)
    end
    return true, value
  end)
  self.__label = label
  return self
end

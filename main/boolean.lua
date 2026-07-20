local base = require "main.base"
local _, newValidator = table.unpack(base)
local helpers = require "main.helpers"

return function()
  return newValidator("boolean", function(value, path)
    if type(value) ~= "boolean" then
      return false, helpers.issue(path, "invalid_type", ("expected boolean, got %s"):format(type(value)), "boolean", type(value))
    end
    return true, value
  end)
end

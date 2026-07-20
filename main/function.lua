local base = require "main.base"
local _, newValidator = table.unpack(base)
local helpers = require "main.helpers"

return function()
  return newValidator("function", function(value, path)
    if type(value) ~= "function" then
      return false, helpers.issue(path, "invalid_type", ("expected function, got %s"):format(type(value)), "function", type(value))
    end
    return true, value
  end)
end

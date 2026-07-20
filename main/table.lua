local base = require "main.base"
local _, newValidator = table.unpack(base)
local helpers = require "main.helpers"

return function()
  return newValidator("table", function(value, path)
    if type(value) ~= "table" then
      return false, helpers.issue(path, "invalid_type", ("expected table, got %s"):format(type(value)), "table", type(value))
    end
    return true, value
  end)
end

local base = require "main.base"
local _, newValidator = table.unpack(base)
local helpers = require "main.helpers"

return function()
  return newValidator("table", function(value, path)
    if type(value) ~= "table" then
      return false, ("[%s] expected table, got %s"):format(helpers.pathToString(path), type(value))
    end
    return true, value
  end)
end

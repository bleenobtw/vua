local _, newValidator = table.unpack(require "main.base")
local helpers = require "main.helpers"

return function()
  return newValidator("boolean", function(value, path)
    if type(value) ~= "boolean" then
      return false, ("[%s] expected boolean, got %s")
        :format(helpers.pathToString(path), type(value))
    end
    return true, value
  end)
end